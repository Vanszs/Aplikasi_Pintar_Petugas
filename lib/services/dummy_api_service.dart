import 'dart:developer' as developer;
import '../models/user.dart';
import '../models/report.dart';

class DummyApiService {
  final String baseUrl;
  String? token;
  String? currentUsername;

  // Dummy user data
  static final User _dummyUser = User(
    id: 1,
    username: 'test',
    name: 'Test User Demo',
    address: 'Jl. Kelurahan Demo No. 123, Jakarta Selatan',
    createdAt: DateTime(2024, 1, 15),
  );

  // Dummy reports data
  static final List<Report> _dummyReports = [
    Report(
      id: 1,
      userId: 1,
      address: 'Jl. Kelurahan Demo No. 123, Jakarta Selatan',
      createdAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)).add(const Duration(hours: 7)),
      userName: 'Test User Demo',
    ),
    Report(
      id: 2,
      userId: 1,
      address: 'Jl. Sukajadi No. 45, Jakarta Selatan',
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)).add(const Duration(hours: 7)),
      userName: 'Test User Demo',
    ),
    Report(
      id: 3,
      userId: 1,
      address: 'Jl. Merdeka No. 67, Jakarta Selatan',
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 3)).add(const Duration(hours: 7)),
      userName: 'Test User Demo',
    ),
    Report(
      id: 4,
      userId: 1,
      address: 'Jl. Pahlawan No. 89, Jakarta Selatan',
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 5)).add(const Duration(hours: 7)),
      userName: 'Test User Demo',
    ),
    Report(
      id: 5,
      userId: 1,
      address: 'Jl. Veteran No. 12, Jakarta Selatan',
      createdAt: DateTime.now().toUtc().subtract(const Duration(days: 7)).add(const Duration(hours: 7)),
      userName: 'Test User Demo',
    ),
  ];

  DummyApiService({required this.baseUrl});

  Future<bool> checkServerHealth() async {
    developer.log('Dummy: Checking server health', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return true; // Always healthy in dummy mode
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    developer.log('Dummy: Login attempt for $username', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay

    // Check dummy credentials
    if (username == 'test' && password == 'test') {
      token = 'dummy_token_${DateTime.now().millisecondsSinceEpoch}';
      currentUsername = username;
      
      developer.log('Dummy: Login successful', name: 'DummyApiService');
      return {
        'success': true,
        'token': token,
        'user': _dummyUser,
        'username': username,
      };
    } else {
      developer.log('Dummy: Login failed - invalid credentials', name: 'DummyApiService');
      return {
        'success': false,
        'message': 'Username atau password salah',
      };
    }
  }

  Future<Map<String, dynamic>> sendReport() async {
    developer.log('Dummy: Sending report (disabled in demo mode)', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Always fail in dummy mode to show it's disabled
    return {
      'success': false,
      'message': 'Fitur laporan dinonaktifkan dalam mode demo',
    };
  }

  Future<Map<String, dynamic>> getUserStats() async {
    developer.log('Dummy: Fetching user stats', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 300));
    
    final today = DateTime.now();
    final todayReports = _dummyReports.where((report) {
      return report.createdAt.year == today.year &&
          report.createdAt.month == today.month &&
          report.createdAt.day == today.day;
    }).length;

    return {
      'success': true,
      'data': {
        'reports': {
          'total': _dummyReports.length,
          'today': todayReports,
          'this_week': _dummyReports.where((r) => 
            DateTime.now().difference(r.createdAt).inDays <= 7).length,
          'this_month': _dummyReports.where((r) => 
            DateTime.now().difference(r.createdAt).inDays <= 30).length,
        }
      },
    };
  }

  Future<Map<String, dynamic>> getUserReports() async {
    developer.log('Dummy: Fetching user reports', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 400));
    
    return {
      'success': true,
      'reports': List<Report>.from(_dummyReports),
    };
  }

  Future<Map<String, dynamic>> getGlobalStats() async {
    developer.log('Dummy: Fetching global stats', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 300));
    
    return {
      'success': true,
      'data': {
        'total_reports': 47,  // Keep this for compatibility
        // These fields are no longer provided by the API but maintained for UI compatibility
        'today_reports': 0,
        'active_users': 0, 
        'resolved_reports': 0,
      },
    };
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    developer.log('Dummy: Fetching user profile', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Tidak ada token autentikasi',
      };
    }

    return {
      'success': true,
      'user': _dummyUser,
    };
  }

  Future<Map<String, dynamic>> refreshToken(String oldToken) async {
    developer.log('Dummy: Refreshing token', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    // In dummy mode, always succeed with a new token
    token = 'dummy_token_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'success': true,
      'token': token,
    };
  }

  Future<Map<String, dynamic>> logout() async {
    developer.log('Dummy: Logging out user', name: 'DummyApiService');
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    
    token = null;
    currentUsername = null;
    
    return {
      'success': true,
      'message': 'Dummy logout successful',
    };
  }

  void clearSession() {
    token = null;
    currentUsername = null;
    developer.log('Dummy: Session cleared', name: 'DummyApiService');
  }
}
