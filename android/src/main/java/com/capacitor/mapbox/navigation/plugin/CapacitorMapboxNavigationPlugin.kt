package com.capacitor.mapbox.navigation.plugin

import android.content.Intent
import androidx.activity.result.ActivityResult
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.ActivityCallback
import com.getcapacitor.annotation.CapacitorPlugin
import com.mapbox.maps.extension.style.expressions.dsl.generated.switchCase


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

        if (routesArray != null && routesArray.length() == 2) {
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

            val simulate = call.getBoolean("simulate",false)
            intent.putExtra("simulate",simulate)

            startActivityForResult(call, intent, "navigationCallback")
        } else {
            call.reject("Invalid routes data")
        }
    }

    @ActivityCallback
    private fun navigationCallback(call: PluginCall?, result: ActivityResult) {
        if (call == null) {
            return
        }

        // Do something with the result data
        var resultIntent = result.data

        var resultStatus = resultIntent?.getStringExtra("status")
        var resultType = resultIntent?.getStringExtra("type")
        var resultData = resultIntent?.getStringExtra("data")


        val data = JSObject()

        data.put("status",resultStatus)
        data.put("type",resultType)
        data.put("data",resultData)

        call.resolve(data)
    }
}
