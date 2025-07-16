import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import '../services/global_offline_handler.dart';
import 'auth_provider.dart';
import 'dart:developer' as developer;

// Extended AuthNotifier that integrates with GlobalOfflineHandler
class AuthNotifierWithOfflineHandler extends AuthNotifier {
  final Ref _ref;

  AuthNotifierWithOfflineHandler(this._ref, ApiService apiService, SharedPreferences prefs)
      : super(apiService, prefs);

  @override
  Future<bool> login(String username, String password) async {
    final success = await super.login(username, password);
    
    if (success) {
      // After successful login, trigger offline check
      _triggerOfflineCheck();
    }
    
    return success;
  }

  @override
  Future<void> logout() async {
    // Hide offline popup before logout
    try {
      final offlineHandler = _ref.read(globalOfflineHandlerProvider);
      offlineHandler.hideOfflinePopup();
    } catch (e) {
      developer.log('Error hiding offline popup during logout: $e', name: 'AuthNotifierWithOfflineHandler');
    }
    
    await super.logout();
  }

  void _triggerOfflineCheck() {
    try {
      // Get the offline handler and check if we should show offline popup
      final offlineHandler = _ref.read(globalOfflineHandlerProvider);
      offlineHandler.checkOfflineStateForAuthenticatedUser();
      developer.log('Triggered offline check after login', name: 'AuthNotifierWithOfflineHandler');
    } catch (e) {
      developer.log('Error triggering offline check: $e', name: 'AuthNotifierWithOfflineHandler');
    }
  }
}
