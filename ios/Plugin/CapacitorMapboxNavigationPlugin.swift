import Foundation
import Capacitor

import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

struct Location: Codable {
    var _id: String = ""
    var longitude: Double = 0.0
    var latitude: Double = 0.0
    var when: String = ""
}

var lastLocation: Location?;
var locationHistory: NSMutableArray?;
var routes = [NSDictionary]();

func getNowString() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    return formatter.string(from: date);
}
@objc(CapacitorMapboxNavigationPlugin)
public class CapacitorMapboxNavigationPlugin: CAPPlugin, NavigationViewControllerDelegate,CLLocationManagerDelegate {
    
    var permissionCallID: String?
    var callbackId: String?
    var locationManager = CLLocationManager()
    enum CallType {
        case permissions
    }
    private var callQueue: [String: CallType] = [:]
    var isNavigationActive = false
    
    @objc override public func load() {
        // Called when the plugin is first constructed in the bridge
        locationHistory = NSMutableArray()
        
        
        // Observe application state changes
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    // Application will resign active (e.g., goes to background)
    @objc func applicationWillResignActive() {
        if isNavigationActive {
            // Navigation is active, ensure idle timer remains disabled
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    // Application did become active (e.g., comes to foreground)
    @objc func applicationDidBecomeActive() {
        if isNavigationActive {
            // Navigation is active, ensure idle timer remains disabled
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    
    @objc func show(_ call: CAPPluginCall) {
        bridge?.saveCall(call)
        callbackId = call.callbackId
        lastLocation = Location(longitude: 0.0, latitude: 0.0);
        locationHistory?.removeAllObjects()
        
        routes = call.getArray("routes", NSDictionary.self) ?? [NSDictionary]()
        var waypoints = [Waypoint]();
        
        for route in routes {
            if let latitude = route["latitude"] as? NSNumber,
               let longitude = route["longitude"] as? NSNumber {

                let lat = latitude.doubleValue
                let lon = longitude.doubleValue

                print(lat)
                print(lon)
                let waypoint = Waypoint(coordinate: CLLocationCoordinate2DMake(lat, lon))
                waypoints.append(waypoint)
            } else {
                print("Failed to convert latitude and longitude to NSNumber")
                sendDataToCapacitor(status: "failure", type: "on_failure",content: "Failed to convert latitude and longitude to NSNumber")
                return
            }
        }
        
        let isSimulate = call.getBool("simulating") ?? false
        
        let routeOptions = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .automobile)
        
        Directions.shared.calculate(routeOptions) { [weak self] (session, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                self?.sendDataToCapacitor(status: "failure", type: "on_failure",content: "no routes found")
            case .success(let response):
                guard let route = response.routes?.first, let strongSelf = self else {
                    return
                }
                
                let navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: routeOptions, simulating: isSimulate ? .always : .never)
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                
                let viewController = NavigationViewController(for: response, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
                viewController.modalPresentationStyle = .fullScreen
                viewController.waypointStyle = .extrudedBuilding;
                viewController.delegate = strongSelf;
                
                self?.keepAwake()
                
                DispatchQueue.main.async {
                    self?.setCenteredPopover(viewController)
                    self?.bridge?.viewController?.present(viewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    public func keepAwake() {
        isNavigationActive = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    public func allowSleep() {
        // Re-enable idle timer and reset navigation active state
        UIApplication.shared.isIdleTimerDisabled = false
        isNavigationActive = false
    }
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        sendDataToCapacitor(status: "success", type: "on_stop", content: "Navigation stopped")
        
        allowSleep()
        
        navigationViewController.dismiss(animated: true)
    }
    
    @objc func history(_ call: CAPPluginCall) {
        let jsonEncoder = JSONEncoder()
        do {
            let lastLocationJsonData = try jsonEncoder.encode(lastLocation)
            let lastLocationJson = String(data: lastLocationJsonData, encoding: String.Encoding.utf8)
            
            let swiftArray = locationHistory as AnyObject as! [Location]
            let locationHistoryJsonData = try jsonEncoder.encode(swiftArray)
            let locationHistoryJson = String(data: locationHistoryJsonData, encoding: String.Encoding.utf8)
            
            call.resolve([
                "lastLocation": lastLocationJson ?? "",
                "locationHistory": locationHistoryJson ?? ""
            ])
        } catch {
            call.reject("Error: Json Encoding Error")
        }
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let removalQueue = callQueue.filter { $0.value == .permissions }
        
        for (id, _) in removalQueue {
            if let call = bridge?.savedCall(withID: id) {
                call.reject(error.localizedDescription)
                bridge?.releaseCall(call)
            }
        }
        
        for (id, _) in callQueue {
            if let call = bridge?.savedCall(withID: id) {
                call.reject(error.localizedDescription)
            }
        }
    }
    
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let removalQueue = callQueue.filter { $0.value == .permissions }
        callQueue = callQueue.filter { $0.value != .permissions }
        
        for (id, _) in removalQueue {
            if let call = bridge?.savedCall(withID: id) {
                checkPermissions(call)
                bridge?.releaseCall(call)
            }
        }
    }
    
    @objc override public func checkPermissions(_ call: CAPPluginCall) {
        var status: String = ""
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined:
                status = "prompt"
            case .restricted, .denied:
                status = "denied"
            case .authorizedAlways, .authorizedWhenInUse:
                status = "granted"
            @unknown default:
                status = "prompt"
            }
        } else {
            call.reject("Location services are not enabled")
            return
        }
        
        let result = [
            "location": status,
            "coarseLocation": status
        ]
        
        call.resolve(result)
    }
    
    @objc override public func requestPermissions(_ call: CAPPluginCall) {
        if CLLocationManager.locationServicesEnabled() {
            // If state is not yet determined, request perms.
            // Otherwise, report back the state right away
            if CLLocationManager.authorizationStatus() == .notDetermined {
                bridge?.saveCall(call)
                callQueue[call.callbackId] = .permissions
                
                DispatchQueue.main.async {
                    self.locationManager.delegate = self
                    self.locationManager.requestWhenInUseAuthorization()
                }
            } else {
                checkPermissions(call)
            }
        } else {
            call.reject("Location services are not enabled")
        }
    }
    
    public func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        
        let jsonEncoder = JSONEncoder()
        do {
            var minDistance: CLLocationDistance = 0;
            var locationId: String = "";
            for (i, route) in routes.enumerated() {
                let location = route["location"] as! NSArray;
                let coord1 = CLLocation(latitude: location[1] as! CLLocationDegrees, longitude: location[0] as! CLLocationDegrees)
                let coord2 = CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)
                
                let distance = coord1.distance(from: coord2)
                
                if (i == 0 || distance < minDistance) {
                    minDistance = distance;
                    locationId = route["_id"] as! String;
                }
            }
            let loc = Location(_id: locationId, longitude: waypoint.coordinate.longitude, latitude: waypoint.coordinate.latitude, when: getNowString());
            let locationJsonData = try jsonEncoder.encode(loc)
            let locationJson = String(data: locationJsonData, encoding: String.Encoding.utf8) ?? ""
            
            sendDataToCapacitor(status: "success", type: "on_arrive", content: locationJson)
        } catch {
            sendDataToCapacitor(status: "failure", type: "on_error", content: "Error: Json Encoding Error")
        }
        return true
    }
    
    
    
    @objc public func sendDataToCapacitor(status: String, type: String, content: String) {
        if let callID = callbackId, let call = bridge?.savedCall(withID: callID) {
            
            let data = ["status": status, "type": type, "content": content]
            call.resolve(data)
            bridge?.releaseCall(call)
        }
        
    }
}

