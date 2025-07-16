import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'routes.dart';
import 'models/user.dart';
import 'services/api.dart';
import 'services/socket_service.dart';
import 'services/dummy_api_service.dart';
import 'services/dummy_socket_service.dart';
import 'services/connectivity_service.dart';
import 'providers/auth_provider.dart';
import 'providers/report_provider.dart';
// import 'services/notification_service.dart'; // Provider defined in service file
// import 'services/background_service.dart'; // REMOVED: Using FCM only
// import 'services/wake_lock_service.dart'; // REMOVED: WakeLock causes conflicts
import 'services/fcm_service.dart';
import 'widgets/notification_permission_handler.dart';

// Provider untuk menentukan mode dummy berdasarkan credential
final isDummyModeProvider = StateProvider<bool>((ref) => false);

// Provider untuk safe area padding
final safePaddingProvider = StateProvider<double>((ref) => 0);

// Provider untuk connectivity service
final connectivityServiceProvider = ChangeNotifierProvider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  return service;
});

// Server configuration
const serverIp = '185.197.195.155'; 
const serverPort = '3000';
const serverUrl = 'http://$serverIp:$serverPort';

// Create a provider for ApiService yang reaktif terhadap isDummyModeProvider
final apiServiceProvider = Provider<dynamic>((ref) {
  final isDummy = ref.watch(isDummyModeProvider);
  if (isDummy) {
    return DummyApiService(baseUrl: 'dummy://localhost');
  } else {
    return ApiService(baseUrl: serverUrl);
  }
});

// Create a provider for SocketService yang reaktif terhadap isDummyModeProvider
final socketServiceProvider = Provider<dynamic>((ref) {
  final isDummy = ref.watch(isDummyModeProvider);
  if (isDummy) {
    final dummySocket = DummySocketService(baseUrl: 'dummy://localhost');
    dummySocket.connect();
    return dummySocket;
  } else {
    final realSocket = SocketService(baseUrl: serverUrl);
    realSocket.connect();
    
    // Create and initialize the lifecycle observer
    AppLifecycleObserver(realSocket); // This automatically registers itself
    
    return realSocket;
  }
});

