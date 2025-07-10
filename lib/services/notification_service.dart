import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:typed_data';
import '../models/report.dart';

class NotificationService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService() {
    _initializeNotifications();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'new_reports',
      'Laporan Baru',
      description: 'Notifikasi saat ada laporan baru',
      importance: Importance.max,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    developer.log('Notification channel created', name: 'NotificationService');
  }

  Future<void> _initializeNotifications() async {
    try {
      // Create notification channel for Android 8.0+
      await _createNotificationChannel();
      
      // Use ic_launcher instead of launcher_icon for Android as it's the standard name
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );

      _isInitialized = true;
      developer.log('Notification service initialized successfully', name: 'NotificationService');
      
      // Request permissions after initialization
      await requestNotificationPermissions();
    } catch (e) {
      developer.log('Error initializing notification service: $e', name: 'NotificationService');
    }
  }
  
  Future<void> requestNotificationPermissions() async {
    try {
      // Request permissions for Android
      final android = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // Permintaan izin bervariasi tergantung versi plugin
        // Untuk versi terbaru (16+)
        try {
          final bool? granted = await android.areNotificationsEnabled();
          developer.log('Android notifications enabled: $granted', name: 'NotificationService');
        } catch (e) {
          developer.log('Could not check notification status: $e', name: 'NotificationService');
        }
      }
      
      // For iOS, permissions are requested during initialization with DarwinInitializationSettings
      
      developer.log('Notification permissions requested successfully', name: 'NotificationService');
    } catch (e) {
      developer.log('Error requesting notification permissions: $e', name: 'NotificationService');
    }
  }

  Future<void> showNewReportNotification(Report report) async {
    // Ensure initialization is complete before showing notification
    if (!_isInitialized) {
      developer.log('Notification service not initialized yet, retrying initialization', name: 'NotificationService');
      try {
        await _initializeNotifications();
        await requestNotificationPermissions(); // Make sure permissions are granted
      } catch (e) {
        developer.log('Error during notification init retry: $e', name: 'NotificationService');
      }
      
      // Double-check initialization status
      if (!_isInitialized) {
        developer.log('Failed to initialize notification service after retry', name: 'NotificationService');
        // Try one more time with a delay - this helps in some Android environments
        await Future.delayed(Duration(milliseconds: 500));
        await _initializeNotifications();
      }
    }

    try {
      // Pertama, vibrate
      await vibrate();

      // Kemudian tampilkan notifikasi dengan pengaturan yang dioptimalkan untuk background
      // Define vibration pattern
      final vibrationPattern = Int64List(6);
      vibrationPattern[0] = 0;
      vibrationPattern[1] = 500;
      vibrationPattern[2] = 200;
      vibrationPattern[3] = 500;
      vibrationPattern[4] = 200;
      vibrationPattern[5] = 500;
      
      // Kemudian tampilkan notifikasi dengan pengaturan yang dioptimalkan untuk background
      final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'new_reports',
        'Laporan Baru',
        channelDescription: 'Notifikasi saat ada laporan baru',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // Will pop up even when screen is locked
        visibility: NotificationVisibility.public,
        ticker: 'ticker',
        color: Color(0xFF6366F1), // Warna brand indigo
        enableLights: true,
        ledColor: Color(0xFF6366F1),
        ledOnMs: 1000,
        ledOffMs: 500,
        // Gunakan default sound
        playSound: true,
        enableVibration: true,
        vibrationPattern: vibrationPattern,
        category: AndroidNotificationCategory.alarm, // Critical notification category
        ongoing: true, // Make it persistent until user interacts with it
        autoCancel: false, // Don't auto-cancel the notification
        timeoutAfter: 300000, // 5 minutes in milliseconds
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Gunakan default sound untuk iOS
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      // Simplified notification - just show report type as requested
      await _flutterLocalNotificationsPlugin.show(
        report.id,
        'Laporan baru diterima',
        report.getReportType().toUpperCase(),
        notificationDetails,
      );

      developer.log('New report notification displayed for ID: ${report.id}', name: 'NotificationService');
    } catch (e) {
      developer.log('Error showing notification: $e', name: 'NotificationService');
    }
  }

  Future<void> vibrate() async {
    try {
      // Cek apakah device mendukung vibration
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        // Multiple attempts to ensure vibration works
        for (int i = 0; i < 2; i++) {
          try {
            // Pola getaran untuk notifikasi laporan baru - lebih kuat dan lebih lama
            // [waktu tunggu ms, getaran ms, waktu tunggu ms, getaran ms]
            await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
            developer.log('Device vibrated for new report', name: 'NotificationService');
            break; // Stop if successful
          } catch (e) {
            developer.log('Vibration attempt $i failed: $e', name: 'NotificationService');
            await Future.delayed(Duration(milliseconds: 300)); // Wait before retry
          }
        }
      } else {
        developer.log('Device does not support vibration', name: 'NotificationService');
      }
    } catch (e) {
      developer.log('Error during vibration: $e', name: 'NotificationService');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
