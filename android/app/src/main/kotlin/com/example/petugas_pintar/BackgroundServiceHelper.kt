package com.example.petugas_pintar

import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * This class is used to modify the intent for FlutterBackgroundService
 * to add FOREGROUND_SERVICE_TYPE flags for Android 13+ compatibility
 */
class BackgroundServiceHelper {
    companion object {
        private const val TAG = "BackgroundServiceHelper"
        
        // Define constants for foreground service types since they may not be available in older API versions
        private const val FOREGROUND_SERVICE_TYPE_DATA_SYNC = 2 // Value from Android API 29+
        private const val FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE = 32 // Value from Android API 29+
        
        /**
         * Set the foreground service types for Android 13+ compatibility
         */
        @JvmStatic
        fun modifyForegroundServiceIntent(intent: Intent) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) { // API 33+
                    Log.d(TAG, "Setting foreground service types for Android 13+")
                    
                    // For Android 13+, we need to specify foreground service type
                    // Adding DATA_SYNC and CONNECTED_DEVICE types as per the app's requirements
                    // DATA_SYNC: For real-time data synchronization
                    // CONNECTED_DEVICE: For socket/websocket connections
                    val serviceTypes: Int = FOREGROUND_SERVICE_TYPE_DATA_SYNC or FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE
                    
                    // Set the foreground service type for Android 13+ (explicitly using Int to avoid ambiguity)
                    intent.putExtra("foregroundServiceType", serviceTypes as Int)
                    Log.d(TAG, "Foreground service types set to $serviceTypes")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error setting foreground service type: ${e.message}")
            }
        }
    }
}
