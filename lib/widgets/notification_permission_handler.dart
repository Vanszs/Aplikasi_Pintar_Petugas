import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../services/notification_service.dart';

/// Provider for notification permission status
final notificationPermissionProvider = StateProvider<bool>((ref) => false);

/// Provider for checking if we should show permission dialog
final shouldShowPermissionDialogProvider = StateProvider<bool>((ref) => false);

/// This widget shows a permission request dialog when the app is first launched
class NotificationPermissionHandler extends ConsumerStatefulWidget {
  final Widget child;
  
  const NotificationPermissionHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  ConsumerState<NotificationPermissionHandler> createState() => _NotificationPermissionHandlerState();
}

class _NotificationPermissionHandlerState extends ConsumerState<NotificationPermissionHandler> {
  bool _isCheckingPermission = true;
  bool _hasShownDialog = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissionAndShowDialog();
  }
  
  Future<void> _checkPermissionAndShowDialog() async {
    try {
      // First check if we've already asked before
      final prefs = await SharedPreferences.getInstance();
      final hasAskedBefore = prefs.getBool('notification_permission_asked') ?? false;
      
      // Get the notification service
      final notificationService = ref.read(notificationServiceProvider);
      
      // Check current permission status
      final hasPermission = await notificationService.checkNotificationPermissions();
      
      // Update the provider with current status
      ref.read(notificationPermissionProvider.notifier).state = hasPermission;
      
      if (!hasAskedBefore && !hasPermission) {
        // If we haven't asked before and don't have permission, show the dialog after a slight delay
        // This gives the app time to fully initialize
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          _showPermissionDialog();
        });
      }
      
      setState(() {
        _isCheckingPermission = false;
      });
    } catch (e) {
      developer.log('Error checking notification permissions: $e', name: 'NotificationPermissionHandler');
      setState(() {
        _isCheckingPermission = false;
      });
    }
  }
  
  Future<void> _showPermissionDialog() async {
    if (_hasShownDialog) return;
    
    setState(() {
      _hasShownDialog = true;
    });
    
    // Record that we've shown the dialog
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_permission_asked', true);
    
    if (!mounted) return;
    
    // Show the dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildPermissionDialog(context),
    );
  }
  
  Widget _buildPermissionDialog(BuildContext context) {
    return AlertDialog(
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
              Icons.notifications_active,
              color: Color(0xFF4F46E5),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Aktifkan Notifikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 64,
                  height: 64,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Petugas Pintar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4F46E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dapatkan notifikasi real-time saat ada laporan baru dari warga yang memerlukan penanganan segera.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notifikasi membantu meningkatkan responsivitas pelayanan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Update provider to indicate user declined
            ref.read(notificationPermissionProvider.notifier).state = false;
          },
          child: const Text(
            'Nanti Saja',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            Navigator.of(context).pop();
            
            // Request notification permission
            final notificationService = ref.read(notificationServiceProvider);
            final hasPermission = await notificationService.requestNotificationPermissions();
            
            // Also request battery optimization whitelist for better background performance
            if (hasPermission) {
              await _requestBatteryOptimizationWhitelist();
            }
            
            // Update the provider
            ref.read(notificationPermissionProvider.notifier).state = hasPermission;
            
            // Show feedback to user
            if (mounted) {
              if (hasPermission) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifikasi telah diaktifkan! 🎉'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              } else {
                // Check if permission is permanently denied
                final status = await Permission.notification.status;
                if (status.isPermanentlyDenied) {
                  _showPermanentlyDeniedDialog();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifikasi belum diaktifkan. Anda dapat mengaktifkannya nanti di pengaturan.'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Izinkan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Request permission to ignore battery optimization for better background performance
  Future<void> _requestBatteryOptimizationWhitelist() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isDenied) {
        await Permission.ignoreBatteryOptimizations.request();
        developer.log('Battery optimization whitelist requested', name: 'NotificationPermissionHandler');
      }
    } catch (e) {
      developer.log('Error requesting battery optimization whitelist: $e', name: 'NotificationPermissionHandler');
    }
  }
  
  /// Open app settings if permission is permanently denied
  Future<void> _openAppSettings() async {
    try {
      await openAppSettings();
      developer.log('Opened app settings for user to enable notifications', name: 'NotificationPermissionHandler');
    } catch (e) {
      developer.log('Error opening app settings: $e', name: 'NotificationPermissionHandler');
    }
  }
  
  void _showPermanentlyDeniedDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Buka Pengaturan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Notifikasi telah dinonaktifkan secara permanen. Untuk mengaktifkannya, silakan buka pengaturan aplikasi dan aktifkan izin notifikasi.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // If still checking, show the child directly
    // This avoids showing a loading indicator which would be jarring
    if (_isCheckingPermission) {
      return widget.child;
    }
    
    // Otherwise, show the child (the dialog will appear over it if needed)
    return widget.child;
  }
}
