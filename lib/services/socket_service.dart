import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import 'dart:async';
import '../models/report.dart';
import '../utils/socket_helper.dart';

class SocketService extends ChangeNotifier {
  final String baseUrl;
  IO.Socket? _socket;
  bool _connected = false;
  // Add a stream controller to notify listeners of new reports
  List<Function(Report)> _reportCallbacks = [];
  // Add keepalive timer
  Timer? _keepAliveTimer;

  SocketService({required this.baseUrl});

  bool get isConnected => _connected;

  Future<void> connect() async {
    try {
      // Check connectivity first - don't attempt connection if no network
      bool hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        developer.log('No connectivity, delaying socket connection', name: 'SocketService');
        // Try again in a few seconds with exponential backoff
        Future.delayed(Duration(seconds: 3), () => connect());
        return;
      }
      
      // Don't create a new socket if we already have a connected one
      if (_socket != null && _connected) {
        developer.log('Socket already connected, sending ping to verify connection', name: 'SocketService');
        try {
          _socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          
          // Set up ping response timeout
          bool pingResponseReceived = false;
          _socket!.once('pong', (_) {
            pingResponseReceived = true;
            developer.log('Received pong, connection is healthy', name: 'SocketService');
          });
          
          // Wait briefly for pong response
          await Future.delayed(Duration(seconds: 2));
          
          if (!pingResponseReceived) {
            developer.log('No pong received, connection may be stale - reconnecting', name: 'SocketService');
            _connected = false;
          } else if (_connected) {
            return; // Connection is healthy, no need to reconnect
          }
        } catch (e) {
          developer.log('Error sending ping to verify connection: $e', name: 'SocketService');
          // If error during ping, connection might be stale, so reconnect anyway
          _connected = false;
        }
      }
      
      developer.log('Connecting to socket server: $baseUrl/iot', name: 'SocketService');

      // If socket exists but not connected, disconnect it first to clean up
      if (_socket != null) {
        try {
          _socket!.dispose();  // Properly dispose first
          _socket!.disconnect();
          _socket = null; // Clear the reference
        } catch (e) {
          // Ignore disconnect errors
          developer.log('Error cleaning up old socket: $e', name: 'SocketService');
        }
      }

      // Create fresh socket with optimized settings for reliability
      // Connect directly to the IoT namespace as configured on the server
      developer.log('Creating socket connection to $baseUrl/iot namespace', name: 'SocketService');
      _socket = IO.io('$baseUrl/iot', <String, dynamic>{
        'transports': ['websocket', 'polling'], // Allow fallback to polling if websocket fails
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'reconnectionAttempts': 99999, // Infinite retry attempts
        'forceNew': true, // Always force new on manual connect
        'timeout': 20000, // Reduced timeout for faster failure detection
        'pingTimeout': 30000, // Ping timeout
        'pingInterval': 10000, // More frequent ping interval
        'extraHeaders': {
          'Connection': 'keep-alive',
          'Accept': 'application/json',
          'Cache-Control': 'no-cache'
        },
      });

      _setupListeners();
      
      // Start a periodic connectivity check to maintain connection
      _startPeriodicConnectionCheck();
      
      // Start a keepalive timer to prevent socket from being closed
      _startKeepAliveTimer();
      
      // Force a join to officer channel after connection
      Future.delayed(Duration(seconds: 1), () {
        try {
          if (_connected && _socket != null) {
            _socket!.emit('join_officer_channel', {});
            developer.log('Sent join_officer_channel event after connect', name: 'SocketService');
            // Re-register all existing report callbacks
            _setupReportListener();
          }
        } catch (e) {
          developer.log('Error sending join_officer_channel: $e', name: 'SocketService');
        }
      });

    } catch (e) {
      _connected = false;
      developer.log('Error connecting to socket: $e', name: 'SocketService');
      notifyListeners();
      
      // Retry connection after error with a delay
      Future.delayed(Duration(seconds: 5), () => connect());
    }
  }

  void disconnect() {
    try {
      if (_socket != null) {
        // Only disconnect if explicitly called by the user
        _socket!.disconnect();
        _connected = false;
        developer.log('Socket disconnected manually', name: 'SocketService');
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error disconnecting socket: $e', name: 'SocketService');
    }
  }
  
  // This should be called when the app is paused but we want to maintain connection
  Future<void> keepAliveInBackground() async {
    try {
      developer.log('Keeping socket alive in background', name: 'SocketService');
      
      // First check if we have connectivity before attempting anything
      bool hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        developer.log('No connectivity detected, skipping background connection attempt', name: 'SocketService');
        return;
      }
      
      if (_socket != null) {
        if (!_connected) {
          // Only try to reconnect if we have connectivity
          developer.log('Socket not connected but network available, attempting reconnect in background', name: 'SocketService');
          connect();
        } else {
          // Send a ping to keep the connection alive
          developer.log('Socket connected, sending ping to keep alive', name: 'SocketService');
          try {
            _socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          } catch (e) {
            developer.log('Error sending ping: $e', name: 'SocketService');
          }
        }
      } else if (hasConnectivity) {
        // Socket is null and we have connectivity, try to create a new one
        developer.log('Socket is null with network available, creating new connection', name: 'SocketService');
        connect();
      }
    } catch (e) {
      developer.log('Error keeping socket alive: $e', name: 'SocketService');
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

  void off(String event) {
    try {
      if (_socket != null) {
        _socket!.off(event);
        developer.log('Removed listener for event: $event', name: 'SocketService');
      } else {
        developer.log('Cannot remove listener: socket is null', name: 'SocketService');
      }
    } catch (e) {
      developer.log('Error removing socket event listener: $e', name: 'SocketService');
    }
  }

  void clearAllListeners() {
    try {
      if (_socket != null) {
        _socket!.clearListeners();
        developer.log('Cleared all socket listeners', name: 'SocketService');
      }
      
      // Also clear report callbacks
      clearReportListeners();
    } catch (e) {
      developer.log('Error clearing all socket listeners: $e', name: 'SocketService');
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

  // New method: Add report listener callback
  void addReportListener(Function(Report) callback) {
    _reportCallbacks.add(callback);
    developer.log('Added report listener, total listeners: ${_reportCallbacks.length}', name: 'SocketService');
    
    // Setup the listener if not already done
    _setupReportListener();
  }
  
  // New method: Remove specific report listener callback
  void removeReportListener(Function(Report) callback) {
    _reportCallbacks.remove(callback);
    developer.log('Removed report listener, total listeners: ${_reportCallbacks.length}', name: 'SocketService');
  }
  
  // New method: Clear all report listeners
  void clearReportListeners() {
    _reportCallbacks.clear();
    developer.log('Cleared all report listeners', name: 'SocketService');
  }

  // Setup report listener
  void _setupReportListener() {
    if (_socket == null) {
      connect(); // Make sure socket is connected
      return;
    }
    
    // Setup new_report listener
    on('new_report', (data) {
      try {
        developer.log('Received new_report: $data', name: 'SocketService');

        // Parse data from backend
        final report = Report(
          id: data['id'],
          userId: data['user_id'] ?? 0,
          address: data['address'] ?? 'Alamat tidak diketahui',
          createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
          userName: data['name'] ?? data['reporter_name'] ?? 'Tanpa nama',
          phone: data['phone'] ?? '-',
          jenisLaporan: data['jenis_laporan'] ?? 'Umum',
        );

        developer.log('Parsed report: ID=${report.id}, From=${report.userName}, Type=${report.jenisLaporan}', 
          name: 'SocketService');
          
        // Notify all registered callbacks
        for (var callback in _reportCallbacks) {
          try {
            callback(report);
          } catch (callbackError) {
            developer.log('Error in report callback: $callbackError', name: 'SocketService');
          }
        }
        
        // Acknowledge receipt
        emit('report_received', {
          'report_id': report.id,
          'timestamp': DateTime.now().millisecondsSinceEpoch
        });
      } catch (e) {
        developer.log('Error parsing report data: $e', name: 'SocketService');
      }
    });
    
    // Join the officer channel to receive notifications for officers
    try {
      emit('join_officer_channel', {});
      developer.log('Joined officer channel', name: 'SocketService');
    } catch (e) {
      developer.log('Error joining officer channel: $e', name: 'SocketService');
    }
  }

  // Listen for app resume events and trigger a report refresh
  void listenForAppResume(Function onAppResume) {
    on('app_resumed', (data) {
      try {
        developer.log('Received app_resumed event, triggering refresh', name: 'SocketService');
        onAppResume();
      } catch (e) {
        developer.log('Error handling app_resume event: $e', name: 'SocketService');
      }
    });
  }

  // Legacy method for compatibility - uses the new addReportListener
  void listenForReports(Function(Report) onNewReport) {
    addReportListener(onNewReport);
  }

  // Setup socket listeners
  void _setupListeners() {
    if (_socket == null) return;
    
    _socket!.onConnect((_) {
      _connected = true;
      
      // Safe logging - check if properties exist before accessing
      final socketId = _socket?.id ?? 'unknown';
      developer.log('Socket connected to IoT namespace with ID: $socketId', name: 'SocketService');
      
      // Additional debug info
      try {
        if (_socket != null) {
          final namespace = _socket?.nsp ?? 'unknown';
          developer.log('Socket connected to namespace: $namespace', name: 'SocketService');
          
          // IMPORTANT: Always join the officer channel on every connection/reconnection
          _socket!.emit('join_officer_channel', {});
          developer.log('JOINED OFFICER CHANNEL after connection', name: 'SocketService');
        }
        
        // Setup listeners for events after connection is established
        _setupReportListener();
        
        // After joining, test if we can receive events by sending a ping
        if (_socket != null) {
          _socket!.emit('ping_test', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          developer.log('Sent ping_test to verify connection', name: 'SocketService');
        }
        
        // Schedule a verification of connection in 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          if (_connected && _socket != null) {
            // Re-emit join to ensure we're in the channel
            _socket!.emit('join_officer_channel', {});
            developer.log('Sent follow-up join_officer_channel to ensure connection', name: 'SocketService');
          }
        });
      } catch (e) {
        developer.log('Error in connection handler: $e', name: 'SocketService');
      }
      
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      developer.log('Socket disconnected', name: 'SocketService');
      // Try to reconnect
      _scheduleReconnect();
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
  }

  // Schedule reconnection with exponential backoff
  void _scheduleReconnect() async {
    // Try immediately and also schedule a retry
    try {
      if (!_connected && _socket != null) {
        _socket!.connect();
        developer.log('Attempting immediate reconnection after disconnect', name: 'SocketService');
      }
    } catch (e) {
      developer.log('Error during immediate reconnection: $e', name: 'SocketService');
    }

    // Check connectivity before attempting to reconnect
    if (await _checkConnectivity()) {
      // Schedule another attempt with a delay
      Future.delayed(Duration(seconds: 3), () {
        if (!_connected && _socket != null) {
          developer.log('Attempting delayed reconnection after disconnect', name: 'SocketService');
          try {
            // Create a new socket if previous one is problematic
            _socket!.disconnect();
            _socket = IO.io('$baseUrl/iot', <String, dynamic>{
              'transports': ['websocket', 'polling'], // Try both transports
              'autoConnect': true,
              'reconnection': true,
              'reconnectionDelay': 500, // Faster reconnection
              'reconnectionDelayMax': 3000, // Lower max delay
              'reconnectionAttempts': 999999, // Keep trying forever
              'forceNew': true, // Force a new connection
              'timeout': 30000, // Longer timeout
              'pingTimeout': 60000, // Much longer ping timeout
              'pingInterval': 10000, // More frequent pings
              'extraHeaders': {
                'Connection': 'keep-alive',
                'Keep-Alive': 'timeout=60, max=1000' // More aggressive keep-alive
              }
            });
            
            // Set up the listeners again
            _setupListeners();
            
            // Connect
            _socket!.connect();
          } catch (e) {
            developer.log('Error during reconnection: $e', name: 'SocketService');
            // Try again if still not connected
            if (!_connected) {
              // Schedule another attempt with increasing delay
              Future.delayed(Duration(seconds: 5), () => _scheduleReconnect());
            }
          }
        }
      });
    } else {
      developer.log('No connectivity, skipping reconnection attempt', name: 'SocketService');
    }
  }

  // Start a periodic connection check to maintain socket connectivity
  void _startPeriodicConnectionCheck() {
    // Create a periodic timer that runs every 30 seconds
    Future.delayed(Duration(seconds: 30), () {
      _periodicConnectionCheck();
    });
  }
  
  // Perform a periodic check and schedule the next one
  Future<void> _periodicConnectionCheck() async {
    try {
      developer.log('Running periodic connection check', name: 'SocketService');
      
      // First check connectivity
      bool hasConnectivity = await _checkConnectivity();
      if (!hasConnectivity) {
        developer.log('No connectivity detected in periodic check', name: 'SocketService');
        // Schedule next check with shorter interval since we have no connectivity
        Future.delayed(Duration(seconds: 15), () => _periodicConnectionCheck());
        return;
      }
      
      // Check if socket exists and is connected
      if (_socket == null) {
        developer.log('Socket is null in periodic check, creating new connection', name: 'SocketService');
        connect();
      } else {
        // Test the connection with a ping
        try {
          if (!_connected) {
            developer.log('Socket exists but not connected, reconnecting', name: 'SocketService');
            // Force disconnect before reconnecting to clean up
            try {
              _socket!.disconnect();
              _socket = null;
            } catch (e) {
              developer.log('Error disconnecting stale socket: $e', name: 'SocketService');
            }
            connect();
          } else {
            // Send a ping to verify connection is actually working
            developer.log('Socket appears connected, sending ping to verify', name: 'SocketService');
            
            // Create a flag to track if we get a response
            bool receivedPong = false;
            
            // Listen for pong response
            _socket!.once('pong', (_) {
              receivedPong = true;
              developer.log('Received pong response, connection verified', name: 'SocketService');
            });
            
            // Send ping with timestamp
            _socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
            
            // Check after a delay if we received a response
            Future.delayed(Duration(seconds: 5), () {
              if (!receivedPong) {
                developer.log('No pong received, connection may be stale', name: 'SocketService');
                _connected = false;
                connect(); // Reconnect
              }
            });
          }
        } catch (e) {
          developer.log('Error during connection check: $e', name: 'SocketService');
          // Connection might be stale, reconnect
          _connected = false;
          connect();
        }
      }
      
    } catch (e) {
      developer.log('Error in periodic connection check: $e', name: 'SocketService');
    } finally {
      // Always schedule the next check, regardless of errors
      Future.delayed(Duration(seconds: 20), () => _periodicConnectionCheck());
    }
  }

  // Check if we have connectivity before attempting reconnect
  Future<bool> _checkConnectivity() async {
    try {
      developer.log('Checking connectivity before socket reconnection', name: 'SocketService');
      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasConnectivity = connectivityResult != ConnectivityResult.none;
      developer.log('Connectivity check result: $hasConnectivity (${connectivityResult.toString()})', name: 'SocketService');
      
      // If we have basic connectivity, try to ping our server
      if (hasConnectivity) {
        try {
          // Check server connectivity by HTTP request instead of relying just on device connectivity
          developer.log('Attempting to verify server connectivity', name: 'SocketService');
          // This will be handled by the HTTP client that's part of the socket.io library
          // We don't need to implement an actual HTTP check here
          return true;
        } catch (e) {
          developer.log('Error verifying server connectivity: $e', name: 'SocketService');
          // Still return true if we have basic connectivity
          return true;
        }
      }
      
      return hasConnectivity;
    } catch (e) {
      developer.log('Error checking connectivity: $e', name: 'SocketService');
      return true; // Assume we have connectivity on error
    }
  }
  
  // Start a timer to keep the socket connection alive
  void _startKeepAliveTimer() {
    // Cancel any existing timer
    _keepAliveTimer?.cancel();
    
    // Create a new timer that sends a ping every 8 seconds
    _keepAliveTimer = Timer.periodic(Duration(seconds: 8), (_) {
      if (_connected && _socket != null) {
        try {
          // Send a ping with timestamp to server
          _socket!.emit('ping', {'timestamp': DateTime.now().millisecondsSinceEpoch});
          developer.log('Sent keepalive ping', name: 'SocketService');
        } catch (e) {
          developer.log('Error sending keepalive ping: $e', name: 'SocketService');
          // Try to reconnect on error
          if (!_connected) connect();
        }
      }
    });
    
    developer.log('Started keepalive timer', name: 'SocketService');
  }
}

final socketServiceProvider = ChangeNotifierProvider<SocketService>((ref) {
  // This will be initialized in main.dart
  throw UnimplementedError();
});
