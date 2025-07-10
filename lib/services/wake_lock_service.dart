import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:developer' as developer;

class WakeLockService {
  static bool _isEnabled = false;
  static Timer? _keepAliveTimer;
  
  // Initialize and enable wake lock with background keepalive
  static Future<void> enableWakeLock() async {
    if (_isEnabled) return;
    
    try {
      // Enable basic wakelock
      await WakelockPlus.enable();
      _isEnabled = true;
      
      developer.log('WakeLock enabled successfully', name: 'WakeLockService');
      
      // Create a keepalive timer that pulses the CPU periodically
      // to help prevent aggressive background throttling
      _startKeepAliveTimer();
      
    } catch (e) {
      developer.log('Error enabling WakeLock: $e', name: 'WakeLockService');
    }
  }
  
  // Disable wake lock if needed
  static Future<void> disableWakeLock() async {
    if (!_isEnabled) return;
    
    try {
      _stopKeepAliveTimer();
      await WakelockPlus.disable();
      _isEnabled = false;
      developer.log('WakeLock disabled', name: 'WakeLockService');
    } catch (e) {
      developer.log('Error disabling WakeLock: $e', name: 'WakeLockService');
    }
  }
  
  // Start a timer to keep the CPU from fully sleeping
  static void _startKeepAliveTimer() {
    _stopKeepAliveTimer();
    
    // Create a timer that executes a small computation every 10 seconds
    // This helps prevent Android from fully suspending the app process
    _keepAliveTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _performKeepAliveTask();
    });
    
    developer.log('Keep-alive timer started', name: 'WakeLockService');
  }
  
  // Stop the keepalive timer
  static void _stopKeepAliveTimer() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }
  
  // Perform a lightweight CPU task to keep the process from being suspended
  static void _performKeepAliveTask() {
    // A simple computation that keeps the CPU active for a brief moment
    if (kReleaseMode) {
      int result = 0;
      for (int i = 0; i < 10000; i++) {
        result += i % 17;
      }
      
      // Only log in debug mode for diagnostics
      if (kDebugMode) {
        developer.log('Keep-alive pulse: $result', name: 'WakeLockService');
      }
    }
  }
  
  // Check if wakelock is currently enabled
  static bool get isEnabled => _isEnabled;
}
