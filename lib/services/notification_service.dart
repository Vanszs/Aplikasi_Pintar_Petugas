import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../models/report.dart';

/// NotificationService - Simplified to only use FCM
/// Local notifications removed to prevent conflicts and crashes
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isEnabled = true;
  bool get isEnabled => _isEnabled;
  
  // Keep track of shown notifications for deduplication (FCM only)
  final Map<String, DateTime> _shownNotifications = {};
  static const Duration _deduplicationWindow = Duration(seconds: 5);

  Future<void> initialize() async {
    developer.log('NotificationService initialized (FCM only mode)', name: 'NotificationService');
  }

  Future<void> requestPermissions() async {
    try {
      final status = await Permission.notification.request();
      _isEnabled = status.isGranted;
      developer.log('Notification permission: ${status.name}', name: 'NotificationService');
      notifyListeners();
    } catch (e) {
      developer.log('Error requesting notification permission: $e', name: 'NotificationService');
      _isEnabled = false;
    }
  }

  /// Alias for requestPermissions() - for compatibility
  Future<bool> requestNotificationPermissions() async {
    await requestPermissions();
    return _isEnabled;
  }

  /// Check notification permissions status
  Future<bool> checkNotificationPermissions() async {
    try {
      final status = await Permission.notification.status;
      _isEnabled = status.isGranted;
      notifyListeners();
      return status.isGranted;
    } catch (e) {
      developer.log('Error checking notification permission: $e', name: 'NotificationService');
      return false;
    }
  }

  void enableNotifications() {
    _isEnabled = true;
    developer.log('Notifications enabled', name: 'NotificationService');
    notifyListeners();
  }

  void disableNotifications() {
    _isEnabled = false;
    _shownNotifications.clear();
    developer.log('Notifications disabled and cache cleared', name: 'NotificationService');
    notifyListeners();
  }

  /// Check if notification should be shown (deduplication)
  bool _shouldShowNotification(String notificationKey) {
    if (!_isEnabled) {
      developer.log('Notifications disabled, skipping: $notificationKey', name: 'NotificationService');
      return false;
    }

    final now = DateTime.now();
    
    // Clean old entries
    _shownNotifications.removeWhere((key, time) => 
      now.difference(time) > _deduplicationWindow);
    
    // Check if this notification was recently shown
    if (_shownNotifications.containsKey(notificationKey)) {
      developer.log('Duplicate notification blocked: $notificationKey', name: 'NotificationService');
      return false;
    }
    
    // Mark as shown
    _shownNotifications[notificationKey] = now;
    return true;
  }

  /// Show new report notification (FCM only - no local notification)
  Future<void> showNewReportNotification(Report report) async {
    final notificationKey = 'new_report_${report.id}_${report.createdAt.millisecondsSinceEpoch}';
    
    if (!_shouldShowNotification(notificationKey)) {
      return;
    }

    developer.log(
      'New report logged: ID=${report.id}, From=${report.userName}, Type=${report.jenisLaporan}',
      name: 'NotificationService'
    );
    
    // Only log - FCM will handle the actual notification display
    notifyListeners();
  }

  /// Show status update notification (FCM only - no local notification)
  Future<void> showStatusUpdateNotification(String title, String body, {String? reportId}) async {
    final notificationKey = 'status_${reportId ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}';
    
    if (!_shouldShowNotification(notificationKey)) {
      return;
    }

    developer.log(
      'Status update logged: $title - $body',
      name: 'NotificationService'
    );
    
    // Only log - FCM will handle the actual notification display
    notifyListeners();
  }

  /// Clear notification cache (useful on logout)
  void clearNotificationCache() {
    _shownNotifications.clear();
    developer.log('Notification cache cleared', name: 'NotificationService');
  }

  /// Get notification statistics
  Map<String, dynamic> getStats() {
    return {
      'enabled': _isEnabled,
      'recent_notifications': _shownNotifications.length,
      'cache_window_seconds': _deduplicationWindow.inSeconds,
    };
  }
}

// Provider for NotificationService
final notificationServiceProvider = ChangeNotifierProvider<NotificationService>((ref) {
  return NotificationService();
});
