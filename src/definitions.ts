export interface CapacitorMapboxNavigationPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
  show(options: MapboxNavOptions): Promise<MapboxResult | void>;
  history(): Promise<any>;
}

export interface MapboxResult {
  status:string
  type:string
  data:string
}

export interface MapboxNavOptions {
  routes: LocationOption[];
  mapType?: string;
}

export interface LocationOption {
  latitude: number;
  longitude: number;
}

export interface MapboxNavStyleOption {

}
