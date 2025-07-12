import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/notification_status_widget.dart';
import '../widgets/notification_permission_handler.dart';
import '../services/notification_service.dart';

/// Example of how to integrate notification status checking in existing screens
class ExampleScreenWithNotificationStatus extends ConsumerWidget {
  const ExampleScreenWithNotificationStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotificationPermission = ref.watch(notificationPermissionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Screen'),
        actions: [
          // Optional: Show notification status in app bar
          if (!hasNotificationPermission)
            IconButton(
              icon: const Icon(Icons.notifications_off),
              onPressed: () {
                // Show bottom sheet with permission request
                _showNotificationPermissionBottomSheet(context, ref);
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Show notification status widget at the top
          const NotificationStatusWidget(),
          
          // Your existing screen content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                // Your existing widgets...
                Card(
                  child: ListTile(
                    title: Text('Sample Content'),
                    subtitle: Text('Your existing screen content goes here'),
                  ),
                ),
                
                // More content...
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showNotificationPermissionBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.notifications_active,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aktifkan Notifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Dapatkan notifikasi real-time saat ada laporan baru yang memerlukan penanganan segera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            NotificationStatusWidget(
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Provider extension to check notification status easily
extension NotificationHelpers on WidgetRef {
  bool get hasNotificationPermission => watch(notificationPermissionProvider);
  
  Future<void> requestNotificationPermission() async {
    final notificationService = read(notificationServiceProvider);
    final hasPermission = await notificationService.requestNotificationPermissions();
    read(notificationPermissionProvider.notifier).state = hasPermission;
  }
}
