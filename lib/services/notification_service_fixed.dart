import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
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

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(newReportsChannel);
    await androidPlugin?.createNotificationChannel(statusUpdatesChannel);
    
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
      developer.log('Notification service initialized successfully', name: 'NotificationService');
      
      // Request permissions after initialization
      await requestNotificationPermissions();
    } catch (e) {
      developer.log('Error initializing notification service: $e', name: 'NotificationService');
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
          developer.log('Android 13+ notification permission granted', name: 'NotificationService');
          return true;
        } else if (status.isPermanentlyDenied) {
          developer.log('Android 13+ notification permission permanently denied', name: 'NotificationService');
          return false;
        } else {
          developer.log('Android 13+ notification permission denied', name: 'NotificationService');
          return false;
        }
      }
      
      // Fallback for older Android versions
      final android = _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        try {
          final bool? granted = await android.requestNotificationsPermission();
          developer.log('Android notification permission granted: $granted', name: 'NotificationService');
          return granted ?? false;
        } catch (e) {
          developer.log('Could not request notification permission: $e', name: 'NotificationService');
          // Fallback to checking if notifications are enabled
          try {
            final bool? enabled = await android.areNotificationsEnabled();
            developer.log('Android notifications enabled (fallback check): $enabled', name: 'NotificationService');
            return enabled ?? false;
          } catch (e2) {
            developer.log('Could not check notification status: $e2', name: 'NotificationService');
            return false;
          }
        }
      }
      
      // For iOS, permissions are requested during initialization
      developer.log('Notification permissions requested successfully', name: 'NotificationService');
      return true;
    } catch (e) {
      developer.log('Error requesting notification permissions: $e', name: 'NotificationService');
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
          developer.log('Android notifications enabled: $enabled', name: 'NotificationService');
          return enabled ?? false;
        } catch (e) {
          developer.log('Could not check notification status: $e', name: 'NotificationService');
          return false;
        }
      }
      
      // For iOS, assume permissions are granted if service is initialized
      return _isInitialized;
    } catch (e) {
      developer.log('Error checking notification permissions: $e', name: 'NotificationService');
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
      icon: '@mipmap/launcher_icon',
    );
  }

  Future<void> showNewReportNotification(Report report) async {
    // Check if we have permission before trying to show notification
    final hasPermission = await checkNotificationPermissions();
    if (!hasPermission) {
      developer.log('No notification permission, skipping notification for report ${report.id}', name: 'NotificationService');
      return;
    }

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

      developer.log('New report notification displayed for ID: ${report.id}', name: 'NotificationService');
    } catch (e) {
      developer.log('Error showing notification: $e', name: 'NotificationService');
      
      // Try to check and request permissions again
      try {
        final hasPermissionAfterError = await checkNotificationPermissions();
        if (!hasPermissionAfterError) {
          developer.log('Notification permission lost, attempting to re-request', name: 'NotificationService');
          await requestNotificationPermissions();
        }
      } catch (permissionError) {
        developer.log('Error checking notification permissions after notification failure: $permissionError', name: 'NotificationService');
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
      
      developer.log('Status update notification shown for report #$reportId: $status', name: 'NotificationService');
    } catch (e) {
      developer.log('Error showing status update notification: $e', name: 'NotificationService');
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
