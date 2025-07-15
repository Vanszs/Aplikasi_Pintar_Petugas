import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/report.dart';

class NotificationService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService() {
    _initializeNotifications();
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel newReportsChannel = AndroidNotificationChannel(
      'new_reports',
      'Laporan Baru',
      description: 'Notifikasi saat ada laporan baru',
      importance: Importance.max,
    );

    const AndroidNotificationChannel statusUpdatesChannel = AndroidNotificationChannel(
      'status_updates',
      'Status Laporan',
      description: 'Notifikasi saat status laporan berubah',
      importance: Importance.high,
    );

    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'Notifikasi Umum',
      description: 'Notifikasi umum aplikasi',
      importance: Importance.high,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(newReportsChannel);
    await androidPlugin?.createNotificationChannel(statusUpdatesChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);
    
    developer.log('Notification channels created', name: 'NotificationService');
  }

  Future<void> _initializeNotifications() async {
    try {
      // Create notification channel for Android 8.0+
      await _createNotificationChannel();
      
      // Use launcher_icon instead of ic_launcher for better app branding
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

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
      developer.log('NotificationService: Notification service initialized successfully', name: 'NotificationService');
      
      // Request permissions after initialization
      await requestNotificationPermissions();
    } catch (e) {
      developer.log('NotificationService: Error initializing notification service: $e', name: 'NotificationService');
    }
  }
  
  Future<bool> requestNotificationPermissions() async {
    try {
      // Check Android version and request appropriate permissions
      final androidInfo = await _getAndroidInfo();
      
      if (androidInfo >= 33) {
        // Android 13+ (API 33+) - Use permission_handler for better control
        final status = await Permission.notification.request();
        
        if (status.isGranted) {
          developer.log('NotificationService: Android 13+ notification permission granted', name: 'NotificationService');
          return true;
        } else if (status.isPermanentlyDenied) {
          developer.log('NotificationService: Android 13+ notification permission permanently denied', name: 'NotificationService');
          return false;
        } else {
          developer.log('NotificationService: Android 13+ notification permission denied', name: 'NotificationService');
          return false;
        }
      }
      
      // Fallback for older Android versions
      final android = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        try {
          final bool? granted = await android.requestNotificationsPermission();
          developer.log('NotificationService: Android notification permission granted: $granted', name: 'NotificationService');
          return granted ?? false;
        } catch (e) {
          developer.log('NotificationService: Could not request notification permission: $e', name: 'NotificationService');
          // Fallback to checking if notifications are enabled
          try {
            final bool? enabled = await android.areNotificationsEnabled();
            developer.log('NotificationService: Android notifications enabled (fallback check): $enabled', name: 'NotificationService');
            return enabled ?? false;
          } catch (e2) {
            developer.log('NotificationService: Could not check notification status: $e2', name: 'NotificationService');
            return false;
          }
        }
      }
      
      // For iOS, permissions are requested during initialization
      developer.log('NotificationService: Notification permissions requested successfully', name: 'NotificationService');
      return true;
    } catch (e) {
      developer.log('NotificationService: Error requesting notification permissions: $e', name: 'NotificationService');
      return false;
    }
  }

  Future<int> _getAndroidInfo() async {
    try {
      // Simple way to check if we're on Android 13+
      return 33; // Assume modern Android for safety
    } catch (e) {
      return 30; // Fallback to older version
    }
  }

  Future<bool> checkNotificationPermissions() async {
    try {
      // First try using permission_handler for more accurate results
      final status = await Permission.notification.status;
      
      if (status.isGranted) {
        return true;
      } else if (status.isDenied || status.isPermanentlyDenied) {
        return false;
      }
      
      // Fallback to flutter_local_notifications method
      final android = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        try {
          final bool? enabled = await android.areNotificationsEnabled();
          developer.log('NotificationService: Android notifications enabled: $enabled', name: 'NotificationService');
          return enabled ?? false;
        } catch (e) {
          developer.log('NotificationService: Could not check notification status: $e', name: 'NotificationService');
          return false;
        }
      }
      
      // For iOS, assume permissions are granted if service is initialized
      return _isInitialized;
    } catch (e) {
      developer.log('NotificationService: Error checking notification permissions: $e', name: 'NotificationService');
      return false;
    }
  }

  Future<AndroidNotificationDetails> _getNotificationDetails(String channelId, String channelName, {Color color = const Color(0xFF6366F1)}) async {
    final prefs = await SharedPreferences.getInstance();
    final sound = prefs.getString('notification_sound');

    return AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      ticker: 'Laporan baru masuk',
      color: color,
      enableLights: true,
      ledColor: color,
      ledOnMs: 1000,
      ledOffMs: 500,
      playSound: true,
      sound: sound != null ? UriAndroidNotificationSound(sound) : null,
      enableVibration: false,
      category: AndroidNotificationCategory.alarm,
      autoCancel: true,
      icon: '@drawable/ic_notification',
      largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
      colorized: true,
    );
  }

  Future<void> showNewReportNotification(Report report) async {
    // Check if we have permission before trying to show notification
    final hasPermission = await checkNotificationPermissions();
    if (!hasPermission) {
      developer.log('NotificationService: No notification permission, skipping notification for report ${report.id}', name: 'NotificationService');
      return;
    }

    // Ensure initialization is complete before showing notification
    if (!_isInitialized) {
      developer.log('NotificationService: Notification service not initialized yet, retrying initialization', name: 'NotificationService');
      try {
        await _initializeNotifications();
        await requestNotificationPermissions(); // Make sure permissions are granted
      } catch (e) {
        developer.log('NotificationService: Error during notification init retry: $e', name: 'NotificationService');
      }
      
      // Double-check initialization status
      if (!_isInitialized) {
        developer.log('NotificationService: Failed to initialize notification service after retry', name: 'NotificationService');
        // Try one more time with a delay - this helps in some Android environments
        await Future.delayed(Duration(milliseconds: 500));
        await _initializeNotifications();
      }
    }

    try {
      // Configure notification details optimized for foreground/background
      final AndroidNotificationDetails androidNotificationDetails = await _getNotificationDetails('new_reports', 'Laporan Baru');

      const DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      // Show simplified notification with report type
      String reportType = report.jenisLaporan?.toUpperCase() ?? 'LAPORAN BARU';
      String address = report.address;
      
      await _flutterLocalNotificationsPlugin.show(
        report.id,
        'Laporan Baru Diterima',
        '$reportType - $address',
        notificationDetails,
        payload: report.id.toString(),
      );

      developer.log('NotificationService: New report notification displayed for ID: ${report.id}', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error showing notification: $e', name: 'NotificationService');
      
      // Try to check and request permissions again
      try {
        final hasPermissionAfterError = await checkNotificationPermissions();
        if (!hasPermissionAfterError) {
          developer.log('NotificationService: Notification permission lost, attempting to re-request', name: 'NotificationService');
          await requestNotificationPermissions();
        }
      } catch (permissionError) {
        developer.log('NotificationService: Error checking notification permissions after notification failure: $permissionError', name: 'NotificationService');
      }
    }
  }

  Future<void> showStatusUpdateNotification(int reportId, String status) async {
    // Ensure initialization is complete before showing notification
    if (!_isInitialized) {
      await _initializeNotifications();
    }

    try {
      // Map status to Indonesian display name
      String statusDisplay = '';
      Color statusColor = const Color(0xFF6366F1);
      
      switch (status.toLowerCase()) {
        case 'pending':
          statusDisplay = 'Menunggu';
          statusColor = const Color(0xFFF59E0B);
          break;
        case 'processing':
          statusDisplay = 'Sedang Diproses';
          statusColor = const Color(0xFF3B82F6);
          break;
        case 'completed':
          statusDisplay = 'Selesai';
          statusColor = const Color(0xFF10B981);
          break;
        case 'rejected':
          statusDisplay = 'Ditolak';
          statusColor = const Color(0xFFEF4444);
          break;
        default:
          statusDisplay = 'Status Berubah';
          break;
      }

      final AndroidNotificationDetails androidNotificationDetails = await _getNotificationDetails('status_updates', 'Status Laporan', color: statusColor);

      const DarwinNotificationDetails iOSNotificationDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: iOSNotificationDetails,
      );

      // Use a different ID for status updates to avoid overwriting report notifications
      final notificationId = reportId + 10000; // Offset to avoid collision
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'Status Laporan Diperbarui',
        'Laporan #$reportId status sekarang: $statusDisplay',
        notificationDetails,
      );
      
      developer.log('NotificationService: Status update notification shown for report #$reportId: $status', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error showing status update notification: $e', name: 'NotificationService');
    }
  }

  // Simple notification method for general messages
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_isInitialized) {
        developer.log('NotificationService: Notifications not initialized, cannot show simple notification', name: 'NotificationService');
        return;
      }

      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'general_notifications',
        'Notifikasi Umum',
        channelDescription: 'Notifikasi umum aplikasi',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@drawable/ic_notification',
        largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
        enableVibration: true,
        playSound: true,
        color: Color(0xFF2196F3), // Blue color for Petugas app
        colorized: true,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.public,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        999, // Use fixed ID for simple notifications
        title,
        body,
        notificationDetails,
        payload: payload,
      );
      
      developer.log('NotificationService: Simple notification shown: $title', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error showing simple notification: $e', name: 'NotificationService');
    }
  }

  // Force notification test (emergency test)
  Future<void> forceEmergencyNotificationTest() async {
    try {
      developer.log('🚨🚨🚨 NotificationService: FORCING EMERGENCY TEST NOTIFICATION 🚨🚨🚨', name: 'NotificationService');
      
      // Create notification channel for high priority alerts
      const AndroidNotificationChannel emergencyChannel = AndroidNotificationChannel(
        'emergency_alerts',
        'Emergency Alerts',
        description: 'Notifikasi darurat yang sangat penting',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        enableVibration: true,
        playSound: true,
        showBadge: true,
        enableLights: true,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();
      
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidPlugin?.createNotificationChannel(emergencyChannel);

      // Send immediate emergency test notification
      const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'emergency_alerts',
        'Emergency Alerts',
        channelDescription: 'Notifikasi darurat yang sangat penting',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        icon: '@drawable/ic_notification',
        largeIcon: DrawableResourceAndroidBitmap('@drawable/ic_notification_large'),
        enableVibration: true,
        playSound: true,
        color: Color(0xFFFF0000), // Red color for emergency
        colorized: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ticker: 'TEST EMERGENCY NOTIFICATION',
        ongoing: true, // Make it persistent
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        9999, // Emergency test ID
        '🚨 EMERGENCY TEST NOTIFICATION',
        'This is an emergency test notification with highest priority. If you see this, the notification system is working.',
        notificationDetails,
      );
      
      developer.log('NotificationService: Emergency test notification sent successfully', name: 'NotificationService');
    } catch (e) {
      developer.log('NotificationService: Error sending emergency test notification: $e', name: 'NotificationService');
    }
  }

  // Method to handle notifications from FCM message
  Future<void> showNotificationFromMessage(RemoteMessage message, {bool isHighPriority = false}) async {
    try {
      developer.log('NotificationService: Showing notification from FCM message: ${message.messageId}', name: 'NotificationService');
      developer.log('NotificationService: Message data: ${message.data}', name: 'NotificationService');
      developer.log('NotificationService: Message notification: ${message.notification?.title} / ${message.notification?.body}', name: 'NotificationService');
      
      // Check if we have permission before trying to show notification
      final hasPermission = await checkNotificationPermissions();
      if (!hasPermission) {
        developer.log('NotificationService: No notification permission, skipping notification', name: 'NotificationService');
        return;
      }

      // Ensure initialization is complete
      if (!_isInitialized) {
        developer.log('NotificationService: Notification service not initialized yet, initializing now', name: 'NotificationService');
        await _initializeNotifications();
      }

      final data = message.data;
      
      // Handle different message types
      switch (data['type']) {
        case 'new_report':
          // Create a Report object from the message data
          final report = Report(
            id: int.tryParse(data['reportId'] ?? '0') ?? 0,
            userId: int.tryParse(data['userId'] ?? '0') ?? 0,
            address: data['address'] ?? 'Alamat tidak tersedia',
            phone: data['userPhone'] ?? '',
            userName: data['userName'] ?? 'Pengguna',
            jenisLaporan: data['jenisLaporan'] ?? 'Laporan Baru',
            status: data['status'] ?? 'pending',
            createdAt: DateTime.now(),
          );
          
          // Show notification with report details
          await showNewReportNotification(report);
          developer.log('NotificationService: New report notification displayed for ID: ${report.id}', name: 'NotificationService');
          break;
          
        case 'status_update':
          // Show status update notification
          final reportId = int.tryParse(data['reportId'] ?? '0') ?? 0;
          final status = data['status'] ?? 'updated';
          
          await showStatusUpdateNotification(reportId, status);
          developer.log('NotificationService: Status update notification displayed for report #$reportId', name: 'NotificationService');
          break;
          
        default:
          // For all other types, use data from the notification payload or fallback to defaults
          final title = message.notification?.title ?? data['title'] ?? 'Notifikasi Baru';
          final body = message.notification?.body ?? data['body'] ?? 'Ada pesan baru untuk Anda';
          
          await showSimpleNotification(
            title: title,
            body: body,
            payload: message.data.toString(),
          );
          developer.log('NotificationService: Generic notification displayed with title: $title', name: 'NotificationService');
          break;
      }
    } catch (e) {
      developer.log('NotificationService: Error showing notification from message: $e', name: 'NotificationService');
      
      // Fallback to showing a simple notification if anything fails
      try {
        final title = message.notification?.title ?? 'Notifikasi';
        final body = message.notification?.body ?? 'Ada pesan baru';
        
        await showSimpleNotification(
          title: title,
          body: body,
          payload: message.data.toString(),
        );
      } catch (fallbackError) {
        developer.log('NotificationService: Error showing fallback notification: $fallbackError', name: 'NotificationService');
      }
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
