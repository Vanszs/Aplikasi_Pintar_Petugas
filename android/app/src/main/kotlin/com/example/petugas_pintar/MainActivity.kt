package com.example.petugas_pintar

import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val TAG = "PetugasPintar"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")

        // Log Android version information for debugging
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Log.d(TAG, "Running on Android 13+ (API ${Build.VERSION.SDK_INT})")
            Log.d(TAG, "Foreground service type enforcement is active")
        } else {
            Log.d(TAG, "Running on Android ${Build.VERSION.SDK_INT}")
        }
    }
    
    override fun onPause() {
        super.onPause()
        Log.d(TAG, "MainActivity onPause")
    }
    
    override fun onResume() {
        super.onResume()
        Log.d(TAG, "MainActivity onResume")
    }
    
    override fun onStop() {
        super.onStop()
        Log.d(TAG, "MainActivity onStop")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "MainActivity onDestroy")
    }
    
    override fun onBackPressed() {
        // When back is pressed, move the app to background rather than closing
        moveTaskToBack(true)
    }
}