// Import notification service


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase first
  try {
    await FCMService.initialize();
    developer.log('Firebase initialized', name: 'Main');
  } catch (e) {
    developer.log('Error initializing Firebase: $e', name: 'Main');
  }
  
  // Initialize background service for persistent socket connections
  // REMOVED: Background service causes crashes and conflicts with FCM
  // Only using FCM for notifications now
  /*
  try {
    await BackgroundService.initializeService();
    developer.log('Background service initialized', name: 'Main');
  } catch (e) {
    developer.log('Error initializing background service: $e', name: 'Main');
  }
  */
  
  // WakeLock service REMOVED to prevent battery drain and conflicts
  // FCM notifications work without keeping app always awake
  /*
  try {
    await WakeLockService.enableWakeLock();
    developer.log('Enhanced WakeLock enabled with keepalive pulses', name: 'Main');
  } catch (e) {
    developer.log('Failed to enable enhanced WakeLock: $e', name: 'Main');
    // Fallback to basic wakelock if custom service fails
    try {
      await WakelockPlus.enable();
      developer.log('Basic WakeLock enabled as fallback', name: 'Main');
    } catch (e) {
      developer.log('Failed to enable WakeLock: $e', name: 'Main');
    }
  }
  */
  
  // Set preferred orientations
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Get shared preferences instance
  final prefs = await SharedPreferences.getInstance();
  
  developer.log('🌐 Starting app with auto-detection mode', name: 'Main');
  
  runApp(
    ProviderScope(
      overrides: [
        // Override auth provider with auto-switching capability
        authProvider.overrideWith((ref) {
          return AutoSwitchingAuthNotifier(ref, prefs, serverUrl);
        }),
        
        // Override report provider
        reportProvider.overrideWith((ref) {
          final apiService = ref.watch(apiServiceProvider);
          final socketService = ref.watch(socketServiceProvider);
          return ReportNotifier(apiService, socketService, ref);
        }),
        
        // Register FCM service provider
        fcmServiceProvider.overrideWith(
          (ref) => FCMService()
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize FCM service after the app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFCM();
    });
  }

  Future<void> _initializeFCM() async {
    try {
      final fcmService = ref.read(fcmServiceProvider);
      await fcmService.initializeFCM();
      
      // Subscribe to general notifications topic
      await fcmService.subscribeToTopic('petugas_notifications');
      
      // Set up token refresh callback to register with server when token changes
      fcmService.setTokenRefreshCallback((newToken) {
        _registerFcmTokenOnRefresh(newToken);
      });
      
      developer.log('FCM service initialized in MyApp', name: 'MyApp');
    } catch (e) {
      developer.log('Error initializing FCM in MyApp: $e', name: 'MyApp');
    }
  }

  void _registerFcmTokenOnRefresh(String newToken) {
    try {
      final authState = ref.read(authProvider);
      
      // Only register if user is authenticated and is admin
      if (authState.isAuthenticated && 
          authState.user != null && 
          authState.user!.isAdmin && 
          !ref.read(isDummyModeProvider)) {
        
        final apiService = ref.read(apiServiceProvider);
        
        // Register the new token
        apiService.registerFcmToken(newToken).then((result) {
          if (result['success']) {
            developer.log('FCM token updated successfully on refresh', name: 'MyApp');
          } else {
            developer.log('Failed to update FCM token on refresh: ${result['message']}', name: 'MyApp');
          }
        }).catchError((e) {
          developer.log('Error updating FCM token on refresh: $e', name: 'MyApp');
        });
      }
    } catch (e) {
      developer.log('Error in _registerFcmTokenOnRefresh: $e', name: 'MyApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final isDummy = ref.watch(isDummyModeProvider);
    
    return NotificationPermissionHandler(
      child: MaterialApp.router(
        title: isDummy ? 'Simokerto PINTAR Petugas (Demo)' : 'Simokerto PINTAR Petugas',
        debugShowCheckedModeBanner: false,
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
      
      // Add localization support
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Indonesian
        Locale('en', 'US'), // English
      ],
      locale: const Locale('id', 'ID'),
      
      theme: ThemeData(
        primaryColor: const Color(0xFF9AA6B2), // Updated to darker blue-gray
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Very light blue-gray
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF9AA6B2), // Darker blue-gray
          secondary: Color(0xFF64748B), // Medium slate
          surface: Colors.white,
          error: Color(0xFFEF4444),
        ),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: const Color(0xFF334155), // Darker text for contrast
          displayColor: const Color(0xFF1E293B), // Almost black text for headers
        ),
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF374151)),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          labelStyle: GoogleFonts.inter(color: const Color(0xFF6B7280)),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          iconColor: const Color(0xFF4F46E5),
        ),
      ),
      ),
    );
  }
}

// Simplified AutoSwitchingAuthNotifier
class AutoSwitchingAuthNotifier extends AuthNotifier {
  final Ref _ref;
  final SharedPreferences _prefs;

  AutoSwitchingAuthNotifier(this._ref, this._prefs, String serverUrl) 
      : super(ApiService(baseUrl: serverUrl), _prefs) {
    _initializeAuth();
  }

  void _switchToMode(bool isDummy) {
    // Update dummy mode state - providers akan otomatis beralih
    _ref.read(isDummyModeProvider.notifier).state = isDummy;
    developer.log('Switched to ${isDummy ? 'dummy' : 'real'} mode', name: 'AutoSwitchingAuth');
  }

