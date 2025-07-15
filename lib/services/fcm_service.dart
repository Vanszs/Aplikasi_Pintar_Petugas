import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service_fixed.dart';
import '../models/report.dart';

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
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  String? _fcmToken;
  Function(String)? _onTokenRefresh;
  bool _notificationsEnabled = true;
  
  // Enhanced deduplication tracking
  final Map<String, DateTime> _recentFcmNotifications = {};
  
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
    
    // Clean old entries (reduce window to 1 second for better responsiveness)
    final deduplicationWindow = const Duration(seconds: 1);
    _recentFcmNotifications.removeWhere((key, time) => 
      now.difference(time) > deduplicationWindow);
    
    // Check for recent duplicates
    if (_recentFcmNotifications.containsKey(messageKey)) {
      final lastProcessed = _recentFcmNotifications[messageKey]!;
      final timeSinceLastProcessed = now.difference(lastProcessed);
      
      if (timeSinceLastProcessed.inMilliseconds < 500) { // Reduce to 500ms
        developer.log('Blocking recent duplicate message: $messageKey (${timeSinceLastProcessed.inMilliseconds}ms ago)', name: 'FCMService');
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
      
      // Initialize notification service first
      developer.log('Initializing notification service...', name: 'FCMService');
      // The notification service initializes automatically via constructor
      
      // Request permission for notifications
      developer.log('Requesting FCM permissions...', name: 'FCMService');
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
      developer.log('FCM Alert Setting: ${settings.alert}', name: 'FCMService');
      developer.log('FCM Sound Setting: ${settings.sound}', name: 'FCMService');
      developer.log('FCM Badge Setting: ${settings.badge}', name: 'FCMService');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        developer.log('FCM: User granted permission', name: 'FCMService');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        developer.log('FCM: User granted provisional permission', name: 'FCMService');
      } else {
        developer.log('FCM: User declined or has not accepted permission', name: 'FCMService');
        // Still continue to get token in case permissions change later
      }

      // Set FCM presentation options for foreground notifications
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      developer.log('FCM foreground presentation options set', name: 'FCMService');


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
      developer.log('FCM foreground message listener set up', name: 'FCMService');

      // Handle message opened app
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      developer.log('FCM message opened app listener set up', name: 'FCMService');

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
    
    // Show custom notification with custom sound (foreground only)
    await _showCustomNotificationForForegroundMessage(message);
    
    // Process additional actions (like updating app state, triggering UI updates, etc.)
    _processMessageData(message);
    
    // Notify listeners for UI updates
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

  // Show custom notification for foreground messages with custom sound
  Future<void> _showCustomNotificationForForegroundMessage(RemoteMessage message) async {
    try {
      final data = message.data;
      
      // Only show custom notification for 'new_report' type messages
      if (data['type'] == 'new_report') {
        // Create a Report object from the message data
        final report = Report(
          id: int.tryParse(data['reportId'] ?? '0') ?? 0,
          userId: int.tryParse(data['userId'] ?? '0') ?? 0,
          address: data['address'] ?? '',
          phone: data['userPhone'] ?? '',
          userName: data['userName'] ?? 'Unknown',
          jenisLaporan: data['jenisLaporan'] ?? 'Laporan',
          status: data['status'] ?? 'pending',
          createdAt: DateTime.now(),
        );
        
        // Show custom notification with sound
        await _notificationService.showNewReportNotification(report);
        developer.log('Custom notification shown for new report', name: 'FCMService');
      } else {
        // For other types, show notification using default FCM (fallback)
        developer.log('Showing default notification for message type: ${data['type']}', name: 'FCMService');
        
        // Show notification manually since we're in foreground
        await _showFallbackNotification(message);
      }
    } catch (e) {
      developer.log('Error showing custom notification: $e', name: 'FCMService');
      
      // Fallback: show simple notification
      try {
        await _showFallbackNotification(message);
      } catch (fallbackError) {
        developer.log('Error showing fallback notification: $fallbackError', name: 'FCMService');
      }
    }
  }

  // Fallback notification method
  Future<void> _showFallbackNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? 'Notifikasi';
      final body = message.notification?.body ?? 'Ada pesan baru';
      
      await _notificationService.showSimpleNotification(
        title: title,
        body: body,
        payload: message.data.toString(),
      );
    } catch (e) {
      developer.log('Error in fallback notification: $e', name: 'FCMService');
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

  // Test method to send a sample notification
  Future<void> testNotification() async {
    try {
      await _notificationService.showSimpleNotification(
        title: 'Test FCM Notification',
        body: 'Ini adalah test notifikasi untuk memastikan sistem berfungsi',
        payload: 'test_notification',
      );
      developer.log('Test notification sent successfully', name: 'FCMService');
    } catch (e) {
      developer.log('Error sending test notification: $e', name: 'FCMService');
    }
  }
}

// Provider for FCM Service
final fcmServiceProvider = ChangeNotifierProvider<FCMService>((ref) {
  return FCMService();
});
