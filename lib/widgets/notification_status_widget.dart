import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import 'notification_permission_handler.dart';

class NotificationStatusWidget extends ConsumerWidget {
  final bool showAsCard;
  final VoidCallback? onTap;
  
  const NotificationStatusWidget({
    super.key,
    this.showAsCard = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPermission = ref.watch(notificationPermissionProvider);
    
    if (hasPermission) {
      // Don't show anything if notifications are enabled
      return const SizedBox.shrink();
    }
    
    if (showAsCard) {
      return Card(
        margin: const EdgeInsets.all(16),
        child: _buildContent(context, ref),
      );
    }
    
    return _buildContent(context, ref);
  }
  
  Widget _buildContent(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: onTap ?? () => _requestPermission(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.notifications_off,
                color: Colors.orange[700],
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
                    'Notifikasi Nonaktif',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aktifkan untuk mendapat laporan real-time',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.orange[600],
            ),
          ],
        ),
      ),
    );
  }
  
  void _requestPermission(BuildContext context, WidgetRef ref) async {
    final notificationService = ref.read(notificationServiceProvider);
    final hasPermission = await notificationService.requestNotificationPermissions();
    
    ref.read(notificationPermissionProvider.notifier).state = hasPermission;
    
    if (context.mounted) {
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
}
