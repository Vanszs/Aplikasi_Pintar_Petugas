import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/notification_status_widget.dart';
import '../widgets/enhanced_notification_status_widget.dart';
import '../widgets/notification_permission_handler.dart';
import '../services/notification_service.dart';
import '../services/permission_manager_service.dart';
import '../models/report.dart';

/// Complete example showing how to integrate all notification features
class ComprehensiveNotificationExample extends ConsumerStatefulWidget {
  const ComprehensiveNotificationExample({super.key});

  @override
  ConsumerState<ComprehensiveNotificationExample> createState() => _ComprehensiveNotificationExampleState();
}

class _ComprehensiveNotificationExampleState extends ConsumerState<ComprehensiveNotificationExample> {
  final PermissionManagerService _permissionManager = PermissionManagerService();
  bool _isLoading = false;
  PermissionResult? _lastPermissionResult;

  @override
  Widget build(BuildContext context) {
    final hasNotificationPermission = ref.watch(notificationPermissionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Setup'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              hasNotificationPermission ? Icons.notifications_active : Icons.notifications_off,
              color: hasNotificationPermission ? Colors.white : Colors.orange,
            ),
            onPressed: _showPermissionStatus,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enhanced notification status widget
          const EnhancedNotificationStatusWidget(
            showAsCard: true,
            showBatteryOptimization: true,
          ),
          
          const SizedBox(height: 16),
          
          // Original notification status widget
          const NotificationStatusWidget(showAsCard: true),
          
          const SizedBox(height: 24),
          
          // Permission management section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manajemen Izin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Permission status display
                  if (_lastPermissionResult != null) ...[
                    _buildPermissionStatusCard(_lastPermissionResult!),
                    const SizedBox(height: 16),
                  ],
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _checkAllPermissions,
                          icon: _isLoading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh),
                          label: const Text('Cek Status'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _requestAllPermissions,
                          icon: const Icon(Icons.security),
                          label: const Text('Minta Izin'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Settings button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openAppSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('Buka Pengaturan Aplikasi'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Test notification section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tes Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tes apakah notifikasi berfungsi dengan benar.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasNotificationPermission ? _sendTestNotification : null,
                      icon: const Icon(Icons.send),
                      label: const Text('Kirim Notifikasi Tes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Information section
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '• Notifikasi diperlukan untuk menerima laporan baru secara real-time\n'
                    '• Optimasi baterai sebaiknya dinonaktifkan untuk performa background yang optimal\n'
                    '• Aplikasi dapat tetap menerima notifikasi meskipun ditutup\n'
                    '• Semua notifikasi menggunakan logo aplikasi Petugas Pintar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionStatusCard(PermissionResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.hasOptimalConfiguration 
            ? const Color.fromRGBO(76, 175, 80, 0.1)
            : result.isGranted 
                ? const Color.fromRGBO(255, 152, 0, 0.1)
                : const Color.fromRGBO(244, 67, 54, 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.hasOptimalConfiguration 
              ? const Color.fromRGBO(76, 175, 80, 0.3)
              : result.isGranted 
                  ? const Color.fromRGBO(255, 152, 0, 0.3)
                  : const Color.fromRGBO(244, 67, 54, 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result.hasOptimalConfiguration 
                    ? Icons.check_circle
                    : result.isGranted 
                        ? Icons.warning
                        : Icons.error,
                color: result.hasOptimalConfiguration 
                    ? Colors.green
                    : result.isGranted 
                        ? Colors.orange
                        : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.summaryDescription,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi: ${result.isGranted ? "✅" : "❌"} | '
            'Optimasi Baterai: ${result.hasBatteryOptimization ? "✅" : "❌"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Future<void> _checkAllPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _permissionManager.requestAllCriticalPermissions();
      setState(() {
        _lastPermissionResult = result;
      });
      
      // Update notification permission provider
      ref.read(notificationPermissionProvider.notifier).state = result.isGranted;
      
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _requestAllPermissions() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await _permissionManager.requestAllCriticalPermissions();
      setState(() {
        _lastPermissionResult = result;
      });
      
      // Update notification permission provider
      ref.read(notificationPermissionProvider.notifier).state = result.isGranted;
      
      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.summaryDescription),
            backgroundColor: result.hasOptimalConfiguration 
                ? Colors.green
                : result.isGranted 
                    ? Colors.orange
                    : Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _openAppSettings() async {
    await _permissionManager.openAppSettings();
  }
  
  Future<void> _sendTestNotification() async {
    final notificationService = ref.read(notificationServiceProvider);
    
    // Create a dummy report for testing
    final testReport = Report(
      id: 999999,
      userId: 1,
      address: 'Alamat Tes Notifikasi - Jl. Contoh No. 123',
      createdAt: DateTime.now(),
      userName: 'User Test',
      jenisLaporan: 'TES',
    );
    
    await notificationService.showNewReportNotification(testReport);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifikasi tes telah dikirim! 📱'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  void _showPermissionStatus() {
    final hasPermission = ref.read(notificationPermissionProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status Notifikasi'),
        content: Text(
          hasPermission 
              ? 'Notifikasi sudah diaktifkan ✅\n\nAnda akan menerima pemberitahuan untuk laporan baru secara real-time.'
              : 'Notifikasi belum diaktifkan ❌\n\nAktifkan notifikasi untuk mendapatkan laporan baru secara real-time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