  @override
  Future<bool> login(String username, String password) async {
    // Auto-detect mode based on credentials
    final isDummy = (username == 'test' && password == 'test');
    
    // Switch to appropriate mode
    _switchToMode(isDummy);
    
    // Get the current API service (akan otomatis sesuai mode)
    final apiService = _ref.read(apiServiceProvider);
    
    // Call login with current API service
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await apiService.login(username, password);
      
      if (result['success']) {
        final user = result['user'];
        final token = result['token'];
        
        // Save to shared preferences
        await _prefs.setString('auth_token', token);
        await _prefs.setString('user_data', json.encode(user.toJson()));
        await _prefs.setString('username', username);
        
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: user,
          token: token,
        );
        
        developer.log('Login successful for user: $username', name: 'AutoSwitchingAuth');
        
        // Enable FCM notifications after successful login
        try {
          final fcmService = _ref.read(fcmServiceProvider);
          fcmService.setNotificationsEnabled(true);
          developer.log('Enabled FCM notifications after login', name: 'AutoSwitchingAuth');
        } catch (e) {
          developer.log('Error enabling FCM notifications: $e', name: 'AutoSwitchingAuth');
        }
        
        // Register FCM token after successful login (for admin users only and not in dummy mode)
        if (user.isAdmin && !isDummy) {
          _registerFcmTokenAfterLogin(apiService);
        }
        
        return true;
      } else {
        developer.log('Login failed for user: $username', name: 'AutoSwitchingAuth');
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      developer.log('Login error for user: $username, error: $e', name: 'AutoSwitchingAuth');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Terjadi kesalahan: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> _registerFcmTokenAfterLogin(dynamic apiService) async {
    try {
      developer.log('Attempting to register FCM token after login', name: 'AutoSwitchingAuth');
      
      // Get FCM token from saved preferences or current token
      String? fcmToken = await FCMService.getSavedToken();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('No FCM token available, skipping registration', name: 'AutoSwitchingAuth');
        return;
      }
      
      // Register token with the server
      final result = await apiService.registerFcmToken(fcmToken);
      
      if (result['success']) {
        developer.log('FCM token registered successfully after login', name: 'AutoSwitchingAuth');
      } else {
        developer.log('Failed to register FCM token: ${result['message']}', name: 'AutoSwitchingAuth');
      }
    } catch (e) {
      // Don't fail login if FCM registration fails
      developer.log('Error registering FCM token after login: $e', name: 'AutoSwitchingAuth');
    }
  }

  @override
  Future<void> logout() async {
    developer.log('Logging out user', name: 'AutoSwitchingAuth');
    
    // Get the current API service before clearing anything
    final apiService = _ref.read(apiServiceProvider);
    
    try {
      // Call API logout to blacklist token on server
      final result = await apiService.logout();
      
      if (!result['success']) {
        developer.log('Warning: Server-side logout failed', name: 'AutoSwitchingAuth');
      }
      
      // Clear stored authentication data
      await _clearStoredAuth();
      
      // Clear socket listeners and notifications from report provider
      try {
        final reportNotifier = _ref.read(reportProvider.notifier);
        reportNotifier.clearSocketListeners();
        developer.log('Cleared socket listeners and notifications', name: 'AutoSwitchingAuth');
      } catch (e) {
        developer.log('Error clearing socket listeners: $e', name: 'AutoSwitchingAuth');
      }
      
      // Disable FCM notifications
      try {
        final fcmService = _ref.read(fcmServiceProvider);
        fcmService.setNotificationsEnabled(false);
        developer.log('Disabled FCM notifications', name: 'AutoSwitchingAuth');
      } catch (e) {
        developer.log('Error disabling FCM notifications: $e', name: 'AutoSwitchingAuth');
      }
      
      // Reset to real mode
      _switchToMode(false);
      
      // Reset auth state
      state = AuthState();
      
      developer.log('Logout completed', name: 'AutoSwitchingAuth');
    } catch (e) {
      developer.log('Error during logout: $e', name: 'AutoSwitchingAuth');
      
      // Clear stored authentication data on error
      await _clearStoredAuth();
      
      // Reset API service session
      apiService.clearSession();
      
      // Try to clear socket listeners even on error
      try {
        final reportNotifier = _ref.read(reportProvider.notifier);
        reportNotifier.clearSocketListeners();
      } catch (cleanupError) {
        developer.log('Error during cleanup: $cleanupError', name: 'AutoSwitchingAuth');
      }
      
      // Try to disable FCM notifications even on error
      try {
        final fcmService = _ref.read(fcmServiceProvider);
        fcmService.setNotificationsEnabled(false);
      } catch (fcmError) {
        developer.log('Error disabling FCM notifications during cleanup: $fcmError', name: 'AutoSwitchingAuth');
      }
      
      // Reset to real mode
      _switchToMode(false);
      
      // Reset auth state
      state = AuthState();
    }
  }

