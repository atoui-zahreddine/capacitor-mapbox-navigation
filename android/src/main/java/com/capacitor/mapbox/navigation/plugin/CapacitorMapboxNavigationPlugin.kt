package com.capacitor.mapbox.navigation.plugin

import android.content.Intent
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin


@CapacitorPlugin(name = "CapacitorMapboxNavigation")
class CapacitorMapboxNavigationPlugin : Plugin() {
    private val implementation = CapacitorMapboxNavigation()

    @PluginMethod
    fun echo(call: PluginCall) {
        val value = call.getString("value")

        val ret = JSObject()
        ret.put("value", value?.let { implementation.echo(it) })
        call.resolve(ret)
    }

    @PluginMethod
    fun show(call: PluginCall){

        val routesArray = call.getArray("routes")

        if (routesArray != null) {
            val fromLocation = routesArray.getJSONObject(0)
            val toLocation = routesArray.getJSONObject(1)

            val fromLat = fromLocation.getDouble("latitude")
            val fromLng = fromLocation.getDouble("longitude")
            val toLat = toLocation.getDouble("latitude")
            val toLng = toLocation.getDouble("longitude")

            val intent = Intent(this.getBridge().context, NavigationActivity::class.java)
            intent.putExtra("fromLat", fromLat)
            intent.putExtra("fromLng", fromLng)
            intent.putExtra("toLat", toLat)
            intent.putExtra("toLng", toLng)

            startActivityForResult(call, intent, 1)
        } else {
            call.reject("Invalid routes data")
        }
    }
}
