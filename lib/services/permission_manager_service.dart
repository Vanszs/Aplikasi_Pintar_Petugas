import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

/// Comprehensive permission manager for all app permissions
class PermissionManagerService {
  static final PermissionManagerService _instance = PermissionManagerService._internal();
  factory PermissionManagerService() => _instance;
  PermissionManagerService._internal();

  /// Check if all critical permissions are granted
  Future<bool> hasAllCriticalPermissions() async {
    try {
      final notification = await Permission.notification.isGranted;
      // Battery optimization is recommended but not critical
      developer.log('Critical permissions - Notification: $notification', name: 'PermissionManager');
      return notification;
    } catch (e) {
      developer.log('Error checking critical permissions: $e', name: 'PermissionManager');
      return false;
    }
  }

  /// Request all critical permissions needed for the app
  Future<PermissionResult> requestAllCriticalPermissions() async {
    final results = <Permission, PermissionStatus>{};
    
    try {
      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      results[Permission.notification] = notificationStatus;
      
      // Request battery optimization (optional but recommended)
      try {
        final batteryStatus = await Permission.ignoreBatteryOptimizations.request();
        results[Permission.ignoreBatteryOptimizations] = batteryStatus;
      } catch (e) {
        developer.log('Battery optimization permission not available: $e', name: 'PermissionManager');
      }
      
      // Request system alert window for critical notifications (optional)
      try {
        final systemAlertStatus = await Permission.systemAlertWindow.request();
        results[Permission.systemAlertWindow] = systemAlertStatus;
      } catch (e) {
        developer.log('System alert window permission not available: $e', name: 'PermissionManager');
      }
      
      developer.log('Permission results: $results', name: 'PermissionManager');
      
      return PermissionResult(
        isGranted: notificationStatus.isGranted,
        results: results,
        hasBatteryOptimization: results[Permission.ignoreBatteryOptimizations]?.isGranted ?? false,
        hasSystemAlert: results[Permission.systemAlertWindow]?.isGranted ?? false,
      );
    } catch (e) {
      developer.log('Error requesting permissions: $e', name: 'PermissionManager');
      return PermissionResult(
        isGranted: false,
        results: results,
        hasBatteryOptimization: false,
        hasSystemAlert: false,
        error: e.toString(),
      );
    }
  }

  /// Check specific permission status
  Future<PermissionStatus> checkPermission(Permission permission) async {
    try {
      return await permission.status;
    } catch (e) {
      developer.log('Error checking permission $permission: $e', name: 'PermissionManager');
      return PermissionStatus.denied;
    }
  }

  /// Request specific permission
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      return await permission.request();
    } catch (e) {
      developer.log('Error requesting permission $permission: $e', name: 'PermissionManager');
      return PermissionStatus.denied;
    }
  }

  /// Open app settings for manual permission configuration
  Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      developer.log('Error opening app settings: $e', name: 'PermissionManager');
      return false;
    }
  }

  /// Show dialog explaining why permissions are needed
  static Future<void> showPermissionEducationDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onAccept,
    VoidCallback? onDecline,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.security,
                color: Color(0xFF4F46E5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          if (onDecline != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDecline();
              },
              child: const Text(
                'Nanti',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onAccept();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );
  }

  /// Get user-friendly permission status description
  static String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Diizinkan';
      case PermissionStatus.denied:
        return 'Ditolak';
      case PermissionStatus.restricted:
        return 'Dibatasi';
      case PermissionStatus.limited:
        return 'Terbatas';
      case PermissionStatus.permanentlyDenied:
        return 'Ditolak Permanen';
      case PermissionStatus.provisional:
        return 'Sementara';
    }
  }
}

/// Result class for permission requests
class PermissionResult {
  final bool isGranted;
  final Map<Permission, PermissionStatus> results;
  final bool hasBatteryOptimization;
  final bool hasSystemAlert;
  final String? error;

  const PermissionResult({
    required this.isGranted,
    required this.results,
    required this.hasBatteryOptimization,
    required this.hasSystemAlert,
    this.error,
  });

  /// Get all granted permissions
  List<Permission> get grantedPermissions {
    return results.entries
        .where((entry) => entry.value.isGranted)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get all denied permissions
  List<Permission> get deniedPermissions {
    return results.entries
        .where((entry) => entry.value.isDenied || entry.value.isPermanentlyDenied)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if has optimal configuration for background operation
  bool get hasOptimalConfiguration {
    return isGranted && hasBatteryOptimization;
  }

  /// Get summary description
  String get summaryDescription {
    if (error != null) return 'Error: $error';
    if (hasOptimalConfiguration) return 'Konfigurasi Optimal ✅';
    if (isGranted) return 'Dasar Diizinkan ⚠️';
    return 'Perlu Izin ❌';
  }
}
