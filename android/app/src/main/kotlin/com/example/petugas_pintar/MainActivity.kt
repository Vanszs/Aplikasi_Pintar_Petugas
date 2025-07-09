package com.example.petugas_pintar

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("VRI", "MainActivity onCreate")
    }
    
    override fun onPause() {
        super.onPause()
        Log.d("VRI", "MainActivity onPause")
    }
    
    override fun onResume() {
        super.onResume()
        Log.d("VRI", "MainActivity onResume")
    }
    
    override fun onStop() {
        super.onStop()
        Log.d("VRI", "MainActivity onStop")
    }
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d("VRI", "MainActivity onDestroy")
    }
    
    override fun onBackPressed() {
        // When back is pressed, move the app to background rather than closing
        moveTaskToBack(true)
    }
}
