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
      
      // Try multiple domains for better reliability
      bool isReachable = false;
      
      // Try multiple domains in case one is blocked
      for (String host in ['8.8.8.8', '1.1.1.1', 'google.com', 'cloudflare.com']) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 2));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            isReachable = true;
            break;
          }
        } catch (_) {
          // Try next host
          continue;
        }
      }
      
      // Only notify if status changed
      if (_isConnected != isReachable) {
        _isConnected = isReachable;
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
