import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/report.dart';
import '../main.dart';
import '../services/notification_service.dart';

class ReportState {
  final List<Report> reports;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? userStats;
  final Map<String, dynamic>? globalStats;
  final Report? selectedReport;
  final bool isLoadingDetail;

  ReportState({
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
    this.userStats,
    this.globalStats,
    this.selectedReport,
    this.isLoadingDetail = false,
  });

  ReportState copyWith({
    List<Report>? reports,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? userStats,
    Map<String, dynamic>? globalStats,
    Report? selectedReport,
    bool? isLoadingDetail,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userStats: userStats ?? this.userStats,
      globalStats: globalStats ?? this.globalStats,
      selectedReport: selectedReport ?? this.selectedReport,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final dynamic _apiService;
  final dynamic _socketService;
  late final NotificationService _notificationService;

  ReportNotifier(this._apiService, this._socketService, Ref ref) 
      : super(ReportState()) {
    _notificationService = ref.read(notificationServiceProvider);
    _listenForReports();
    _listenForAppResume();
    _loadInitialData();
  }

  void _listenForReports() {
    try {
      _socketService.on('new_report', (data) {
        developer.log('New report received via socket: $data', name: 'ReportProvider');
        
        // Parse report data
        try {
          final report = Report(
            id: data['id'],
            userId: 0, // Backend tidak mengirim user_id
            address: data['address'] ?? 'Alamat tidak diketahui',
            createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
            userName: data['name'] ?? 'Tanpa nama',
            jenisLaporan: data['jenis_laporan'] ?? 'Umum',
          );
          
          // Log data for debugging
          developer.log('Processing report: ID=${report.id}, Type=${report.jenisLaporan}', name: 'ReportProvider');
          
          // Multiple attempts to ensure notification is shown, with increasing delays
          // First attempt - immediate
          _notificationService.showNewReportNotification(report);
          
          // Second attempt - short delay
          Future.delayed(Duration(milliseconds: 500), () {
            _notificationService.showNewReportNotification(report);
          });
          
          // Third attempt - longer delay (helps with background notifications)
          Future.delayed(Duration(seconds: 2), () {
            _notificationService.showNewReportNotification(report);
          });
          
          // Force reload reports when we receive a new one via socket
          _retryLoadReports();
          
        } catch (parseError) {
          developer.log('Error parsing socket report data: $parseError', name: 'ReportProvider');
        }
      });
      
      // Re-register for new_report event if socket reconnects
      _socketService.on('connect', (_) {
        developer.log('Socket reconnected, re-registering for new_report events', name: 'ReportProvider');
        
        // Wait a moment for socket to fully initialize before registering listeners
        Future.delayed(Duration(milliseconds: 500), () {
          _listenForReports();
        });
      });
    } catch (e) {
      developer.log('Error setting up socket listener: $e', name: 'ReportProvider');
      
      // Retry listener setup after delay
      Future.delayed(Duration(seconds: 5), () {
        _listenForReports();
      });
    }
  }
  
  // Retry loading reports several times with increasing delays
  void _retryLoadReports() {
    developer.log('Triggering report data refresh sequence', name: 'ReportProvider');
    
    // Immediate attempt
    loadAllReports();
    
    // Additional attempts with varying delays to catch any network issues
    Future.delayed(Duration(milliseconds: 500), () => loadAllReports());
    Future.delayed(Duration(seconds: 2), () => loadAllReports());
    Future.delayed(Duration(seconds: 5), () => loadAllReports());
    Future.delayed(Duration(seconds: 10), () => loadAllReports());
  }

  Future<void> _loadInitialData() async {
    // Immediately load reports on startup - don't wait for user action
    developer.log('Loading initial data automatically', name: 'ReportProvider');
    loadAllReports();
    
    // Also load global stats if needed
    loadGlobalStats();
  }

  void resetState() {
    state = ReportState();
  }

  // Ubah untuk petugas: load semua laporan
  Future<void> loadAllReports() async {
    developer.log('Loading all reports from API', name: 'ReportProvider');
    
    // Only set isLoading if we don't already have reports
    // This prevents UI flicker when refreshing data
    if (state.reports.isEmpty) {
      state = state.copyWith(isLoading: true);
    }
    
    try {
      developer.log('Requesting getAllReports from API service', name: 'ReportProvider');
      final result = await _apiService.getAllReports();
      
      if (result['success']) {
        final newReports = result['reports'] as List<Report>;
        developer.log('Received ${newReports.length} reports from API', name: 'ReportProvider');
        
        // Check if we have new reports compared to current state
        bool hasNewData = _hasNewOrUpdatedReports(state.reports, newReports);
        
        // Update state with new reports
        state = state.copyWith(
          reports: newReports,
          isLoading: false,
          errorMessage: null,
        );
        
        if (hasNewData) {
          developer.log('New or updated report data detected and loaded', name: 'ReportProvider');
        } else {
          developer.log('Reports loaded, no changes detected', name: 'ReportProvider');
        }
      } else {
        developer.log('API returned error: ${result['message']}', name: 'ReportProvider');
        
        // Don't clear existing reports on error, just update error state
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        developer.log('Failed to load all reports: ${result['message']}', name: 'ReportProvider');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading reports: ${e.toString()}',
      );
      developer.log('Error loading all reports: $e', name: 'ReportProvider');
    }
  }

  // Tetap pertahankan untuk kompatibilitas
  Future<void> loadUserReports() async {
    return loadAllReports();
  }

  // Load global stats dari endpoint baru
  Future<void> loadGlobalStats() async {
    developer.log('Loading global stats', name: 'ReportProvider');
    
    try {
      final result = await _apiService.getGlobalReportStats();
      
      if (result['success']) {
        state = state.copyWith(
          globalStats: result['data'],
        );
        developer.log('Global stats loaded successfully', name: 'ReportProvider');
      } else {
        developer.log('Failed to load global stats: ${result['message']}', name: 'ReportProvider');
      }
    } catch (e) {
      developer.log('Error loading global stats: $e', name: 'ReportProvider');
    }
  }

  // Metode baru untuk mendapatkan detail laporan
  Future<void> loadReportDetail(int reportId) async {
    developer.log('Loading report detail for ID: $reportId', name: 'ReportProvider');
    
    // Reset state first and set loading state
    state = state.copyWith(
      selectedReport: null,
      errorMessage: null,
      isLoadingDetail: true
    );
    
    try {
      final result = await _apiService.getReportDetail(reportId);
      
      developer.log('API result received: ${result['success']}', name: 'ReportProvider');
      
      if (result['success']) {
        final report = result['report'] as Report;
        state = state.copyWith(
          selectedReport: report,
          isLoadingDetail: false,
          errorMessage: null,
        );
        developer.log('Report detail loaded successfully: ID=${report.id}, Type=${report.jenisLaporan}', name: 'ReportProvider');
      } else {
        final errorMsg = result['message'] ?? 'Failed to load report detail';
        state = state.copyWith(
          isLoadingDetail: false,
          errorMessage: errorMsg,
        );
        developer.log('Failed to load report detail: $errorMsg', name: 'ReportProvider');
      }
    } catch (e) {
      final errorMsg = 'Error loading report detail: ${e.toString()}';
      state = state.copyWith(
        isLoadingDetail: false,
        errorMessage: errorMsg,
      );
      developer.log('Exception in loadReportDetail: $e', name: 'ReportProvider');
      rethrow; // Re-throw to allow UI to handle the error
    }
  }

  // Mendukung fitur sementara untuk tetap kompatibel
  Future<void> loadUserStats() async {
    // Saat dijalankan oleh petugas, gunakan data global stats
    return loadGlobalStats();
  }

  // Mengirimkan laporan oleh petugas
  Future<bool> sendPetugasReport({
    String? name,
    required String address,
    required String phone,
    required String jenisLaporan,
    String? rwNumber
  }) async {
    developer.log('Petugas mengirim laporan', name: 'ReportProvider');
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      developer.log('Sending officer report with data:', name: 'ReportProvider');
      developer.log('Name: $name', name: 'ReportProvider');
      developer.log('Address: $address', name: 'ReportProvider');
      developer.log('Phone: $phone', name: 'ReportProvider');
      developer.log('Jenis Laporan: $jenisLaporan', name: 'ReportProvider');
      developer.log('RW Number: $rwNumber', name: 'ReportProvider');
      
      final result = await _apiService.sendReport(
        name: name,
        address: address,
        phone: phone,
        jenisLaporan: jenisLaporan,
        rwNumber: rwNumber
      );
      
      if (result['success']) {
        developer.log('Laporan petugas berhasil dikirim', name: 'ReportProvider');
        // Reload reports to include the new one
        await loadAllReports();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Gagal mengirim laporan',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}',
      );
      return false;
    }
  }
  
  // Backwards compatibility method
  Future<bool> sendReport({String? name, String? address, String? phone, String? jenisLaporan, bool useAccountData = true}) async {
    if (address == null || phone == null || jenisLaporan == null) {
      state = state.copyWith(
        errorMessage: 'Data laporan tidak lengkap',
      );
      return false;
    }
    
    return sendPetugasReport(
      name: name,
      address: address,
      phone: phone,
      jenisLaporan: jenisLaporan
    );
  }

  void _listenForAppResume() {
    try {
      _socketService.listenForAppResume(() {
        developer.log('⚡ CRITICAL: App resume detected, immediately reloading reports', name: 'ReportProvider');
        
        // Immediate aggressive reload sequence with multiple attempts
        // This ensures we get fresh data when the app is brought back to foreground
        loadAllReports();
        
        // Schedule multiple reload attempts with increasing delays
        // to account for unstable network conditions when resuming
        Future.delayed(Duration(milliseconds: 300), () => loadAllReports());
        Future.delayed(Duration(milliseconds: 800), () => loadAllReports());
        Future.delayed(Duration(seconds: 2), () => loadAllReports());
        Future.delayed(Duration(seconds: 5), () => loadAllReports());
      });
      
      // Also listen for the global app resumed event from AppLifecycleObserver
      _socketService.on('global:app_resumed', (_) {
        developer.log('Global app resume event received, triggering refresh', name: 'ReportProvider');
        loadAllReports();
      });
    } catch (e) {
      developer.log('Error setting up app resume listener: $e', name: 'ReportProvider');
      
      // Retry setting up the listener after a delay
      Future.delayed(Duration(seconds: 2), () {
        _listenForAppResume();
      });
    }
  }

  // Helper method to check if new reports contain any changes
  bool _hasNewOrUpdatedReports(List<Report> oldReports, List<Report> newReports) {
    // If count differs, we definitely have changes
    if (oldReports.length != newReports.length) {
      developer.log('Report count changed: ${oldReports.length} -> ${newReports.length}', name: 'ReportProvider');
      return true;
    }
    
    // Check if we have any new report IDs
    final oldIds = oldReports.map((r) => r.id).toSet();
    final newIds = newReports.map((r) => r.id).toSet();
    
    // If any ID exists in new but not in old, we have new reports
    if (newIds.any((id) => !oldIds.contains(id))) {
      developer.log('Found new report IDs', name: 'ReportProvider');
      return true;
    }
    
    // Compare timestamps to detect updates
    for (final newReport in newReports) {
      try {
        // Find matching report by ID
        final oldReport = oldReports.firstWhere(
          (r) => r.id == newReport.id,
          // This will throw if not found, which is caught by the try/catch
        );
        
        // Compare timestamps if available
        if (oldReport.createdAt != newReport.createdAt) {
          developer.log('Report ${newReport.id} has updated timestamp', name: 'ReportProvider');
          return true;
        }
      } catch (_) {
        // If we can't find a matching report, it's new
        developer.log('New report detected with ID: ${newReport.id}', name: 'ReportProvider');
        return true;
      }
    }
    
    return false;
  }
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ReportNotifier(apiService, socketService, ref);
});

// Provider for socket connection status
final socketConnectedProvider = Provider<bool>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.isConnected;
});
