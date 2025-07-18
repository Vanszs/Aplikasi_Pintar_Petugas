import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'auth_provider.dart';
import 'report_provider.dart';
import '../services/cache_service.dart';
import '../main.dart';
import 'dart:developer' as developer;

// Global refresh state provider untuk sinkronisasi di semua widget
final globalRefreshStateProvider = StateProvider<bool>((ref) => false);

// Provider untuk mendeteksi perubahan offline-to-online yang memerlukan sync message
final offlineToOnlineSyncProvider = StateProvider<bool>((ref) => false);

// Previous connection state untuk deteksi perubahan
final previousConnectionStateProvider = StateProvider<bool?>((ref) => null);

// Connectivity state provider
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

// Internet connection status provider - start with null to indicate unchecked state
final internetConnectionProvider = StateProvider<bool?>((ref) => null);

// Last sync timestamp provider
final lastSyncProvider = StateProvider<DateTime?>((ref) => null);

// Global refresh function provider - terpusat untuk konsistensi  
final globalRefreshProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    final refreshNotifier = ref.read(globalRefreshStateProvider.notifier);
    final offlineToOnlineNotifier = ref.read(offlineToOnlineSyncProvider.notifier);
    final previousConnectionNotifier = ref.read(previousConnectionStateProvider.notifier);
    final internetConnectionNotifier = ref.read(internetConnectionProvider.notifier);
    
    // Cegah multiple refresh operations bersamaan
    if (refreshNotifier.state) {
      return false;
    }
    
    // Get previous connection state
    final previousConnection = previousConnectionNotifier.state;
    
    // Check connectivity first menggunakan ConnectivityService yang sudah ada
    final connectivityService = ref.read(connectivityServiceProvider);
    final hasRealInternet = await connectivityService.checkInternetConnection();
    
    // Detect offline-to-online transition
    final isOfflineToOnline = (previousConnection == false || previousConnection == null) && hasRealInternet;
    
    // Set sync state only for offline-to-online transitions
    if (isOfflineToOnline) {
      offlineToOnlineNotifier.state = true;
      refreshNotifier.state = true;
      developer.log('Offline-to-online transition detected - showing sync message', name: 'GlobalRefresh');
    } else if (hasRealInternet) {
      // Online refresh without sync message
      refreshNotifier.state = false; // Don't show sync message for regular refresh
      developer.log('Regular online refresh - no sync message', name: 'GlobalRefresh');
    } else {
      refreshNotifier.state = false;
    }
    
    // Update connection states
    internetConnectionNotifier.state = hasRealInternet;
    previousConnectionNotifier.state = hasRealInternet;
    
    try {
      if (!hasRealInternet) {
        developer.log('No internet connection - loading cached data', name: 'GlobalRefresh');
        
        // Load cached data when offline
        await _loadCachedData(ref);
        return false; // Return false to indicate offline mode
      }
      
      final authNotifier = ref.read(authProvider.notifier);
      
      // Try to refresh connection/validate token
      final success = await authNotifier.refreshConnection();
      
      if (success) {
        // Update internet connection status
        internetConnectionNotifier.state = true;
        
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
        internetConnectionNotifier.state = false;
        developer.log('Auth refresh failed - loading cached data', name: 'GlobalRefresh');
        
        // Load cached data when auth fails
        await _loadCachedData(ref);
        return false;
      }
      
    } catch (e) {
      // Log error tapi jangan throw untuk mencegah UI breaking
      internetConnectionNotifier.state = false;
      developer.log('Error in global refresh - loading cached data: $e', name: 'GlobalRefresh');
      
      // Load cached data on error
      await _loadCachedData(ref);
      return false;
    } finally {
      // Selalu reset refresh state dan offline-to-online state
      refreshNotifier.state = false;
      offlineToOnlineNotifier.state = false;
    }
  };
});

// Helper function to load cached data
Future<void> _loadCachedData(Ref ref) async {
  try {
    // Load cached reports
    final cachedReports = await CacheService.loadReports();
    if (cachedReports.isNotEmpty) {
      await ref.read(reportProvider.notifier).setCachedReports(cachedReports);
      developer.log('Loaded ${cachedReports.length} cached reports', name: 'GlobalRefresh');
    }
    
    // Load cached user stats
    final cachedUserStats = await CacheService.loadUserStats();
    if (cachedUserStats != null) {
      await ref.read(reportProvider.notifier).setCachedUserStats(cachedUserStats);
      developer.log('Loaded cached user stats', name: 'GlobalRefresh');
    }
    
    // Load cached global stats
    final cachedGlobalStats = await CacheService.loadGlobalStats();
    if (cachedGlobalStats != null) {
      await ref.read(reportProvider.notifier).setCachedGlobalStats(cachedGlobalStats);
      developer.log('Loaded cached global stats', name: 'GlobalRefresh');
    }
  } catch (e) {
    developer.log('Error loading cached data: $e', name: 'GlobalRefresh');
  }
}

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
