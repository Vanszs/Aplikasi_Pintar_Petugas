import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
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
    if (!_isInitialized) {
      developer.log('Notification service not initialized yet', name: 'NotificationService');
      return;
    }

    try {
      // Pertama, vibrate
      await vibrate();

      // Kemudian tampilkan notifikasi
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'new_reports',
        'Laporan Baru',
        channelDescription: 'Notifikasi saat ada laporan baru',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true, // Will pop up even when screen is locked
        ticker: 'ticker',
        color: Color(0xFF6366F1), // Warna brand indigo
        enableLights: true,
        ledColor: Color(0xFF6366F1),
        ledOnMs: 1000,
        ledOffMs: 500,
        // Gunakan default sound
        playSound: true,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      );

      const DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        // Gunakan default sound untuk iOS
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      // Simplified notification - no need for address or time
      
      await _flutterLocalNotificationsPlugin.show(
        report.id,
        'Laporan baru diterima',
        '${report.getReportType().toUpperCase()}',
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
        // Pola getaran untuk notifikasi laporan baru - lebih kuat dan lebih lama
        // [waktu tunggu ms, getaran ms, waktu tunggu ms, getaran ms]
        await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
        developer.log('Device vibrated for new report', name: 'NotificationService');
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
