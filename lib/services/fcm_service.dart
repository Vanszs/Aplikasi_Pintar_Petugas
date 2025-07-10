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
  
  // Getters
  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

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

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('FCM: User granted permission', name: 'FCMService');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        developer.log('FCM: User granted provisional permission', name: 'FCMService');
      } else {
        developer.log('FCM: User declined or has not accepted permission', name: 'FCMService');
        return;
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get the token
      _fcmToken = await _firebaseMessaging.getToken();
      developer.log('FCM Token: $_fcmToken', name: 'FCMService');
      
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
        
        // Notify listeners about token change (this will be used by auth provider)
        _onTokenRefresh?.call(fcmToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle message opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check for any messages received while app was terminated
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      notifyListeners();
      
      developer.log('FCM Service initialized successfully', name: 'FCMService');
    } catch (e) {
      developer.log('Error initializing FCM: $e', name: 'FCMService');
    }
  }

  Future<void> _initializeLocalNotifications() async {
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

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fcm_default_channel', // id
      'FCM Notifications', // title
      description: 'Firebase Cloud Messaging notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    developer.log('Notification tapped: ${notificationResponse.payload}', name: 'FCMService');
    // Handle notification tap here
    // You can navigate to specific screens based on the payload
  }

  void _handleForegroundMessage(RemoteMessage message) {
    developer.log('Got a message whilst in the foreground!', name: 'FCMService');
    developer.log('Message data: ${message.data}', name: 'FCMService');

    if (message.notification != null) {
      developer.log('Message also contained a notification: ${message.notification}', name: 'FCMService');
      _showLocalNotification(message);
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    developer.log('A new onMessageOpenedApp event was published!', name: 'FCMService');
    developer.log('Message data: ${message.data}', name: 'FCMService');
    
    // Handle navigation here based on message data
    _handleNotificationNavigation(message);
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    developer.log('Handling background message: ${message.messageId}', name: 'FCMService');
    
    // You can process the message here
    // Note: You can't show UI or navigate in background handler
    // But you can show local notifications, save to database, etc.
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null && !kIsWeb) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_default_channel',
            'FCM Notifications',
            channelDescription: 'Firebase Cloud Messaging notifications',
            icon: '@mipmap/launcher_icon',
            importance: Importance.high,
            priority: Priority.high,
            color: const Color(0xFF4F46E5),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
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
}

// Provider for FCM Service
final fcmServiceProvider = ChangeNotifierProvider<FCMService>((ref) {
  return FCMService();
});