  Future<void> _clearStoredAuth() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    await _prefs.remove('username');
  }

  Future<void> _initializeAuth() async {
    developer.log('Initializing authentication', name: 'AutoSwitchingAuth');
    final token = _prefs.getString('auth_token');
    final userJson = _prefs.getString('user_data');
    final username = _prefs.getString('username');
    
    if (token != null && userJson != null && username != null) {
      try {
        // Detect mode berdasarkan username yang tersimpan
        final isDummy = (username == 'test');
        _switchToMode(isDummy);
        
        // Get current API service after mode switch
        final apiService = _ref.read(apiServiceProvider);
        apiService.token = token;
        apiService.currentUsername = username;
        
        final user = User.fromJson(
            Map<String, dynamic>.from(json.decode(userJson) as Map));
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: user,
        );
        
        // Validate token with the appropriate service
        _validateToken(apiService);
        
        developer.log('Authentication restored for user: ${user.username}', name: 'AutoSwitchingAuth');
      } catch (e) {
        developer.log('Error restoring authentication: $e', name: 'AutoSwitchingAuth');
        // Clear invalid data
        await _clearStoredAuth();
      }
    } else {
      developer.log('No saved authentication found', name: 'AutoSwitchingAuth');
    }
  }

  // New method to validate token using the current API service
  Future<void> _validateToken(dynamic apiService) async {
    try {
      final result = await apiService.getUserProfile();
      
      if (!result['success']) {
        developer.log('Stored token is invalid, attempting silent refresh', name: 'AutoSwitchingAuth');
        await _refreshToken(apiService);
      }
    } catch (e) {
      developer.log('Error validating token: $e', name: 'AutoSwitchingAuth');
    }
  }

  // New method for token refresh
  Future<bool> _refreshToken(dynamic apiService) async {
    if (state.user == null) return false;
    
    try {
      // Use the provided API service to refresh token
      final result = await apiService.refreshToken(state.token!);
      
      if (result['success']) {
        final newToken = result['token'];
        apiService.token = newToken;
        await _prefs.setString('auth_token', newToken);
        state = state.copyWith(token: newToken);
        developer.log('Token refreshed successfully', name: 'AutoSwitchingAuth');
        return true;
      }
      
      // FIXED: Jangan logout otomatis saat refresh gagal - bisa karena masalah koneksi
      developer.log('Token refresh failed - keeping user logged in for offline mode', name: 'AutoSwitchingAuth');
      return false;
      
    } catch (e) {
      developer.log('Error refreshing token (keeping user logged in): $e', name: 'AutoSwitchingAuth');
      // Jangan logout otomatis, biar user tetap login dalam mode offline
      return false;
    }
  }
}

// App lifecycle observer to handle background/foreground transitions
class AppLifecycleObserver with WidgetsBindingObserver {
  final SocketService socketService;

  AppLifecycleObserver(this.socketService) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log('App lifecycle state changed to: $state', name: 'AppLifecycleObserver');
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and responding to user input
        developer.log('APP RESUMED: Immediately reconnecting socket and refreshing data', name: 'AppLifecycleObserver');
        
        // First, immediately make sure socket is connected
        socketService.connect();
        
        // Delay very slightly to allow socket to connect
        Future.delayed(const Duration(milliseconds: 300), () {
          // Force reload report data with high priority
          developer.log('CRITICAL: Forcing data refresh now', name: 'AppLifecycleObserver');
          _forceReloadReports();
        });
        
