import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';
import '../models/user.dart';
import '../services/api.dart';
import '../services/fcm_service.dart';


extension AuthNotifierUserUpdate on AuthNotifier {
  void updateUser(User user) {
    // ignore: invalid_use_of_protected_member
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    state = state.copyWith(user: user);
  }
}

// Auth state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final String? token;
  final String? errorMessage;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth notifier class
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  AuthNotifier(this._apiService, this._prefs) : super(AuthState()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    developer.log('Initializing authentication', name: 'AuthProvider');
    final token = _prefs.getString('auth_token');
    final userJson = _prefs.getString('user_data');
    final username = _prefs.getString('username');
    
    if (token != null && userJson != null && username != null) {
      try {
        _apiService.token = token;
        _apiService.currentUsername = username;
        final user = User.fromJson(
            Map<String, dynamic>.from(json.decode(userJson) as Map));
        
        // Set authentication state with stored data
        state = state.copyWith(
          isAuthenticated: true,
          token: token,
          user: user,
        );
        
        // Validate token without requiring immediate refresh
        _validateToken();
        
        developer.log('Authentication restored for user: ${user.username}', name: 'AuthProvider');
      } catch (e) {
        developer.log('Error restoring authentication: $e', name: 'AuthProvider');
        // Clear invalid data
        await _clearStoredAuth();
      }
    } else {
      developer.log('No saved authentication found', name: 'AuthProvider');
    }
  }

  // Method to validate token
  Future<void> _validateToken() async {
    try {
      // Check token validity by trying to fetch user profile
      final result = await _apiService.getUserProfile();
      
      if (!result['success']) {
        developer.log('Stored token is invalid, attempting silent refresh', name: 'AuthProvider');
        await _refreshToken();
      }
    } catch (e) {
      developer.log('Error validating token: $e', name: 'AuthProvider');
    }
  }

  // Method for token refresh
  Future<bool> _refreshToken() async {
    if (state.token == null) return false;
    
    try {
      // Use the provided API service to refresh token
      final result = await _apiService.refreshToken(state.token!);
      
      if (result['success']) {
        final newToken = result['token'];
        _apiService.token = newToken;
        await _prefs.setString('auth_token', newToken);
        state = state.copyWith(token: newToken);
        developer.log('Token refreshed successfully', name: 'AuthProvider');
        return true;
      }
      
      // If refresh failed, hanya logout jika bukan masalah koneksi
      developer.log('Token refresh failed', name: 'AuthProvider');
      return false;
      
    } catch (e) {
      developer.log('Error refreshing token: $e', name: 'AuthProvider');
      // Jangan logout otomatis pada error koneksi, biar user tetap dalam mode offline
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _apiService.login(username, password);
      
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
        
        developer.log('Login successful for user: $username', name: 'AuthProvider');
        
        // Register FCM token after successful login (for admin users only)
        if (user.isAdmin) {
          _registerFcmTokenAfterLogin();
        }
        
        return true;
      } else {
        developer.log('Login failed for user: $username', name: 'AuthProvider');
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        return false;
      }
    } catch (e) {
      developer.log('Login error: $e', name: 'AuthProvider');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> _registerFcmTokenAfterLogin() async {
    try {
      developer.log('Attempting to register FCM token after login', name: 'AuthProvider');
      
      // Get FCM token from saved preferences or current token
      String? fcmToken = await FCMService.getSavedToken();
      
      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('No FCM token available, skipping registration', name: 'AuthProvider');
        return;
      }
      
      // Register token with the server
      final result = await _apiService.registerFcmToken(fcmToken);
      
      if (result['success']) {
        developer.log('FCM token registered successfully after login', name: 'AuthProvider');
      } else {
        developer.log('Failed to register FCM token: ${result['message']}', name: 'AuthProvider');
      }
    } catch (e) {
      // Don't fail login if FCM registration fails
      developer.log('Error registering FCM token after login: $e', name: 'AuthProvider');
    }
  }

  // Method to manually register FCM token (e.g., when token is refreshed)
  Future<bool> registerFcmToken(String fcmToken) async {
    try {
      developer.log('Manually registering FCM token', name: 'AuthProvider');
      
      if (state.token == null) {
        developer.log('No auth token available for FCM registration', name: 'AuthProvider');
        return false;
      }
      
      final result = await _apiService.registerFcmToken(fcmToken);
      
      if (result['success']) {
        developer.log('FCM token registered successfully', name: 'AuthProvider');
        return true;
      } else {
        developer.log('Failed to register FCM token: ${result['message']}', name: 'AuthProvider');
        return false;
      }
    } catch (e) {
      developer.log('Error registering FCM token: $e', name: 'AuthProvider');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Call API logout endpoint to invalidate token on server
      final result = await _apiService.logout();
      
      if (!result['success']) {
        developer.log('Warning: Server-side logout failed', name: 'AuthProvider');
      }
      
      // Clear stored auth data regardless of API response
      await _clearStoredAuth();
      
      // Reset API service
      _apiService.clearSession();
      
      // Reset auth state
      state = AuthState();
      
      developer.log('User logged out', name: 'AuthProvider');
    } catch (e) {
      developer.log('Error during logout: $e', name: 'AuthProvider');
      
      // Still clear auth data and reset state on error
      await _clearStoredAuth();
      _apiService.clearSession();
      state = AuthState();
    }
  }

  void setErrorMessage(String message) {
    state = state.copyWith(errorMessage: message);
  }

  Future<void> _clearStoredAuth() async {
    await _prefs.remove('auth_token');
    await _prefs.remove('user_data');
    await _prefs.remove('username');
    developer.log('Stored auth data cleared', name: 'AuthProvider');
  }

  // Method untuk refresh connection - digunakan oleh global refresh provider
  Future<bool> refreshConnection() async {
    developer.log('Attempting to refresh connection', name: 'AuthProvider');
    
    try {
      // Jika tidak ada token, tidak bisa refresh
      if (state.token == null) {
        developer.log('No token available for refresh', name: 'AuthProvider');
        return false;
      }
      
      // Coba validate token dengan server
      final result = await _apiService.getUserProfile();
      
      if (result['success']) {
        developer.log('Connection refresh successful', name: 'AuthProvider');
        // Update user profile jika berhasil
        if (result['user'] != null) {
          updateUser(result['user']);
        }
        return true;
      } else {
        // Token invalid, coba refresh token tapi jangan logout otomatis
        developer.log('Token invalid, attempting token refresh', name: 'AuthProvider');
        return await _refreshToken();
      }
    } catch (e) {
      developer.log('Error refreshing connection: $e', name: 'AuthProvider');
      // Return false tapi jangan logout, biar user tetap dalam mode offline
      return false;
    }
  }
  
  // Method untuk check koneksi sederhana
  Future<bool> checkConnection() async {
    try {
      if (state.token == null) return false;
      
      final result = await _apiService.getUserProfile();
      return result['success'];
    } catch (e) {
      developer.log('Error checking connection: $e', name: 'AuthProvider');
      return false;
    }
  }
}

// Provider definition
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  throw UnimplementedError();
});

