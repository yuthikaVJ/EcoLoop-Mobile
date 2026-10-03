package com.example.eco_loop

import android.Manifest
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import com.google.android.gms.location.CurrentLocationRequest
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import com.google.android.gms.tasks.CancellationTokenSource
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ecoloop/location")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentLocation" -> getCurrentLocation(
                        timeoutMs = call.argument<Int>("timeoutMs") ?: 15000,
                        maxAgeMs = call.argument<Int>("maxAgeMs") ?: 0,
                        result = result,
                    )
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * One location fix from Google Play Services, delivered asynchronously.
     *
     * Used instead of geolocator's getCurrentPosition: geolocator registers a
     * GNSS NMEA listener for every request and unregisters it on the main
     * thread, and on some Android builds that unregister call blocks, freezing
     * the app until Android kills it ("App isn't responding").
     */
    private fun getCurrentLocation(timeoutMs: Int, maxAgeMs: Int, result: MethodChannel.Result) {
        val fine = hasPermission(Manifest.permission.ACCESS_FINE_LOCATION)
        if (!fine && !hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)) {
            result.error("PERMISSION_DENIED", "Location permission was not granted.", null)
            return
        }

        val request = CurrentLocationRequest.Builder()
            .setPriority(if (fine) Priority.PRIORITY_HIGH_ACCURACY else Priority.PRIORITY_BALANCED_POWER_ACCURACY)
            .setDurationMillis(timeoutMs.toLong())
            .setMaxUpdateAgeMillis(maxAgeMs.toLong())
            .build()

        try {
            LocationServices.getFusedLocationProviderClient(this)
                .getCurrentLocation(request, CancellationTokenSource().token)
                .addOnSuccessListener { location ->
                    result.success(
                        location?.let {
                            mapOf(
                                "latitude" to it.latitude,
                                "longitude" to it.longitude,
                                "accuracy" to it.accuracy.toDouble(),
                                "timestamp" to it.time,
                            )
                        },
                    )
                }
                .addOnFailureListener { error ->
                    result.error("LOCATION_ERROR", error.message, null)
                }
        } catch (error: SecurityException) {
            result.error("PERMISSION_DENIED", error.message, null)
        }
    }

    private fun hasPermission(permission: String) =
        ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
}
