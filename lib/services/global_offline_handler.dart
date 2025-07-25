import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/global_refresh_provider.dart';
import '../main.dart';
import 'dart:developer' as developer;

// Provider untuk menangani global offline state
final globalOfflineHandlerProvider = ChangeNotifierProvider<GlobalOfflineHandler>((ref) {
  return GlobalOfflineHandler(ref);
});

class GlobalOfflineHandler extends ChangeNotifier with WidgetsBindingObserver {
  final Ref _ref;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  Timer? _initialCheckTimer;
  Timer? _debounceTimer; // Add debounce timer to prevent too frequent checks
  bool _hasInternetConnection = true;
  bool _isInitialized = false;
  bool _shouldShowOfflinePopup = false;
  bool _isCheckingConnection = false;
  
  // Add listener for auth state changes
  ProviderSubscription<AuthState>? _authSubscription;

  GlobalOfflineHandler(this._ref) {
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _initialize();
    _setupAuthListener();
  }

  bool get hasInternetConnection => _hasInternetConnection;
  bool get isOnline => _hasInternetConnection;
  bool get shouldShowOfflinePopup => _shouldShowOfflinePopup;
  bool get isInitialized => _isInitialized;

  void _initialize() {
    developer.log('Initializing GlobalOfflineHandler', name: 'GlobalOfflineHandler');
    
    // Setup connectivity listener immediately
    _setupConnectivityListener();
    
    // Perform initial check immediately (no delay) for better user experience
    _performInitialCheck();
    
    // Start periodic checks
    _startPeriodicInternetCheck();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      developer.log('Connectivity changed: $result', name: 'GlobalOfflineHandler');
      _handleConnectivityChange(result);
    });
  }

  Future<void> _performInitialCheck() async {
    developer.log('Performing initial connectivity check', name: 'GlobalOfflineHandler');
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final connectivityService = _ref.read(connectivityServiceProvider);
      
      bool hasRealInternet = false;
      
      if (connectivityResult != ConnectivityResult.none) {
        // Ada koneksi basic, cek internet sesungguhnya
        hasRealInternet = await connectivityService.checkInternetConnection();
      }
      
      _hasInternetConnection = hasRealInternet;
      _ref.read(internetConnectionProvider.notifier).state = hasRealInternet;
      
      // Check if user is authenticated and determine if we should show offline popup
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated && !hasRealInternet) {
        _shouldShowOfflinePopup = true;
        developer.log('Initial check: User authenticated but no internet - showing offline popup', name: 'GlobalOfflineHandler');
      } else {
        _shouldShowOfflinePopup = false;
      }
      
      _isInitialized = true;
      
      // Notify listeners immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
      
      developer.log('Initial check completed. Internet: $hasRealInternet, Show popup: $_shouldShowOfflinePopup, Initialized: $_isInitialized', name: 'GlobalOfflineHandler');
      
    } catch (e) {
      developer.log('Error in initial connectivity check: $e', name: 'GlobalOfflineHandler');
      _hasInternetConnection = false;
      _ref.read(internetConnectionProvider.notifier).state = false;
      
      // Mark as initialized even on error
      _isInitialized = true;
      
      final authState = _ref.read(authProvider);
      if (authState.isAuthenticated) {
        _shouldShowOfflinePopup = true;
      }
      
      // Notify listeners immediately 
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  Future<void> _handleConnectivityChange(ConnectivityResult result) async {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Debounce connectivity changes to prevent rapid firing and UI freeze
    _debounceTimer = Timer(const Duration(milliseconds: 800), () async {
      await _processConnectivityChange(result);
    });
  }

  Future<void> _processConnectivityChange(ConnectivityResult result) async {
    if (_isCheckingConnection) return;
    _isCheckingConnection = true;
    
    try {
      developer.log('Processing connectivity change to: $result', name: 'GlobalOfflineHandler');
      
      final hasBasicConnection = result != ConnectivityResult.none;
      bool hasRealInternet = false;
      
      if (hasBasicConnection) {
        // Ada koneksi WiFi/mobile, sekarang cek internet sesungguhnya
        final connectivityService = _ref.read(connectivityServiceProvider);
        hasRealInternet = await connectivityService.checkInternetConnection();
      }
      
      final previousConnectionState = _hasInternetConnection;
      _hasInternetConnection = hasRealInternet;
      _ref.read(internetConnectionProvider.notifier).state = hasRealInternet;
      
      final authState = _ref.read(authProvider);
      
      if (authState.isAuthenticated) {
        if (!hasRealInternet && previousConnectionState) {
          // Internet baru saja putus - show popup immediately (prioritize popup over capsule)
          _shouldShowOfflinePopup = true;
          developer.log('Connection lost - showing offline popup immediately', name: 'GlobalOfflineHandler');
          
          // Force immediate notification to update UI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
          
        } else if (hasRealInternet && !previousConnectionState) {
          // Internet baru saja kembali
          _shouldShowOfflinePopup = false;
          developer.log('Connection restored - hiding offline popup', name: 'GlobalOfflineHandler');
          
          // Force immediate notification to update UI
          WidgetsBinding.instance.addPostFrameCallback((_) {
            notifyListeners();
          });
          
          // Auto refresh data when connection restored
          _handleConnectionRestored();
        } else if (!hasRealInternet) {
          // Masih offline or tetap offline - ensure popup is shown
          if (!_shouldShowOfflinePopup) {
            _shouldShowOfflinePopup = true;
            developer.log('Still offline - ensuring popup is shown', name: 'GlobalOfflineHandler');
            
            // Force immediate notification to update UI
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          }
        } else {
          _shouldShowOfflinePopup = false;
        }
      } else {
        _shouldShowOfflinePopup = false;
      }
      
    } catch (e) {
      developer.log('Error processing connectivity change: $e', name: 'GlobalOfflineHandler');
    } finally {
      _isCheckingConnection = false;
    }
  }

  Future<void> _handleConnectionRestored() async {
    try {
      // Auto-refresh when connection is restored
      final globalRefresh = _ref.read(globalRefreshProvider);
      await globalRefresh();
      developer.log('Auto-refresh completed after connection restored', name: 'GlobalOfflineHandler');
    } catch (e) {
      developer.log('Error in auto-refresh after connection restored: $e', name: 'GlobalOfflineHandler');
    }
  }

  void _startPeriodicInternetCheck() {
    // Check setiap 15 detik (less frequent to prevent freeze)
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (!_isInitialized || _isCheckingConnection) return;
      
      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated) {
        return;
      }
      
      try {
        final connectivityService = _ref.read(connectivityServiceProvider);
        final hasRealInternet = await connectivityService.checkInternetConnection();
        
        // Check for any connection state changes
        if (_hasInternetConnection != hasRealInternet) {
          developer.log('Periodic check detected connectivity change: $_hasInternetConnection -> $hasRealInternet', name: 'GlobalOfflineHandler');
          
          _hasInternetConnection = hasRealInternet;
          _ref.read(internetConnectionProvider.notifier).state = hasRealInternet;
          
          if (!hasRealInternet) {
            // Internet lost - show popup immediately
            _shouldShowOfflinePopup = true;
            developer.log('Periodic check: Internet lost - showing offline popup', name: 'GlobalOfflineHandler');
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
          } else {
            // Internet restored - hide popup
            _shouldShowOfflinePopup = false;
            developer.log('Periodic check: Internet restored - hiding offline popup', name: 'GlobalOfflineHandler');
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              notifyListeners();
            });
            
            // Auto refresh when restored
            _handleConnectionRestored();
          }
        }
      } catch (e) {
        developer.log('Error in periodic connectivity check: $e', name: 'GlobalOfflineHandler');
      }
    });
  }

  // Method untuk manual refresh dari UI
  Future<bool> refreshConnection() async {
    try {
      // Cek koneksi internet sesungguhnya
      final connectivityService = _ref.read(connectivityServiceProvider);
      final hasRealInternet = await connectivityService.checkInternetConnection();
      
      if (!hasRealInternet) {
        // Masih tidak ada internet
        return false;
      }
      
      // Update status koneksi
      _hasInternetConnection = true;
      _ref.read(internetConnectionProvider.notifier).state = true;
      
      // Coba refresh data
      final globalRefresh = _ref.read(globalRefreshProvider);
      final success = await globalRefresh();
      
      if (success) {
        _shouldShowOfflinePopup = false;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      developer.log('Error in manual refresh: $e', name: 'GlobalOfflineHandler');
      return false;
    }
  }

  // Method untuk dismiss offline popup setelah user klik "Coba Lagi"
  void dismissOfflinePopup() {
    if (_shouldShowOfflinePopup) {
      _shouldShowOfflinePopup = false;
      notifyListeners();
      developer.log('Dismissing offline popup - allowing offline mode', name: 'GlobalOfflineHandler');
    }
  }

  void _setupAuthListener() {
    // Listen to auth state changes
    _authSubscription = _ref.listen<AuthState>(authProvider, (previous, next) {
      developer.log('Auth state changed. Authenticated: ${next.isAuthenticated}', name: 'GlobalOfflineHandler');
      
      if (next.isAuthenticated && !_hasInternetConnection) {
        // User just logged in and is offline - show popup
        _shouldShowOfflinePopup = true;
        notifyListeners();
        developer.log('User logged in while offline - showing popup', name: 'GlobalOfflineHandler');
      } else if (!next.isAuthenticated) {
        // User logged out - hide popup
        _shouldShowOfflinePopup = false;
        notifyListeners();
        developer.log('User logged out - hiding popup', name: 'GlobalOfflineHandler');
      }
    }, fireImmediately: false);
  }

  // Method untuk force check offline state setelah app restart
  Future<void> forceCheckOfflineState() async {
    developer.log('Force checking offline state', name: 'GlobalOfflineHandler');
    
    final authState = _ref.read(authProvider);
    if (!authState.isAuthenticated) {
      developer.log('User not authenticated, skipping offline check', name: 'GlobalOfflineHandler');
      _shouldShowOfflinePopup = false;
      notifyListeners();
      return;
    }
    
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final connectivityService = _ref.read(connectivityServiceProvider);
      
      bool hasRealInternet = false;
      
      if (connectivityResult != ConnectivityResult.none) {
        // Ada koneksi basic, cek internet sesungguhnya
        hasRealInternet = await connectivityService.checkInternetConnection();
      }
      
      _hasInternetConnection = hasRealInternet;
      _ref.read(internetConnectionProvider.notifier).state = hasRealInternet;
      
      if (!hasRealInternet) {
        _shouldShowOfflinePopup = true;
        developer.log('Force check: No internet - showing offline popup', name: 'GlobalOfflineHandler');
      } else {
        _shouldShowOfflinePopup = false;
        developer.log('Force check: Internet available - hiding offline popup', name: 'GlobalOfflineHandler');
      }
      
      _isInitialized = true;
      notifyListeners();
      
    } catch (e) {
      developer.log('Error in force offline check: $e', name: 'GlobalOfflineHandler');
      // On error, assume offline
      _hasInternetConnection = false;
      _ref.read(internetConnectionProvider.notifier).state = false;
      _shouldShowOfflinePopup = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Method untuk force show offline popup (misalnya saat auth state berubah)
  void checkOfflineStateForAuthenticatedUser() {
    final authState = _ref.read(authProvider);
    if (authState.isAuthenticated && !_hasInternetConnection) {
      _shouldShowOfflinePopup = true;
      notifyListeners();
      developer.log('Force showing offline popup for authenticated user', name: 'GlobalOfflineHandler');
    }
  }

  // Method untuk hide offline popup (misalnya saat logout)
  void hideOfflinePopup() {
    if (_shouldShowOfflinePopup) {
      _shouldShowOfflinePopup = false;
      notifyListeners();
      developer.log('Hiding offline popup', name: 'GlobalOfflineHandler');
    }
  }

  // Handle app lifecycle changes (app resume/pause)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      developer.log('App resumed - performing connectivity check', name: 'GlobalOfflineHandler');
      
      // When app resumes, check connectivity immediately
      Future.delayed(const Duration(milliseconds: 500), () {
        forceCheckOfflineState();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove lifecycle observer
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    _initialCheckTimer?.cancel();
    _debounceTimer?.cancel();
    _authSubscription?.close();
    super.dispose();
  }
}
