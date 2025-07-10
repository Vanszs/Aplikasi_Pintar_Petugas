import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  
  developer.log('Handling a background message: ${message.messageId}', name: 'FCMService');
  
  // You can access message data here
  if (message.data.isNotEmpty) {
    developer.log('Background message data: ${message.data}', name: 'FCMService');
  }
  
  // Handle the message here
  await FCMService._handleBackgroundMessage(message);
}

class FCMService extends ChangeNotifier {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  String? _fcmToken;
  Function(String)? _onTokenRefresh;
  bool _notificationsEnabled = true;
  
  // Enhanced deduplication tracking
  final Map<String, DateTime> _recentFcmNotifications = {};
  static const Duration _fcmDeduplicationWindow = Duration(seconds: 2);
  
  // Session tracking
  String? _currentSessionId;
  
  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  // Method to enable/disable notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    if (!enabled) {
      _recentFcmNotifications.clear();
    }
    developer.log('FCM notifications ${enabled ? 'enabled' : 'disabled'}', name: 'FCMService');
    notifyListeners();
  }

  // Check if FCM notification should be processed (simplified)
  bool _shouldProcessFcmMessage(String messageKey, Map<String, dynamic> messageData) {
    if (!_notificationsEnabled) {
      developer.log('FCM notifications disabled, skipping: $messageKey', name: 'FCMService');
      return false;
    }

    final now = DateTime.now();
    
    // Clean old entries
    _recentFcmNotifications.removeWhere((key, time) => 
      now.difference(time) > _fcmDeduplicationWindow);
    
    // Check for recent duplicates
    if (_recentFcmNotifications.containsKey(messageKey)) {
      final lastProcessed = _recentFcmNotifications[messageKey]!;
      final timeSinceLastProcessed = now.difference(lastProcessed);
      developer.log('Duplicate FCM message detected: $messageKey (last processed ${timeSinceLastProcessed.inSeconds}s ago)', name: 'FCMService');
      
      if (timeSinceLastProcessed.inSeconds < 2) {
        developer.log('Blocking duplicate message: $messageKey', name: 'FCMService');
        return false;
      }
    }
    
    // Mark as processed
    _recentFcmNotifications[messageKey] = now;
    developer.log('FCM message approved for processing: $messageKey', name: 'FCMService');
    return true;
  }

  // Method to set token refresh callback
  void setTokenRefreshCallback(Function(String)? callback) {
    _onTokenRefresh = callback;
  }

  static Future<void> initialize() async {
    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Set the background messaging handler early on, as a named top-level function
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      developer.log('Firebase initialized successfully', name: 'FCMService');
    } catch (e) {
      developer.log('Error initializing Firebase: $e', name: 'FCMService');
    }
  }

  Future<void> initializeFCM() async {
    try {
      developer.log('=== INITIALIZING FCM SERVICE ===', name: 'FCMService');
      
      // Request permission for notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('FCM Permission Status: ${settings.authorizationStatus}', name: 'FCMService');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('FCM: User granted permission', name: 'FCMService');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        developer.log('FCM: User granted provisional permission', name: 'FCMService');
      } else {
        developer.log('FCM: User declined or has not accepted permission', name: 'FCMService');
        return;
      }

      // Set FCM presentation options for foreground notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Initialize backup local notifications for foreground messages
      await _initializeBackupNotifications();

      // Get the token
      _fcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM Token: $_fcmToken', name: 'FCMService');
      
      // Generate new session
      _generateNewSession();
      
      // Save token to SharedPreferences
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        developer.log('FCM Token refreshed: $fcmToken', name: 'FCMService');
        _fcmToken = fcmToken;
        _saveTokenToPreferences(fcmToken);
        notifyListeners();
        
        // Notify listeners about token change
        _onTokenRefresh?.call(fcmToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for any messages received while app was terminated
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        developer.log('Initial message found: ${initialMessage.messageId}', name: 'FCMService');
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      notifyListeners();
      
      developer.log('=== FCM SERVICE INITIALIZED SUCCESSFULLY ===', name: 'FCMService');
    } catch (e) {
      developer.log('Error initializing FCM: $e', name: 'FCMService');
    }
  }

  Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // Handle FCM foreground messages - Ensure notifications show when app is open
  void _handleForegroundMessage(RemoteMessage message) async {
    developer.log('=== FCM FOREGROUND MESSAGE RECEIVED ===', name: 'FCMService');
    developer.log('Message ID: ${message.messageId}', name: 'FCMService');
    developer.log('Message data: ${message.data}', name: 'FCMService');
    developer.log('Notifications enabled: $_notificationsEnabled', name: 'FCMService');

    // Create message key for deduplication
    String messageKey = 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}';
    
    // Use data to create more specific key if available
    if (message.data['type'] == 'new_report' && message.data['reportId'] != null) {
      messageKey = 'fcm_new_report_${message.data['reportId']}';
    } else if (message.data['type'] == 'status_update' && message.data['reportId'] != null) {
      messageKey = 'fcm_status_update_${message.data['reportId']}_${message.data['status'] ?? 'unknown'}';
    }

    // Check if we should process this message
    if (!_shouldProcessFcmMessage(messageKey, message.data)) {
      developer.log('FCM message processing skipped due to deduplication', name: 'FCMService');
      return;
    }

    // Log notification details
    if (message.notification != null) {
      developer.log('Message notification title: ${message.notification?.title}', name: 'FCMService');
      developer.log('Message notification body: ${message.notification?.body}', name: 'FCMService');
    } else {
      developer.log('No notification payload in message', name: 'FCMService');
    }
    
    // Show backup notification for foreground messages to ensure they appear
    // This ensures notifications show even if FCM foreground presentation fails
    await _showBackupNotification(message);
    
    // Process additional actions (like updating app state, triggering UI updates, etc.)
    _processMessageData(message);
    
    // For foreground messages, the system should automatically show the notification
    // due to setForegroundNotificationPresentationOptions, but let's also notify listeners
    notifyListeners();
    
    developer.log('=== END FCM FOREGROUND MESSAGE ===', name: 'FCMService');
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log('FCM message opened app!', name: 'FCMService');
    developer.log('Message data: ${message.data}', name: 'FCMService');
    
    // Handle navigation here based on message data
    _handleNotificationNavigation(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    developer.log('Handling background message: ${message.messageId}', name: 'FCMService');
    developer.log('Background message data: ${message.data}', name: 'FCMService');
    
    // FCM automatically shows notification in background
    // You can process additional data here if needed
  }

  // Initialize backup local notifications for foreground messages only
  Future<void> _initializeBackupNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(initializationSettings);

      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'fcm_foreground_channel',
        'FCM Foreground Notifications',
        description: 'Backup notifications for when app is open',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
          
      developer.log('Backup local notifications initialized', name: 'FCMService');
    } catch (e) {
      developer.log('Error initializing backup notifications: $e', name: 'FCMService');
    }
  }

  // Show backup local notification for foreground messages
  Future<void> _showBackupNotification(RemoteMessage message) async {
    if (!_notificationsEnabled || kIsWeb) return;
    
    try {
      final notification = message.notification;
      final data = message.data;
      
      String title = notification?.title ?? 'Laporan Baru';
      String body = notification?.body ?? 'Ada laporan baru untuk ditangani';
      
      // Create notification based on data if no notification payload
      if (notification == null && data.isNotEmpty) {
        if (data['type'] == 'new_report') {
          title = 'Laporan Baru';
          body = 'Ada laporan ${data['jenis_laporan'] ?? 'baru'} yang perlu ditangani';
        } else if (data['type'] == 'status_update') {
          title = 'Update Status Laporan';
          body = 'Status laporan telah diperbarui';
        }
      }

      await _localNotifications.show(
        message.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_foreground_channel',
            'FCM Foreground Notifications',
            channelDescription: 'Backup notifications for when app is open',
            icon: '@mipmap/launcher_icon',
            importance: Importance.high,
            priority: Priority.high,
            color: Color(0xFF4F46E5),
            enableLights: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      developer.log('Backup notification shown for foreground message', name: 'FCMService');
    } catch (e) {
      developer.log('Error showing backup notification: $e', name: 'FCMService');
    }
  }

  // Process message data for app state updates
  void _processMessageData(RemoteMessage message) {
    final data = message.data;
    
    if (data.isNotEmpty) {
      developer.log('Processing message data: $data', name: 'FCMService');
      
      // Here you can trigger app state updates based on message type
      switch (data['type']) {
        case 'new_report':
          developer.log('New report notification received: ${data['reportId']}', name: 'FCMService');
          // You can emit events here to update UI
          break;
        case 'status_update':
          developer.log('Status update notification received: ${data['reportId']}', name: 'FCMService');
          // You can emit events here to update UI
          break;
        default:
          developer.log('Unknown notification type: ${data['type']}', name: 'FCMService');
      }
    }
  }

  void _handleNotificationNavigation(RemoteMessage message) {
    // Handle navigation based on notification data
    final data = message.data;
    
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'new_report':
          developer.log('Navigate to new report: ${data['report_id']}', name: 'FCMService');
          // Add navigation logic here
          break;
        case 'status_update':
          developer.log('Navigate to status update: ${data['report_id']}', name: 'FCMService');
          // Add navigation logic here
          break;
        default:
          developer.log('Unknown notification type: ${data['type']}', name: 'FCMService');
      }
    }
  }

  // Method to subscribe to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'FCMService');
    } catch (e) {
      developer.log('Error subscribing to topic $topic: $e', name: 'FCMService');
    }
  }

  // Method to unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'FCMService');
    } catch (e) {
      developer.log('Error unsubscribing from topic $topic: $e', name: 'FCMService');
    }
  }

  // Method to get saved FCM token from SharedPreferences
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }

  // Method to send token to your server
  Future<void> sendTokenToServer(String? userId, {Function(String)? onTokenUpdate}) async {
    if (_fcmToken == null) return;
    
    try {
      developer.log('Sending FCM token to server: $_fcmToken for user: $userId', name: 'FCMService');
      
      // Call the callback function if provided (this will call auth provider)
      if (onTokenUpdate != null) {
        onTokenUpdate(_fcmToken!);
      }
    } catch (e) {
      developer.log('Error sending token to server: $e', name: 'FCMService');
    }
  }

  // Method to register token immediately if user is authenticated
  Future<void> registerTokenIfAuthenticated({Function(String)? onTokenUpdate}) async {
    if (_fcmToken != null && onTokenUpdate != null) {
      try {
        onTokenUpdate(_fcmToken!);
      } catch (e) {
        developer.log('Error in registerTokenIfAuthenticated: $e', name: 'FCMService');
      }
    }
  }

  // Method to generate new session when FCM token is registered
  void _generateNewSession() {
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
    developer.log('Generated new FCM session: $_currentSessionId', name: 'FCMService');
  }
}

// Provider for FCM Service
final fcmServiceProvider = ChangeNotifierProvider<FCMService>((ref) {
  return FCMService();
});
