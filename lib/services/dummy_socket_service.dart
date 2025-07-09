import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/report.dart';
import 'dart:async';

class DummySocketService extends ChangeNotifier {
  final String baseUrl;
  bool _isConnected = false;
  Timer? _connectionTimer;

  DummySocketService({required this.baseUrl});

  bool get isConnected => _isConnected;

  void connect() {
    developer.log('Dummy: Connecting to socket (simulated)', name: 'DummySocketService');
    
    // Simulate connection delay
    _connectionTimer = Timer(const Duration(milliseconds: 500), () {
      _isConnected = true;
      notifyListeners();
      developer.log('Dummy: Socket connected (simulated)', name: 'DummySocketService');
    });
  }

  void listenForReports(Function(Report) onNewReport) {
    developer.log('Dummy: Listening for reports (no new reports in demo)', name: 'DummySocketService');
    // In dummy mode, we don't simulate new reports to keep it simple
    // Real implementation would call onNewReport when receiving socket events
  }

  void disconnect() {
    _connectionTimer?.cancel();
    _isConnected = false;
    notifyListeners();
    developer.log('Dummy: Socket disconnected', name: 'DummySocketService');
  }
}
