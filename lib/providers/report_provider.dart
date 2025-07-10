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
  final DateTime? lastUpdated; // Track when the data was last updated

  ReportState({
    this.reports = const [],
    this.isLoading = false,
    this.errorMessage,
    this.userStats,
    this.globalStats,
    this.selectedReport,
    this.isLoadingDetail = false,
    this.lastUpdated,
  });

  ReportState copyWith({
    List<Report>? reports,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? userStats,
    Map<String, dynamic>? globalStats,
    Report? selectedReport,
    bool? isLoadingDetail,
    DateTime? lastUpdated,
  }) {
    return ReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      userStats: userStats ?? this.userStats,
      globalStats: globalStats ?? this.globalStats,
      selectedReport: selectedReport ?? this.selectedReport,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ReportNotifier extends StateNotifier<ReportState> {
  final dynamic _apiService;
  final dynamic _socketService;
  late final NotificationService _notificationService;
  final Ref _ref;

  ReportNotifier(this._apiService, this._socketService, this._ref) 
      : super(ReportState()) {
    _notificationService = _ref.read(notificationServiceProvider);
    _setupSocketListeners();
    _listenForAppResume();
    _loadInitialData();
  }

  void _setupSocketListeners() {
    try {
      // Use the improved callback system in socket_service
      _socketService.addReportListener(_handleNewReport);
      
      // Also listen for reconnection events
      _socketService.on('connect', (_) {
        developer.log('Socket reconnected, refreshing data', name: 'ReportProvider');
        // Reload reports on reconnection
        loadAllReports();
      });
    } catch (e) {
      developer.log('Error setting up socket listeners: $e', name: 'ReportProvider');
      
      // Retry after delay
      Future.delayed(Duration(seconds: 3), () {
        _setupSocketListeners();
      });
    }
  }
  
  // Handler for new reports from socket
  void _handleNewReport(Report report) {
    try {
      developer.log('Received new report: ID=${report.id}, Type=${report.jenisLaporan}', name: 'ReportProvider');
      
      // Add report to state
      _addNewReportToState(report);
      
      // Show notification
      _notificationService.showNewReportNotification(report);
    } catch (e) {
      developer.log('Error handling new report: $e', name: 'ReportProvider');
    }
  }
  
  // Listen for app resume events
  void _listenForAppResume() {
    try {
      _socketService.listenForAppResume(() {
        developer.log('App resumed, refreshing report data', name: 'ReportProvider');
        loadAllReports();
      });
    } catch (e) {
      developer.log('Error setting up app resume listener: $e', name: 'ReportProvider');
    }
  }
  
  // Add new report to state without reloading everything
  void _addNewReportToState(Report newReport) {
    try {
      // Check if report already exists in state
      final existingIndex = state.reports.indexWhere((r) => r.id == newReport.id);
      
      if (existingIndex >= 0) {
        // Update existing report if it exists
        final updatedReports = List<Report>.from(state.reports);
        updatedReports[existingIndex] = newReport;
        
        state = state.copyWith(
          reports: updatedReports,
          lastUpdated: DateTime.now(),
        );
        developer.log('Updated existing report in state: ID=${newReport.id}', name: 'ReportProvider');
      } else {
        // Add new report to the beginning of the list
        final updatedReports = [newReport, ...state.reports];
        
        state = state.copyWith(
          reports: updatedReports,
          lastUpdated: DateTime.now(),
        );
        developer.log('Added new report to state: ID=${newReport.id}', name: 'ReportProvider');
      }
    } catch (e) {
      developer.log('Error adding new report to state: $e', name: 'ReportProvider');
      // Fall back to full reload if direct update fails
      loadAllReports();
    }
  }
  
  // Retry loading reports with delay to ensure data is refreshed
  Future<void> retryLoadReports() async {
    developer.log('Triggering report data refresh sequence', name: 'ReportProvider');
    
    // Immediate attempt
    await loadAllReports();
    
    // Additional attempt with delay to catch any network issues
    Future.delayed(Duration(seconds: 2), () => loadAllReports());
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

  // Load all reports for the officer
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
        bool hasNewData = state.reports.length != newReports.length;
        
        // Update state with new reports
        state = state.copyWith(
          reports: newReports,
          isLoading: false,
          errorMessage: null,
          lastUpdated: DateTime.now(),
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

  // Load user stats
  Future<void> loadUserStats() async {
    developer.log('Loading user stats', name: 'ReportProvider');
    
    try {
      final result = await _apiService.getUserStats();
      
      if (result['success']) {
        state = state.copyWith(
          userStats: result['data'],
        );
        developer.log('User stats loaded successfully', name: 'ReportProvider');
      } else {
        developer.log('Failed to load user stats: ${result['message']}', name: 'ReportProvider');
      }
    } catch (e) {
      developer.log('Error loading user stats: $e', name: 'ReportProvider');
    }
  }

  // Load a specific report by ID
  Future<void> loadReportById(int reportId) async {
    developer.log('Loading report detail for ID: $reportId', name: 'ReportProvider');
    
    state = state.copyWith(isLoadingDetail: true);
    
    try {
      final result = await _apiService.getReportById(reportId);
      
      if (result['success']) {
        state = state.copyWith(
          selectedReport: result['report'],
          isLoadingDetail: false,
        );
        developer.log('Report detail loaded successfully for ID: $reportId', name: 'ReportProvider');
      } else {
        state = state.copyWith(
          isLoadingDetail: false,
          errorMessage: result['message'],
        );
        developer.log('Failed to load report detail: ${result['message']}', name: 'ReportProvider');
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingDetail: false,
        errorMessage: 'Error loading report detail: ${e.toString()}',
      );
      developer.log('Error loading report detail: $e', name: 'ReportProvider');
    }
  }

  // Alias for loadReportById to maintain compatibility with existing code
  Future<void> loadReportDetail(int reportId) async {
    return loadReportById(reportId);
  }

  // Send a new report from user
  Future<bool> sendReport({
    required String jenisLaporan,
    String? address,
    String? phone,
    String? rwNumber,
    bool useAccountData = true,
  }) async {
    developer.log('Sending new user report: $jenisLaporan', name: 'ReportProvider');
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _apiService.sendReport(
        jenisLaporan: jenisLaporan,
        address: address,
        phone: phone,
        rwNumber: rwNumber,
        useAccountData: useAccountData,
      );
      
      if (result['success']) {
        // Refresh reports to show the newly added one
        loadAllReports();
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
        developer.log('Report sent successfully', name: 'ReportProvider');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to send report',
        );
        developer.log('Failed to send report: ${result['message']}', name: 'ReportProvider');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error sending report: ${e.toString()}',
      );
      developer.log('Error sending report: $e', name: 'ReportProvider');
      return false;
    }
  }

  // Send a new report from officer
  Future<bool> sendPetugasReport({
    required String name,
    required String address,
    required String phone,
    required String jenisLaporan,
    required String rwNumber,
  }) async {
    developer.log('Sending new officer report: $jenisLaporan', name: 'ReportProvider');
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _apiService.sendPetugasReport(
        name: name,
        address: address,
        phone: phone,
        jenisLaporan: jenisLaporan,
        rwNumber: rwNumber,
      );
      
      if (result['success']) {
        // Refresh reports to show the newly added one
        loadAllReports();
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
        developer.log('Officer report sent successfully', name: 'ReportProvider');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Failed to send officer report',
        );
        developer.log('Failed to send officer report: ${result['message']}', name: 'ReportProvider');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error sending officer report: ${e.toString()}',
      );
      developer.log('Error sending officer report: $e', name: 'ReportProvider');
      return false;
    }
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
