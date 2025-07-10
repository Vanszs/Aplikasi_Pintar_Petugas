package com.example.petugas_pintar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * This broadcast receiver handles background service intents
 * and ensures they have the proper foreground service type for Android 13+
 */
class BackgroundServiceBroadcastReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "BackgroundServiceReceiver"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        try {
            Log.d(TAG, "Received intent: ${intent?.action}")
            
            if (intent?.action == "id.flutter.flutter_background_service.BACKGROUND_SERVICE_ACTION") {
                Log.d(TAG, "Processing background service intent")
                BackgroundServiceHelper.modifyForegroundServiceIntent(intent)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error in broadcast receiver: ${e.message}")
        }
    }
}