        // Direct access to report notifier to force refresh
        try {
          developer.log('Broadcasting app resume to all listeners', name: 'AppLifecycleObserver');
          // This will broadcast to any listeners in the app
          socketService.emit('global:app_resumed', {'timestamp': DateTime.now().millisecondsSinceEpoch});
        } catch (e) {
          developer.log('Error broadcasting app resume: $e', name: 'AppLifecycleObserver');
        }
        
        // Make sure WakeLock is enabled when app is in foreground
        _ensureWakeLock(true);
        break;
        
      case AppLifecycleState.inactive:
        // App is in an inactive state (may happen when receiving phone call)
        // Keep the socket alive but allow screen to dim
        developer.log('App inactive: keeping socket alive', name: 'AppLifecycleObserver');
        socketService.keepAliveInBackground();
        _ensureWakeLock(false); // Let screen dim to save battery
        break;
        
      case AppLifecycleState.paused:
        // App is not visible but may still be processing
        // Keep the socket alive in the background
        developer.log('App paused: maintaining minimal background service', name: 'AppLifecycleObserver');
        socketService.keepAliveInBackground();
        
        // Disable WakeLock in background to save battery
        _ensureWakeLock(false);
        break;
        
      case AppLifecycleState.detached:
        // App is suspended but not terminated
        developer.log('App detached: releasing resources', name: 'AppLifecycleObserver');
        // Don't force connection in detached state to save battery
        _ensureWakeLock(false); // Make sure wakelock is off
        break;
        
      case AppLifecycleState.hidden:
        // For Flutter 3.13+, there's a hidden state
        developer.log('App hidden: maintaining minimal service', name: 'AppLifecycleObserver');
        socketService.keepAliveInBackground();
        _ensureWakeLock(false); // Let device sleep to save battery
        break;
        
      // No default case needed as we've covered all enum values
    }
  }

  // Helper method to ensure WakeLock is in the desired state
  Future<void> _ensureWakeLock(bool enable) async {
    try {
      if (enable) {
        // Only enable wakelock when in foreground to save battery
        if (!await WakelockPlus.enabled) {
          await WakelockPlus.enable();
          developer.log('WakeLock enabled', name: 'AppLifecycleObserver');
        }
      } else {
        // Disable when app is no longer visible
        if (await WakelockPlus.enabled) {
          await WakelockPlus.disable();
          developer.log('WakeLock disabled', name: 'AppLifecycleObserver');
        }
      }
    } catch (e) {
      developer.log('Error managing WakeLock: $e', name: 'AppLifecycleObserver');
    }
  }

  // Force reload of reports data using the provider system
  void _forceReloadReports() {
    // First immediate attempt
    Future.delayed(Duration.zero, () {
      try {
        developer.log('PRIORITY: Forcing immediate data refresh after app resume', name: 'AppLifecycleObserver');
        
        // Use socket service to emit a local refresh event that the app can react to
        try {
          // Emit app_resumed event multiple times with delays to ensure it's processed
          socketService.emit('app_resumed', {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'priority': 'high',
            'action': 'force_refresh'
          });
          
          // Log that we're forcing immediate refresh
          developer.log('Sent high priority app_resumed event to trigger refresh', name: 'AppLifecycleObserver');
        } catch (e) {
          developer.log('Error emitting app_resumed event: $e', name: 'AppLifecycleObserver');
        }
      } catch (e) {
        developer.log('Failed to trigger initial refresh: $e', name: 'AppLifecycleObserver');
      }
    });
    
    // Additional attempts with delays to ensure refresh happens
    Future.delayed(const Duration(milliseconds: 500), _sendRefreshRequest);
    Future.delayed(const Duration(seconds: 1), _sendRefreshRequest);
    Future.delayed(const Duration(seconds: 3), _sendRefreshRequest);
  }
  
  void _sendRefreshRequest() {
    try {
      // Emit app_resumed event to trigger refresh
      socketService.emit('app_resumed', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'action': 'refresh_data'
      });
      developer.log('Sent follow-up refresh request', name: 'AppLifecycleObserver');
    } catch (e) {
      developer.log('Error in follow-up refresh: $e', name: 'AppLifecycleObserver');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
