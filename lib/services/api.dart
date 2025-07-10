import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/report.dart';
import '../models/user.dart';
import '../utils/timezone_helper.dart';

class ApiService {
  final String baseUrl;
  String? token;
  String? currentUsername;
  bool? isAdmin;
  String? role;

  ApiService({required this.baseUrl});

  Future<bool> checkServerHealth() async {
    try {
      developer.log('Checking server health', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Server health check failed: $e', name: 'ApiService');
      return false;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      developer.log('Attempting admin login for: $username', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      developer.log('Login response status: ${response.statusCode}', name: 'ApiService');
      developer.log('Login response body: ${response.body}', name: 'ApiService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        token = data['token'];
        currentUsername = username;
        isAdmin = data['is_admin'] ?? false;
        role = data['role'];
        
        // Jika bukan admin, gagalkan login
        if (isAdmin != true) {
          return {
            'success': false,
            'message': 'Akun ini bukan akun petugas',
          };
        }
        
        // Now that we have the token, fetch user profile
        final userProfile = await getUserProfile();
        
        if (userProfile['success']) {
          return {
            'success': true,
            'token': token,
            'user': userProfile['user'],
            'username': username,
          };
        } else {
          return {
            'success': false,
            'message': userProfile['message'] ?? 'Failed to get user profile',
          };
        }
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      // Enhanced error logging
      if (e is http.ClientException) {
        developer.log('HTTP client error: ${e.message}', name: 'ApiService');
      } else {
        developer.log('Login error: $e', name: 'ApiService');
      }
      
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken(String oldToken) async {
    // The API doesn't have refresh token endpoint, tokens don't expire
    // Just check if token is still valid by making a profile request
    try {
      developer.log('Validating token', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No token to validate',
        };
      }
      
      final profileResult = await getUserProfile();
      
      if (profileResult['success']) {
        return {
          'success': true,
          'token': token, // Return the same token since it's still valid
        };
      } else {
        return {
          'success': false,
          'message': 'Token validation failed',
        };
      }
    } catch (e) {
      developer.log('Token validation error: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Error validating token: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      developer.log('Logging out user', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': true,
          'message': 'No active session',
        };
      }
      
      // Call the server's /logout endpoint to invalidate the token
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 5));
      
      // Clear token regardless of response
      token = null;
      currentUsername = null;
      
      if (response.statusCode == 200) {
        developer.log('Logout successful: token blacklisted on server', name: 'ApiService');
        return {
          'success': true,
          'message': 'Logged out successfully',
        };
      } else {
        developer.log('Server-side logout failed: ${response.body}', name: 'ApiService');
        // Still return success since we cleared the local token
        return {
          'success': true,
          'message': 'Logged out locally, but server-side logout failed',
        };
      }
    } catch (e) {
      developer.log('Logout error: $e', name: 'ApiService');
      // Still clear the token on error
      token = null;
      currentUsername = null;
      return {
        'success': true,
        'message': 'Logged out locally due to error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      developer.log('Fetching user profile', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        // Convert server response to User model including admin info
        final user = User(
          id: userData['id'],
          username: userData['username'],
          name: userData['name'],
          address: userData['address'] ?? '-',
          phone: userData['phone'], // Allow null value
          createdAt: DateTime.parse(userData['created_at']),
          isAdmin: userData['is_admin'] ?? false,
          role: userData['role'],
        );
        
        // Store admin status for future use
        isAdmin = userData['is_admin'] ?? false;
        role = userData['role'];
        
        developer.log('User profile fetched successfully', name: 'ApiService');
        return {
          'success': true,
          'user': user,
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to fetch user profile: ${data['error']}', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch profile',
        };
      }
    } catch (e) {
      developer.log('Error fetching user profile: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> sendReport({
    String? name, 
    String? address, 
    String? phone, 
    required String jenisLaporan,
    String? rwNumber,
    bool useAccountData = true,
  }) async {
    try {
      developer.log('Petugas sending report', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      // Create request body based on parameters
      Map<String, dynamic> requestBody = {};
      
      // Validasi field-field wajib
      if (jenisLaporan.isEmpty) {
        return {
          'success': false,
          'message': 'Jenis laporan wajib diisi',
        };
      }
      
      // Validasi berdasarkan useAccountData
      if (!useAccountData) {
        // Jika tidak menggunakan data akun, address dan phone harus disediakan
        if (address == null || address.isEmpty) {
          return {
            'success': false,
            'message': 'Alamat wajib diisi',
          };
        }
        
        if (phone == null || phone.isEmpty) {
          return {
            'success': false,
            'message': 'Nomor telepon wajib diisi',
          };
        }
      }
      
      // Tambahkan field-field ke request body
      requestBody['jenis_laporan'] = jenisLaporan;
      requestBody['use_account_data'] = useAccountData;
      
      // Tambahkan address dan phone jika disediakan (untuk custom data)
      if (address != null && address.isNotEmpty) {
        requestBody['address'] = address;
      }
      
      if (phone != null && phone.isNotEmpty) {
        requestBody['phone'] = phone;
      }
      
      // Set flag untuk laporan petugas
      requestBody['is_officer_report'] = true;
      
      // Tambahkan timestamp Jakarta (UTC+7)
      final timestampData = TimezoneHelper.getTimestampData();
      requestBody.addAll(timestampData);
      
      // Tambahkan field opsional jika tersedia
      if (rwNumber != null && rwNumber.isNotEmpty) {
        requestBody['rw'] = rwNumber;
      }
      
      // Ambil name dari akun jika tidak disediakan
      if (name != null && name.isNotEmpty) {
        requestBody['reporter_name'] = name;
      }
      
      // Log request untuk debugging
      developer.log('Petugas report request: ${requestBody.toString()}', name: 'ApiService');
      
      // Create JSON body and log it
      final body = jsonEncode(requestBody);
      
      // Log the exact request body being sent
      developer.log('Sending petugas report with body: $body', name: 'ApiService');
      
      // Log the exact request body being sent
      developer.log('Sending request to: $baseUrl/report', name: 'ApiService');
      developer.log('Request headers: Authorization: Bearer $token', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/report'), // Use the standard report endpoint for all reports
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 15)); // Increased timeout for slower connections
      
      // Log the response for debugging
      developer.log('Report API response status: ${response.statusCode}', name: 'ApiService');
      developer.log('Report API response body: ${response.body}', name: 'ApiService');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Report sent successfully with response: $data', name: 'ApiService');
        return {
          'success': true,
          'report': data,
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to send report: ${response.statusCode}', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to send report',
        };
      }
    } catch (e) {
      developer.log('Error sending report: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> sendPetugasReport({
    required String name,
    required String address,
    required String phone,
    required String jenisLaporan,
    String? rwNumber,
  }) async {
    try {
      developer.log('Petugas sending report', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      // Create request body
      Map<String, dynamic> requestBody = {
        'reporter_name': name,
        'address': address,
        'phone': phone,
        'jenis_laporan': jenisLaporan,
        'is_officer_report': true,
        'use_account_data': false,
      };
      
      // Tambahkan timestamp Jakarta (UTC+7)
      final timestampData = TimezoneHelper.getTimestampData();
      requestBody.addAll(timestampData);
      
      // Tambahkan RW jika ada
      if (rwNumber != null && rwNumber.isNotEmpty) {
        requestBody['rw'] = rwNumber;
      }
      
      // Log request untuk debugging
      developer.log('Petugas report request: ${requestBody.toString()}', name: 'ApiService');
      
      final body = jsonEncode(requestBody);
      developer.log('Sending petugas report with body: $body', name: 'ApiService');
      
      final response = await http.post(
        Uri.parse('$baseUrl/report'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));
      
      developer.log('Petugas report API response status: ${response.statusCode}', name: 'ApiService');
      developer.log('Petugas report API response body: ${response.body}', name: 'ApiService');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Petugas report sent successfully', name: 'ApiService');
        return {
          'success': true,
          'report': data,
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to send petugas report: ${response.statusCode}', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to send report',
        };
      }
    } catch (e) {
      developer.log('Error sending petugas report: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      developer.log('Fetching user statistics', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/reports/user-stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('User statistics fetched successfully', name: 'ApiService');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to fetch user statistics', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      developer.log('Error fetching user statistics: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserReports() async {
    try {
      developer.log('Fetching user reports', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      // Get current user's username first
      if (currentUsername == null) {
        final profileResult = await getUserProfile();
        if (!profileResult['success']) {
          return {
            'success': false,
            'message': 'Could not determine current user',
          };
        }
        currentUsername = profileResult['user'].username;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/reports/by-username/$currentUsername'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> reportsJson = jsonDecode(response.body);
        final List<Report> reports = reportsJson.map((json) => Report.fromJson(json)).toList();
        
        developer.log('User reports fetched successfully', name: 'ApiService');
        return {
          'success': true,
          'reports': reports,
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to fetch user reports', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch reports',
        };
      }
    } catch (e) {
      developer.log('Error fetching user reports: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    try {
      developer.log('Fetching user by username: $username', name: 'ApiService');

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data),
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch user',
        };
      }
    } catch (e) {
      developer.log('Error fetching user: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserStatsByUsername(String username) async {
    try {
      developer.log('Fetching user stats for $username', name: 'ApiService');

      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/reports/user-stats/$username'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      developer.log('Error fetching user stats: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getGlobalStats() async {
    try {
      developer.log('Fetching global statistics', name: 'ApiService');
      final response = await http.get(
        Uri.parse('$baseUrl/reports/total'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Global stats fetched successfully', name: 'ApiService');
        
        // Convert simpler response format to maintain compatibility with UI
        return {
          'success': true,
          'data': {
            'total_reports': data['total'],
            // Default values for other stats that aren't provided by the new endpoint
            'today_reports': 0,
            'active_users': 0,
            'resolved_reports': 0,
          },
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to fetch global stats, status: ${response.statusCode}', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch global statistics',
        };
      }
    } catch (e) {
      developer.log('Error fetching global stats: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Method baru untuk mendapatkan semua laporan (untuk petugas)
  Future<Map<String, dynamic>> getAllReports() async {
    try {
      developer.log('Fetching all reports', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/reports/all'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List<dynamic> reportsJson = jsonDecode(response.body);
        developer.log('Reports JSON: ${reportsJson.length} reports found', name: 'ApiService');
        // Log sample report data for debugging
        if (reportsJson.isNotEmpty) {
          final sampleReport = reportsJson[0];
          developer.log('Sample report: $sampleReport', name: 'ApiService');
          developer.log('Sample report keys: ${sampleReport.keys.toList()}', name: 'ApiService');
        }
        
        final List<Report> reports = reportsJson.map((json) => Report.fromJson(json)).toList();
        
        developer.log('All reports fetched successfully: ${reports.length} reports', name: 'ApiService');
        return {
          'success': true,
          'reports': reports,
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to fetch all reports: ${response.statusCode}', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch reports',
        };
      }
    } catch (e) {
      developer.log('Error fetching all reports: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  // Method untuk mendapatkan statistik laporan global
  Future<Map<String, dynamic>> getGlobalReportStats() async {
    try {
      developer.log('Fetching global report statistics', name: 'ApiService');
      
      final response = await http.get(
        Uri.parse('$baseUrl/reports/count'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Global statistics fetched successfully: $data', name: 'ApiService');
        
        // Ensure we have the expected data structure for the UI
        return {
          'success': true,
          'data': {
            'total': data['total'] ?? 0,
            'today': data['today'] ?? 0
          },
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to fetch global statistics', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to fetch statistics',
        };
      }
    } catch (e) {
      developer.log('Error fetching global statistics: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  // Method untuk mendapatkan detail laporan berdasarkan ID dari endpoint /reports/:id
  Future<Map<String, dynamic>> getReportDetail(int reportId) async {
    try {
      developer.log('Fetching report detail for ID: $reportId', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      // Endpoint untuk detail laporan adalah /reports/:id
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
      
      developer.log('Report detail response status: ${response.statusCode}', name: 'ApiService');
      developer.log('Report detail response body: ${response.body}', name: 'ApiService');
      
      if (response.statusCode == 200) {
        try {
          final reportJson = jsonDecode(response.body);
          developer.log('Report JSON: $reportJson', name: 'ApiService');
          developer.log('Report JSON keys: ${reportJson.keys.toList()}', name: 'ApiService');
          
          // Debug detail_laporan specifically
          if (reportJson.containsKey('detail_laporan')) {
            developer.log('detail_laporan exists: ${reportJson['detail_laporan']}', name: 'ApiService');
            developer.log('detail_laporan type: ${reportJson['detail_laporan'].runtimeType}', name: 'ApiService');
            developer.log('detail_laporan is null: ${reportJson['detail_laporan'] == null}', name: 'ApiService');
            developer.log('detail_laporan is empty: ${reportJson['detail_laporan'] == ""}', name: 'ApiService');
          } else {
            developer.log('detail_laporan key does NOT exist', name: 'ApiService');
          }
          
          final report = Report.fromJson(reportJson);
          
          developer.log('Report created with status: ${reportJson['status'] ?? 'pending'}', name: 'ApiService');
          
          developer.log('Report detail fetched successfully for ID: $reportId', name: 'ApiService');
          
          // Return report and user details if available
          return {
            'success': true,
            'report': report,
            'user_details': reportJson['user_details'] ?? {},
          };
        } catch (parseError) {
          developer.log('Error parsing report detail: $parseError', name: 'ApiService');
          return {
            'success': false,
            'message': 'Error parsing report data: ${parseError.toString()}',
          };
        }
      } else {
        final errorMessage = response.body.isNotEmpty 
            ? jsonDecode(response.body)['error'] ?? 'Failed to fetch report detail'
            : 'Failed to fetch report detail';
            
        developer.log('Failed to fetch report detail for ID: $reportId, status: ${response.statusCode}', name: 'ApiService');
        developer.log('Error response: ${response.body}', name: 'ApiService');
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      developer.log('Error fetching report detail: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // Method untuk mendapatkan detail laporan berdasarkan ID yang beradaptasi dengan struktur server
  Future<Map<String, dynamic>> getReportWithRetry(int reportId) async {
    try {
      // First, try the standard report detail endpoint
      final result = await getReportDetail(reportId);
      
      if (result['success']) {
        return result;
      }
      
      // If standard endpoint fails, try the all reports endpoint and find by ID
      developer.log('First attempt failed, trying alternate method', name: 'ApiService');
      final allReports = await getAllReports();
      
      if (allReports['success'] && allReports['reports'] != null) {
        final reportsList = allReports['reports'] as List<dynamic>;
        final reports = reportsList.cast<Report>();
        final matchingReport = reports.where((r) => r.id == reportId).toList();
        
        if (matchingReport.isNotEmpty) {
          developer.log('Found report in all reports: ${matchingReport.first.id}', name: 'ApiService');
          return {
            'success': true,
            'report': matchingReport.first
          };
        }
      }
      
      return {
        'success': false,
        'message': 'Report not found after multiple attempts'
      };
    } catch (e) {
      developer.log('Error in getReportWithRetry: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> registerFcmToken(String fcmToken) async {
    try {
      developer.log('Registering FCM token', name: 'ApiService');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token',
        };
      }
      
      if (fcmToken.isEmpty) {
        return {
          'success': false,
          'message': 'FCM token is required',
        };
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/admin/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
        }),
      ).timeout(const Duration(seconds: 10));
      
      developer.log('FCM token registration response status: ${response.statusCode}', name: 'ApiService');
      developer.log('FCM token registration response body: ${response.body}', name: 'ApiService');
      
      if (response.statusCode == 200) {
        developer.log('FCM token registered successfully', name: 'ApiService');
        return {
          'success': true,
          'message': 'FCM token registered successfully',
        };
      } else {
        final data = jsonDecode(response.body);
        developer.log('Failed to register FCM token: ${data['error']}', name: 'ApiService');
        return {
          'success': false,
          'message': data['error'] ?? 'Failed to register FCM token',
        };
      }
    } catch (e) {
      developer.log('Error registering FCM token: $e', name: 'ApiService');
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  void clearSession() {
    token = null;
    currentUsername = null;
    developer.log('Session cleared', name: 'ApiService');
  }
}
