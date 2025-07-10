import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:connectivity_plus/connectivity_plus.dart';

class SocketHelper {
  // Check if a host is reachable by performing a socket connection test
  static Future<bool> isHostReachable(String host, int port, {int timeout = 5}) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: Duration(seconds: timeout),
      );
      await socket.close();
      return true;
    } catch (e) {
      developer.log('Host $host:$port unreachable: $e', name: 'SocketHelper');
      return false;
    }
  }
  
  // Keep a socket connection alive by sending periodic data
  static Timer startKeepAliveTimer(
    Function sendFn, 
    {Duration interval = const Duration(seconds: 10)}
  ) {
    return Timer.periodic(interval, (_) {
      try {
        sendFn();
      } catch (e) {
        developer.log('Error in keep-alive: $e', name: 'SocketHelper');
      }
    });
  }
  
  // Check if device has internet connection
  static Future<bool> hasNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'SocketHelper');
      return false;
    }
  }
  
  // Enhanced ping function that tries multiple times
  static Future<bool> canReachHost(String host, int port) async {
    bool canReach = false;
    
    for (int i = 0; i < 3; i++) {
      canReach = await isHostReachable(host, port);
      if (canReach) break;
      
      // Wait before retrying
      await Future.delayed(Duration(seconds: 1));
    }
    
    return canReach;
  }
}
