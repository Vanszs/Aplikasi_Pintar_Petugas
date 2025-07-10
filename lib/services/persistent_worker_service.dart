import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'background_service.dart';

// Constants
const String LAST_RUN_TIMESTAMP_KEY = "last_service_run_timestamp";

class PersistentWorkerService {
  static bool _isInitialized = false;
  static const MethodChannel _channel = MethodChannel('com.example.petugas_pintar/persistent_worker');
  static Timer? _periodicServiceTimer;
  static Timer? _dailyServiceTimer;
  
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Use native custom alarm through platform channel
      await _scheduleCustomAlarm();
      
      // Start a reliable periodic timer in Dart
      _startPeriodicTimers();
      
      _isInitialized = true;
      developer.log("PersistentWorkerService initialized", name: "PersistentWorker");
    } catch (e) {
      developer.log("Error initializing PersistentWorkerService: $e", name: "PersistentWorker");
    }
  }

  // Start timers to periodically ensure service is running
  static void _startPeriodicTimers() {
    // Cancel any existing timers
    _periodicServiceTimer?.cancel();
    _dailyServiceTimer?.cancel();
    
    // Start periodic timer (every 15 minutes)
    _periodicServiceTimer = Timer.periodic(const Duration(minutes: 15), (timer) async {
      developer.log("Periodic timer triggered", name: "PersistentWorker");
      await _ensureServiceRunning();
    });
    
    // Start daily timer (24 hours)
    _dailyServiceTimer = Timer.periodic(const Duration(hours: 24), (timer) async {
      developer.log("Daily timer triggered", name: "PersistentWorker");
      await _ensureServiceRunning();
    });
    
    // Immediately run once
    _ensureServiceRunning();
  }
  
  // Ensure the service is running
  static Future<void> _ensureServiceRunning() async {
    try {
      final isRunning = await BackgroundService.isRunning();
      developer.log("Service running check: $isRunning", name: "PersistentWorker");
      
      if (!isRunning) {
        developer.log("Service not running, starting it", name: "PersistentWorker");
        await BackgroundService.startService();
      }
      
      // Record successful run in any case
      await recordServiceRun();
      
      // Check our native alarm registration
      await _scheduleCustomAlarm();
    } catch (e) {
      developer.log("Error ensuring service is running: $e", name: "PersistentWorker");
      
      // Try to start service anyway
      try {
        await BackgroundService.startService();
      } catch (e2) {
        developer.log("Error starting service in recovery: $e2", name: "PersistentWorker");
      }
    }
  }
  
  // Use custom platform-specific approach instead of AlarmManager
  static Future<void> _scheduleCustomAlarm() async {
    try {
      // Using native platform channel directly with our custom receiver
      final bool success = await _channel.invokeMethod('scheduleCustomAlarm') ?? false;
      developer.log("Custom alarm scheduling result: $success", name: "PersistentWorker");
    } catch (e) {
      developer.log("Error scheduling custom alarm: $e", name: "PersistentWorker");
    }
  }
  
  // Record successful service run
  static Future<void> recordServiceRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LAST_RUN_TIMESTAMP_KEY, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      developer.log("Error recording service run: $e", name: "PersistentWorker");
    }
  }
  
  // Check when service last ran
  static Future<DateTime?> getLastServiceRunTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(LAST_RUN_TIMESTAMP_KEY);
      
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      developer.log("Error getting last service run time: $e", name: "PersistentWorker");
      return null;
    }
  }
  
  // Cleanup
  static void dispose() {
    _periodicServiceTimer?.cancel();
    _dailyServiceTimer?.cancel();
    _periodicServiceTimer = null;
    _dailyServiceTimer = null;
  }
}
