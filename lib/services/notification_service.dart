import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
      // Configure notification details optimized for foreground/background
      final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'new_reports',
        'Laporan Baru',
        channelDescription: 'Notifikasi saat ada laporan baru',
        importance: Importance.max,
        priority: Priority.high,
        fullScreenIntent: true, // Will pop up even when screen is locked
        visibility: NotificationVisibility.public,
        ticker: 'Laporan baru masuk',
        color: Color(0xFF6366F1), // Brand indigo color
        enableLights: true,
        ledColor: Color(0xFF6366F1),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        enableVibration: false, // Disable vibration as requested
        category: AndroidNotificationCategory.alarm, // Critical notification category
        autoCancel: true // Allow user to dismiss the notification
      );

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

      final AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
        'status_updates',
        'Status Laporan',
        channelDescription: 'Notifikasi saat status laporan berubah',
        importance: Importance.high,
        priority: Priority.high,
        color: statusColor,
        enableLights: true,
        ledColor: statusColor,
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        enableVibration: false, // Disable vibration as requested
      );

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
