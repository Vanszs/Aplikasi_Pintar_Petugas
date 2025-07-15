import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_provider.dart';
import 'report_provider.dart';

// Global refresh state provider untuk sinkronisasi di semua widget
final globalRefreshStateProvider = StateProvider<bool>((ref) => false);

// Connectivity state provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Internet connection status provider
final internetConnectionProvider = StateProvider<bool>((ref) => true);

// Last sync timestamp provider
final lastSyncProvider = StateProvider<DateTime?>((ref) => null);

// Global refresh function provider - terpusat untuk konsistensi  
final globalRefreshProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final refreshNotifier = ref.read(globalRefreshStateProvider.notifier);
    
    // Cegah multiple refresh operations bersamaan
    if (refreshNotifier.state) {
      return false;
    }
    
    refreshNotifier.state = true;
    
    try {
      // Check connectivity first menggunakan ConnectivityService yang sudah ada
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        ref.read(internetConnectionProvider.notifier).state = false;
        return false;
      }
      
      final authNotifier = ref.read(authProvider.notifier);
      
      // Try to refresh connection/validate token
      final success = await authNotifier.refreshConnection();
      
      if (success) {
        // Update internet connection status
        ref.read(internetConnectionProvider.notifier).state = true;
        
        // Update last sync timestamp
        ref.read(lastSyncProvider.notifier).state = DateTime.now();
        
        // Reload semua data secara parallel untuk performa yang lebih baik
        await Future.wait([
          ref.read(reportProvider.notifier).loadPetugasReports(),
          ref.read(reportProvider.notifier).loadPetugasStats(),
          // Tambahkan provider lain yang diperlukan untuk petugas
        ]);
        
        return true;
      } else {
        ref.read(internetConnectionProvider.notifier).state = false;
        return false;
      }
      
    } catch (e) {
      // Log error tapi jangan throw untuk mencegah UI breaking
      ref.read(internetConnectionProvider.notifier).state = false;
      return false;
    } finally {
      // Selalu reset refresh state
      refreshNotifier.state = false;
    }
  };
});

// Helper untuk check koneksi internet aktual (bukan hanya connectivity)
final internetStatusProvider = FutureProvider<bool>((ref) async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }
    
    // Optional: ping actual server to verify internet connection
    final authNotifier = ref.read(authProvider.notifier);
    return await authNotifier.checkConnection();
  } catch (e) {
    return false;
  }
});
