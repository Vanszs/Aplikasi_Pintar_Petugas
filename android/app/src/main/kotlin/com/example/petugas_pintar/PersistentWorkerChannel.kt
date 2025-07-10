package com.example.petugas_pintar

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Handles platform-specific persistent worker functionality through method channels
 */
class PersistentWorkerChannel(private val context: Context) {
    companion object {
        const val CHANNEL = "com.example.petugas_pintar/persistent_worker"
    }

    /**
     * Set up the method channel in the Flutter engine
     */
    fun configureChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleCustomAlarm" -> {
                    try {
                        ServiceAlarmReceiver.scheduleAlarm(context)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ALARM_ERROR", "Error scheduling custom alarm: ${e.message}", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
