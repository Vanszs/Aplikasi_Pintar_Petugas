import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/report.dart';

class SocketService extends ChangeNotifier {
  final String baseUrl;
  IO.Socket? _socket;
  bool _connected = false;

  SocketService({required this.baseUrl});

  bool get isConnected => _connected;

  void connect() {
    try {
      developer.log('Connecting to socket server: $baseUrl/iot', name: 'SocketService');

      _socket = IO.io('$baseUrl/iot', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 99999, // Infinite retry attempts
        'forceNew': false,
        'timeout': 20000, // 20 seconds timeout
      });

      _socket!.onConnect((_) {
        _connected = true;
        developer.log('Socket connected with ID: ${_socket!.id}', name: 'SocketService');
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        _connected = false;
        developer.log('Socket disconnected', name: 'SocketService');
        // Try to reconnect after a delay when disconnected
        Future.delayed(Duration(seconds: 3), () {
          if (!_connected && _socket != null) {
            developer.log('Attempting reconnection after disconnect', name: 'SocketService');
            _socket!.connect();
          }
        });
        notifyListeners();
      });

      _socket!.onError((error) {
        _connected = false;
        developer.log('Socket error: $error', name: 'SocketService');
        notifyListeners();
      });

      _socket!.onConnectError((error) {
        _connected = false;
        developer.log('Socket connect error: $error', name: 'SocketService');
        notifyListeners();
      });

    } catch (e) {
      _connected = false;
      developer.log('Error connecting to socket: $e', name: 'SocketService');
      notifyListeners();
    }
  }

  void disconnect() {
    try {
      if (_socket != null) {
        _socket!.disconnect();
        _connected = false;
        developer.log('Socket disconnected manually', name: 'SocketService');
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error disconnecting socket: $e', name: 'SocketService');
    }
  }

  void on(String event, Function(dynamic) callback) {
    try {
      if (_socket != null) {
        _socket!.on(event, callback);
        developer.log('Registered listener for event: $event', name: 'SocketService');
      } else {
        developer.log('Cannot register listener: socket is null', name: 'SocketService');
      }
    } catch (e) {
      developer.log('Error registering socket event: $e', name: 'SocketService');
    }
  }

  void emit(String event, dynamic data) {
    try {
      if (_socket != null && _connected) {
        _socket!.emit(event, data);
        developer.log('Emitted event: $event', name: 'SocketService');
      } else {
        developer.log('Cannot emit: socket is null or not connected', name: 'SocketService');
      }
    } catch (e) {
      developer.log('Error emitting socket event: $e', name: 'SocketService');
    }
  }

  void listenForReports(Function(Report) onNewReport) {
    on('new_report', (data) {
      try {
        developer.log('Received new_report: $data', name: 'SocketService');

        // Check if socket is still active before processing
        if (_socket == null) return;

        // Sesuaikan dengan format data dari backend
        final report = Report(
          id: data['id'],
          userId: 0, // Backend tidak mengirim user_id
          address: data['address'],
          createdAt: DateTime.parse(data['created_at']),
          userName: data['name'],
        );

        onNewReport(report);
      } catch (e) {
        developer.log('Error parsing report data: $e', name: 'SocketService');
      }
    });
  }
}

final socketServiceProvider = ChangeNotifierProvider<SocketService>((ref) {
  // This will be initialized in main.dart
  throw UnimplementedError();
});
