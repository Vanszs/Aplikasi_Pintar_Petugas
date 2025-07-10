import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';
import 'notification_permission_handler.dart';

/// Enhanced notification status widget with comprehensive permission handling
class EnhancedNotificationStatusWidget extends ConsumerStatefulWidget {
  final bool showAsCard;
  final VoidCallback? onTap;
  final bool showBatteryOptimization;
  
  const EnhancedNotificationStatusWidget({
    super.key,
    this.showAsCard = false,
    this.onTap,
    this.showBatteryOptimization = true,
  });

  @override
  ConsumerState<EnhancedNotificationStatusWidget> createState() => _EnhancedNotificationStatusWidgetState();
}

class _EnhancedNotificationStatusWidgetState extends ConsumerState<EnhancedNotificationStatusWidget> {
  bool _hasBatteryOptimization = false;
  bool _isChecking = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }
  
  Future<void> _checkPermissions() async {
    if (!mounted) return;
    
    setState(() {
      _isChecking = true;
    });
    
    try {
      final batteryStatus = await Permission.ignoreBatteryOptimizations.isGranted;
      
      if (mounted) {
        setState(() {
          _hasBatteryOptimization = batteryStatus;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotificationPermission = ref.watch(notificationPermissionProvider);
    
    // If all permissions are granted, don't show anything
    if (hasNotificationPermission && (_hasBatteryOptimization || !widget.showBatteryOptimization)) {
      return const SizedBox.shrink();
    }
    
    if (widget.showAsCard) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: _buildContent(context, hasNotificationPermission),
      );
    }
    
    return _buildContent(context, hasNotificationPermission);
  }
  
  Widget _buildContent(BuildContext context, bool hasNotificationPermission) {
    String title;
    String subtitle;
    IconData icon;
    MaterialColor color;
    
    if (!hasNotificationPermission) {
      title = 'Notifikasi Nonaktif';
      subtitle = 'Aktifkan untuk mendapat laporan real-time';
      icon = Icons.notifications_off;
      color = Colors.orange;
    } else if (!_hasBatteryOptimization && widget.showBatteryOptimization) {
      title = 'Optimasi Baterai Aktif';
      subtitle = 'Nonaktifkan untuk performa background yang lebih baik';
      icon = Icons.battery_alert;
      color = Colors.amber;
    } else {
      return const SizedBox.shrink();
    }
    
    return InkWell(
      onTap: widget.onTap ?? () => _handleTap(context, hasNotificationPermission),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color[700],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: color[600],
                    ),
                  ),
                ],
              ),
            ),
            if (_isChecking)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: color[600],
              ),
          ],
        ),
      ),
    );
  }
  
  void _handleTap(BuildContext context, bool hasNotificationPermission) async {
    if (!hasNotificationPermission) {
      // Request notification permission
      await _requestNotificationPermission(context);
    } else if (!_hasBatteryOptimization && widget.showBatteryOptimization) {
      // Request battery optimization whitelist
      await _requestBatteryOptimization(context);
    }
  }
  
  Future<void> _requestNotificationPermission(BuildContext context) async {
    final notificationService = ref.read(notificationServiceProvider);
    final hasPermission = await notificationService.requestNotificationPermissions();
    
    ref.read(notificationPermissionProvider.notifier).state = hasPermission;
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasPermission 
                ? 'Notifikasi telah diaktifkan! 🎉'
                : 'Gagal mengaktifkan notifikasi. Coba lagi nanti.',
          ),
          backgroundColor: hasPermission ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  Future<void> _requestBatteryOptimization(BuildContext context) async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      
      if (mounted) {
        setState(() {
          _hasBatteryOptimization = status.isGranted;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.isGranted 
                  ? 'Optimasi baterai dinonaktifkan! ✅'
                  : 'Optimasi baterai masih aktif. Anda dapat mengaturnya nanti.',
            ),
            backgroundColor: status.isGranted ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saat mengatur optimasi baterai'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
