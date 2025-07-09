import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:developer' as developer;

class ConnectivityService extends ChangeNotifier {
  bool _isConnected = true;
  bool _isChecking = false;
  Timer? _periodicCheck;

  ConnectivityService() {
    // Setup periodic connectivity check
    _periodicCheck = Timer.periodic(
      const Duration(seconds: 30), 
      (_) => checkInternetConnection()
    );
    
    // Immediate check when service is created
    checkInternetConnection();
  }

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;

  Future<bool> checkInternetConnection() async {
    if (_isChecking) return _isConnected;
    
    _isChecking = true;
    notifyListeners();

    try {
      developer.log('Checking internet connectivity...', name: 'ConnectivityService');
      
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      final newStatus = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      // Only notify if status changed
      if (_isConnected != newStatus) {
        _isConnected = newStatus;
        notifyListeners();
      }
      
      developer.log('Internet connectivity: $_isConnected', name: 'ConnectivityService');
    } catch (e) {
      developer.log('Internet connectivity check failed: $e', name: 'ConnectivityService');
      
      // Only notify if status changed
      if (_isConnected) {
        _isConnected = false;
        notifyListeners();
      }
    }

    _isChecking = false;
    notifyListeners();
    return _isConnected;
  }

  void setConnectionStatus(bool status) {
    if (_isConnected != status) {
      _isConnected = status;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _periodicCheck?.cancel();
    super.dispose();
  }
}
