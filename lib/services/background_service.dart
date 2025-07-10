import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:developer' as developer;
import '../models/report.dart';
import 'wake_lock_service.dart';

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();
  static final String serverUrl = 'http://185.197.195.155:3000';
  static bool _isInitialized = false;

  static Future<void> initializeService() async {
    if (_isInitialized) return;

    // Create notification channel
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'petugas_pintar_background',
            'Petugas Pintar Background Service',
            description: 'Pastikan laporan baru selalu terkirim meskipun aplikasi ditutup',
            importance: Importance.high,
          ),
        );      // Configure service with more aggressive settings for Android battery optimization
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceNotificationId: 888,
        initialNotificationTitle: 'Petugas Pintar Aktif',
        initialNotificationContent: 'Memantau laporan baru...',
        notificationChannelId: 'petugas_pintar_background',
        autoStartOnBoot: true,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
    
    developer.log('Background service initialized successfully', name: 'BackgroundService');
    _isInitialized = true;
  }

  // iOS background handler
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  // Main service entry point
  static Future<void> onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Enable wakelock to keep CPU active
    try {
      await WakeLockService.enableWakeLock();
      developer.log('WakeLock enabled in background service', name: 'BackgroundService');
    } catch (e) {
      developer.log('Failed to enable WakeLock in background: $e', name: 'BackgroundService');
    }

    // For Android - set as foreground service with notification
    // Note: Foreground service type is now set in AndroidManifest.xml
    // with android:foregroundServiceType="dataSync|connectedDevice"
    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'Petugas Pintar Aktif',
        content: 'Siap menerima notifikasi laporan',
      );
    }

    // Debug log
    developer.log('Background service started', name: 'BackgroundService');

    // Initialize socket connection
    IO.Socket? socket;
    bool isConnected = false;
    
    // Function to connect/reconnect socket with more robustness
    void connectSocket() {
      try {
        // Disconnect previous connection if exists
        if (socket != null) {
          try {
            socket!.disconnect();
            socket!.dispose();
          } catch (e) {
            developer.log('Error disposing previous socket: $e', name: 'BackgroundService');
          }
        }
        
        // Create fresh socket with extremely aggressive settings to stay alive
        developer.log('Connecting to socket from background service: $serverUrl', name: 'BackgroundService');
        socket = IO.io(serverUrl, <String, dynamic>{
          'transports': ['websocket', 'polling'], // Try both transports
          'autoConnect': true,
          'reconnection': true,
          'reconnectionDelay': 500,  // Faster reconnection
          'reconnectionDelayMax': 3000, // Lower max delay
          'reconnectionAttempts': 999999, // Keep trying forever
          'forceNew': true, 
          'timeout': 30000, // Longer timeout
          'pingTimeout': 60000, // Much longer ping timeout
          'pingInterval': 10000, // More frequent pings
          'path': '/socket.io',
          'extraHeaders': {
            'Connection': 'keep-alive',
            'Keep-Alive': 'timeout=60, max=1000' // More aggressive keep-alive
          },
          'nsp': '/iot'  // Connect to IoT namespace
        });

        // Socket event listeners
        socket!.onConnect((_) {
          isConnected = true;
          developer.log('Socket connected from background service: ${socket!.id}', name: 'BackgroundService');
          // Update service notification
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Petugas Pintar Aktif',
              content: 'Terhubung dan memantau laporan baru',
            );
          }
        });

        socket!.onDisconnect((_) {
          isConnected = false;
          developer.log('Socket disconnected in background service', name: 'BackgroundService');
          // Try to reconnect after short delay
          Future.delayed(Duration(seconds: 5), connectSocket);
        });

        socket!.onError((error) {
          isConnected = false;
          developer.log('Socket error in background service: $error', name: 'BackgroundService');
          // Try to reconnect after error
          Future.delayed(Duration(seconds: 5), connectSocket);
        });

        // Listen for new reports
        socket!.on('new_report', (data) async {
          try {
            developer.log('New report received in background service: $data', name: 'BackgroundService');
            
            // Validate data before processing
            if (data == null) {
              developer.log('Received null data in new_report event', name: 'BackgroundService');
              return;
            }
            
            // Extract data safely with null checks
            final reportId = data['id'] is int ? data['id'] : 0;
            final address = data['address'] is String ? data['address'] : 'Alamat tidak diketahui';
            String createdAtStr = '';
            
            // Safely handle date parsing
            try {
              createdAtStr = data['created_at'] is String ? data['created_at'] : DateTime.now().toIso8601String();
            } catch (e) {
              createdAtStr = DateTime.now().toIso8601String();
            }
            
            final userName = data['name'] is String ? data['name'] : 'Tanpa nama';
            final jenisLaporan = data['jenis_laporan'] is String ? data['jenis_laporan'] : 'Umum';
            
            // Create report object
            final report = Report(
              id: reportId,
              userId: 0,
              address: address,
              createdAt: DateTime.parse(createdAtStr),
              userName: userName,
              jenisLaporan: jenisLaporan,
            );
            
            developer.log('Processed report data: ID=$reportId, Type=$jenisLaporan', name: 'BackgroundService');
            
            // Show notification with try-catch for safety
            try {
              await showBackgroundNotification(report);
            } catch (e) {
              developer.log('Error showing notification: $e', name: 'BackgroundService');
            }
            
            // Signal to the app if it's running - with error handling
            try {
              service.invoke('new_report_received', {
                'report_id': reportId,
                'timestamp': DateTime.now().millisecondsSinceEpoch,
              });
              developer.log('Sent signal to main app for report: $reportId', name: 'BackgroundService');
            } catch (e) {
              developer.log('Error invoking main app: $e', name: 'BackgroundService');
            }
            
          } catch (e) {
            developer.log('Error processing new report in background: $e', name: 'BackgroundService');
          }
        });
      } catch (e) {
        developer.log('Error connecting to socket in background: $e', name: 'BackgroundService');
        // Try again after delay
        Future.delayed(Duration(seconds: 10), connectSocket);
      }
    }
    
    // Initial connection
    connectSocket();
    
    // More frequent connection check to keep socket alive (every 15 seconds)
    Timer.periodic(Duration(seconds: 15), (timer) {
      if (!isConnected) {
        developer.log('Socket not connected in periodic check, reconnecting...', name: 'BackgroundService');
        connectSocket();
      } else if (socket != null) {
        // Send ping to keep connection alive
        try {
          socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          developer.log('Sent keep-alive ping from background service', name: 'BackgroundService');
        } catch (e) {
          developer.log('Error sending ping: $e', name: 'BackgroundService');
          connectSocket(); // Reconnect on error
        }
      }
    });
    
    // Standard periodic check (every 30 seconds)
    Timer.periodic(Duration(seconds: 30), (timer) {
      if (!isConnected) {
        developer.log('Socket not connected in 30s periodic check, reconnecting...', name: 'BackgroundService');
        connectSocket();
      } else {
        // Send ping to verify connection
        try {
          socket?.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
        } catch (e) {
          developer.log('Error sending ping: $e', name: 'BackgroundService');
          isConnected = false;
          connectSocket();
        }
      }
    });
    
    // Listen for commands from the app
    service.on('stopService').listen((event) {
      service.stopSelf();
    });
  }
  
  static Future<void> showBackgroundNotification(Report report) async {
    final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
    
    // Define Android notification details - with vibration disabled
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'petugas_pintar_background',
      'Petugas Pintar Background',
      channelDescription: 'Notifikasi laporan baru dari background service',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      enableVibration: false, // Disable vibration as requested
      playSound: true,
      icon: '@mipmap/launcher_icon', // Use app icon instead of default
      autoCancel: true, // Allow user to dismiss
    );
    
    // Define iOS notification details
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    // Create notification details
    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Show notification with null-safe access
    String reportType = report.jenisLaporan?.toUpperCase() ?? "LAPORAN";
    String address = report.address;
    
    await notifications.show(
      report.id,
      'Laporan Baru Diterima',
      '$reportType - $address',
      notificationDetails,
      payload: report.id.toString(),
    );
    
    developer.log('Background notification displayed for ID: ${report.id}', name: 'BackgroundService');
  }
  
  static Future<void> startService() async {
    await initializeService();
    await _service.startService();
    developer.log('Background service started', name: 'BackgroundService');
  }

  static void stopService() {
    _service.invoke('stopService');
    developer.log('Background service stopped', name: 'BackgroundService');
  }
  
  static Future<bool> isRunning() async {
    return await _service.isRunning();
  }
}
