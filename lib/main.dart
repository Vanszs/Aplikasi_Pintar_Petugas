import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    return realSocket;
  }
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDummy = ref.watch(isDummyModeProvider);
    
    return MaterialApp.router(
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
    );
  }
}

// Simplified AutoSwitchingAuthNotifier
class AutoSwitchingAuthNotifier extends AuthNotifier {
  final StateNotifierProviderRef<AuthNotifier, AuthState> _ref;
  final String _serverUrl;
  final SharedPreferences _prefs;

  AutoSwitchingAuthNotifier(this._ref, this._prefs, this._serverUrl) 
      : super(ApiService(baseUrl: _serverUrl), _prefs) {
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

  @override
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
      
      // If refresh failed, user needs to login again
      developer.log('Token refresh failed, logging out', name: 'AutoSwitchingAuth');
      await logout();
      return false;
      
    } catch (e) {
      developer.log('Error refreshing token: $e', name: 'AutoSwitchingAuth');
      return false;
    }
  }
}
