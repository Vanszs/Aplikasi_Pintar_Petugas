package com.example.petugas_pintar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import java.util.Calendar

/**
 * This BroadcastReceiver is triggered by AlarmManager
 * to ensure our background service is kept alive
 */
class ServiceAlarmReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ServiceAlarmReceiver"
        private const val ALARM_ID = 9753
        private const val INTERVAL_MINUTES = 15

        /**
         * Schedule a custom periodic task using Handler instead of AlarmManager
         * This provides similar functionality without the alarm manager dependency
         */
        fun scheduleAlarm(context: Context) {
            try {
                // Create a simple handler that will periodically start our service
                val handler = Handler(Looper.getMainLooper())
                
                // Setup a repeating runnable task
                val runnableTask = object : Runnable {
                    override fun run() {
                        try {
                            // Start the Flutter background service
                            val serviceIntent = Intent(context, Class.forName("id.flutter.flutter_background_service.BackgroundService"))
                            serviceIntent.action = "id.flutter.flutter_background_service.ACTION_START"
                            
                            // Modify the intent for proper foreground service type
                            BackgroundServiceHelper.modifyForegroundServiceIntent(serviceIntent)
                            
                            // Start service based on Android version
                            if (Build.VERSION.SDK_INT >= 26) {
                                context.startForegroundService(serviceIntent)
                            } else {
                                context.startService(serviceIntent)
                            }
                            
                            Log.d(TAG, "Background service started from custom periodic task")
                        } catch (e: Exception) {
                            Log.e(TAG, "Error starting service from custom task: ${e.message}")
                        }
                        
                        // Reschedule this runnable
                        handler.postDelayed(this, INTERVAL_MINUTES * 60 * 1000L)
                    }
                }
                
                // Start the periodic task after a short delay
                handler.postDelayed(runnableTask, 30000) // 30 seconds delay for first run
                
                Log.d(TAG, "Custom periodic task scheduled successfully")
            } catch (e: Exception) {
                Log.e(TAG, "Error scheduling custom task: ${e.message}")
            }
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "Broadcast receiver triggered, intent action: ${intent?.action}")
        
        if (context == null) {
            Log.e(TAG, "Context is null, cannot proceed")
            return
        }
        
        if (intent?.action == "com.example.petugas_pintar.START_BACKGROUND_SERVICE" ||
            intent?.action == Intent.ACTION_BOOT_COMPLETED ||
            intent?.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            
            try {
                // Start the Flutter background service
                val serviceIntent = Intent(context, Class.forName("id.flutter.flutter_background_service.BackgroundService"))
                serviceIntent.action = "id.flutter.flutter_background_service.ACTION_START"
                
                // Modify the intent for proper foreground service type
                BackgroundServiceHelper.modifyForegroundServiceIntent(serviceIntent)
                
                // Start service based on Android version
                if (Build.VERSION.SDK_INT >= 26) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
                
                Log.d(TAG, "Background service started from broadcast receiver")
                
                // Schedule the periodic task
                scheduleAlarm(context)
            } catch (e: Exception) {
                Log.e(TAG, "Error starting service from broadcast receiver: ${e.message}")
            }
        }
    }
}
