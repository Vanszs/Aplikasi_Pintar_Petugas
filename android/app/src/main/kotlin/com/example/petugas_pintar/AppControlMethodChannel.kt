package com.example.petugas_pintar

import android.app.Activity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles platform-specific back button behavior through method channels
 */
class AppControlMethodChannel(private val activity: Activity) {
    companion object {
        const val CHANNEL = "com.example.petugas_pintar/app_control"
    }

    /**
     * Set up the method channel in the Flutter engine
     */
    fun configureChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveTaskToBack" -> {
                    // Move app to background instead of exiting
                    val success = activity.moveTaskToBack(true)
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }
}
