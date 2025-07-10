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
    Color color;
    
    if (!hasNotificationPermission) {
      title = 'Notifikasi Nonaktif';
      subtitle = 'Aktifkan untuk mendapat laporan real-time';
      icon = Icons.notifications_off_rounded;
      color = const Color(0xFFF59E0B);
    } else if (!_hasBatteryOptimization && widget.showBatteryOptimization) {
      title = 'Optimasi Baterai Aktif';
      subtitle = 'Nonaktifkan untuk performa background yang lebih baik';
      icon = Icons.battery_alert_rounded;
      color = const Color(0xFFEF4444);
    } else {
      return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.08),
            color.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap ?? () => _handleTap(context, hasNotificationPermission),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: color,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: color.withOpacity(0.8),
                              height: 1.3,
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
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: color.withOpacity(0.7),
                      ),
                  ],
                ),
                if (!hasNotificationPermission) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleTap(context, hasNotificationPermission),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text(
                        'Aktifkan Notifikasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
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
          content: Row(
            children: [
              Icon(
                hasPermission ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                hasPermission 
                    ? 'Notifikasi berhasil diaktifkan!'
                    : 'Gagal mengaktifkan notifikasi',
              ),
            ],
          ),
          backgroundColor: hasPermission ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            content: Row(
              children: [
                Icon(
                  status.isGranted ? Icons.check_circle_outline : Icons.info_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  status.isGranted 
                      ? 'Optimasi baterai dinonaktifkan!'
                      : 'Pengaturan bisa diubah nanti',
                ),
              ],
            ),
            backgroundColor: status.isGranted ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Error saat mengatur optimasi baterai'),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }
}
