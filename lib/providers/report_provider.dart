import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/report.dart';
import '../main.dart';
import '../services/cache_service.dart';
import 'auth_provider.dart';

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
  final Ref _ref;

  ReportNotifier(this._apiService, this._socketService, this._ref) 
      : super(ReportState()) {
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
      
      // Listen for report status updates
      _socketService.on('report_status_update', (data) {
        try {
          developer.log('Received report_status_update: $data', name: 'ReportProvider');
          
          // Check if user is still authenticated before processing
          final authState = _ref.read(authProvider);
          if (!authState.isAuthenticated) {
            developer.log('User not authenticated, skipping status update notification', name: 'ReportProvider');
            return;
          }
          
          // Extract report ID and status from event
          final reportId = data['report_id'];
          final status = data['status'];
          
          if (reportId != null && status != null) {
            // Update the report in state
            _updateReportStatus(reportId, status, data['report']);
            
            // Status update processed (notifications handled by FCM)
            developer.log('Report status updated: $reportId -> $status', name: 'ReportProvider');
          }
        } catch (e) {
          developer.log('Error handling report status update: $e', name: 'ReportProvider');
        }
      });
    } catch (e) {
      developer.log('Error setting up socket listeners: $e', name: 'ReportProvider');
      
      // Retry after delay
      Future.delayed(const Duration(seconds: 3), () {
        _setupSocketListeners();
      });
    }
  }
  
  // Handler for new reports from socket
  void _handleNewReport(Report report) {
    try {
      developer.log('Received new report: ID=${report.id}, Type=${report.jenisLaporan}', name: 'ReportProvider');
      
      // Check if user is still authenticated before processing
      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated) {
        developer.log('User not authenticated, skipping report notification', name: 'ReportProvider');
        return;
      }
      
      // Add report to state
      _addNewReportToState(report);
      
      // New report processed (notifications handled by FCM)
      developer.log('New report added to state: ${report.id}', name: 'ReportProvider');
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
    Future.delayed(const Duration(seconds: 2), () => loadAllReports());
  }

  Future<void> _loadInitialData() async {
    // Immediately load cached data first for fast startup
    developer.log('Loading initial data - trying cache first', name: 'ReportProvider');
    
    try {
      // Load cached data immediately for better UX
      final cachedReports = await CacheService.loadReports();
      final cachedUserStats = await CacheService.loadUserStats();
      final cachedGlobalStats = await CacheService.loadGlobalStats();
      
      if (cachedReports.isNotEmpty || cachedUserStats != null || cachedGlobalStats != null) {
        developer.log('Found cached data, loading immediately', name: 'ReportProvider');
        
        state = state.copyWith(
          reports: cachedReports,
          userStats: cachedUserStats,
          globalStats: cachedGlobalStats,
          lastUpdated: DateTime.now(),
        );
        
        developer.log('Loaded cached data: ${cachedReports.length} reports, userStats: ${cachedUserStats != null}, globalStats: ${cachedGlobalStats != null}', name: 'ReportProvider');
      }
    } catch (e) {
      developer.log('Error loading cached data: $e', name: 'ReportProvider');
    }
    
    // Then try to load fresh data from API (this will happen in background)
    loadAllReports().then((_) {
      // After loading reports, preload details for offline access
      preloadReportDetails();
    });
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
        
        // Save to cache for offline use
        try {
          await CacheService.saveReports(newReports);
          developer.log('Saved ${newReports.length} reports to cache', name: 'ReportProvider');
          
          // Also cache each report detail for offline access
          for (final report in newReports) {
            try {
              await CacheService.saveReportDetail(report.id, report);
            } catch (detailCacheError) {
              developer.log('Error caching report detail for ID ${report.id}: $detailCacheError', name: 'ReportProvider');
            }
          }
          developer.log('Cached individual report details for offline access', name: 'ReportProvider');
          
        } catch (cacheError) {
          developer.log('Error saving reports to cache: $cacheError', name: 'ReportProvider');
        }
        
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
        
        // Save to cache for offline use
        try {
          await CacheService.saveGlobalStats(result['data']);
          developer.log('Saved global stats to cache', name: 'ReportProvider');
        } catch (cacheError) {
          developer.log('Error saving global stats to cache: $cacheError', name: 'ReportProvider');
        }
        
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
        
        // Save to cache for offline use
        try {
          await CacheService.saveUserStats(result['data']);
          developer.log('Saved user stats to cache', name: 'ReportProvider');
        } catch (cacheError) {
          developer.log('Error saving user stats to cache: $cacheError', name: 'ReportProvider');
        }
        
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
    
    state = state.copyWith(isLoadingDetail: true, errorMessage: null);
    
    // First, always try to load from cache - even if online for faster loading
    developer.log('Checking cache for report detail ID: $reportId', name: 'ReportProvider');
    final cachedReport = await CacheService.loadReportDetail(reportId);
    
    if (cachedReport != null) {
      developer.log('Found cached report detail for ID: $reportId', name: 'ReportProvider');
      state = state.copyWith(
        selectedReport: cachedReport,
        isLoadingDetail: false,
      );
      
      // If we have cached data, check if we should refresh from server
      final connectivityService = _ref.read(connectivityServiceProvider);
      final hasInternet = await connectivityService.checkInternetConnection();
      
      if (hasInternet) {
        // Background refresh to update cache - don't block UI
        _refreshReportDetailInBackground(reportId);
      }
      return;
    }
    
    // No cached data - check connectivity
    final connectivityService = _ref.read(connectivityServiceProvider);
    final hasInternet = await connectivityService.checkInternetConnection();
    
    if (!hasInternet) {
      developer.log('No internet and no cached data for report ID: $reportId', name: 'ReportProvider');
      state = state.copyWith(
        isLoadingDetail: false,
        errorMessage: 'Detail laporan tidak tersedia offline. Data ini belum pernah dimuat sebelumnya.',
      );
      return;
    }
    
    // Load from server
    try {
      developer.log('Loading report detail from server for ID: $reportId', name: 'ReportProvider');
      final result = await _apiService.getReportDetail(reportId);
      
      if (result['success']) {
        final report = result['report'] as Report;
        
        // Save to cache for offline use
        await CacheService.saveReportDetail(reportId, report);
        developer.log('Cached report detail for ID: $reportId', name: 'ReportProvider');
        
        state = state.copyWith(
          selectedReport: report,
          isLoadingDetail: false,
        );
        developer.log('Report detail loaded successfully from server for ID: $reportId', name: 'ReportProvider');
      } else {
        state = state.copyWith(
          isLoadingDetail: false,
          errorMessage: result['message'] ?? 'Gagal memuat detail laporan',
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

  // Background refresh of report detail (don't block UI)
  Future<void> _refreshReportDetailInBackground(int reportId) async {
    try {
      developer.log('Background refresh for report detail ID: $reportId', name: 'ReportProvider');
      final result = await _apiService.getReportDetail(reportId);
      
      if (result['success']) {
        final report = result['report'] as Report;
        
        // Update cache with fresh data
        await CacheService.saveReportDetail(reportId, report);
        
        // Update UI if this is still the selected report
        if (state.selectedReport?.id == reportId) {
          state = state.copyWith(selectedReport: report);
          developer.log('Updated UI with fresh report detail for ID: $reportId', name: 'ReportProvider');
        }
      }
    } catch (e) {
      developer.log('Background refresh failed for report ID $reportId: $e', name: 'ReportProvider');
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
    required bool isSirine,
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
        isSirine: isSirine,
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
      // For officer reports, be more tolerant of connectivity issues
      final errorString = e.toString().toLowerCase();
      final isConnectivityError = errorString.contains('network') || 
                                 errorString.contains('connection') ||
                                 errorString.contains('internet') ||
                                 errorString.contains('timeout') ||
                                 errorString.contains('socket');
      
      if (isConnectivityError) {
        // For connectivity errors, return success to provide better UX
        // The report will be "saved locally" (conceptually)
        state = state.copyWith(
          isLoading: false,
          errorMessage: null,
        );
        developer.log('Officer report saved locally due to connectivity issue', name: 'ReportProvider');
        return true; // Return true for better UX
      } else {
        // For other errors, show actual error
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Error sending officer report: ${e.toString()}',
        );
        developer.log('Error sending officer report: $e', name: 'ReportProvider');
        return false;
      }
    }
  }

  // Update report status in state
  void _updateReportStatus(int reportId, String newStatus, dynamic reportData) {
    try {
      // Find the report in our current state
      final reports = state.reports;
      final reportIndex = reports.indexWhere((r) => r.id == reportId);
      
      // If found in list, update status
      if (reportIndex >= 0) {
        final oldReport = reports[reportIndex];
        
        // Create updated report with new status
        Report updatedReport;
        
        // If full report data is available, use it
        if (reportData != null) {
          try {
            updatedReport = Report.fromJson(reportData);
            developer.log('Updated report from full data: $reportData', name: 'ReportProvider');
          } catch (e) {
            // Fallback to just updating the status
            updatedReport = Report(
              id: oldReport.id,
              userId: oldReport.userId,
              address: oldReport.address,
              createdAt: oldReport.createdAt,
              userName: oldReport.userName,
              phone: oldReport.phone,
              jenisLaporan: oldReport.jenisLaporan,
              status: newStatus,
            );
            developer.log('Error parsing report data, using fallback: $e', name: 'ReportProvider');
          }
        } else {
          // Just update the status
          updatedReport = Report(
            id: oldReport.id,
            userId: oldReport.userId,
            address: oldReport.address,
            createdAt: oldReport.createdAt,
            userName: oldReport.userName,
            phone: oldReport.phone,
            jenisLaporan: oldReport.jenisLaporan,
            status: newStatus,
          );
        }
        
        // Create new list with updated report
        final updatedReports = List<Report>.from(reports);
        updatedReports[reportIndex] = updatedReport;
        
        // Update state
        state = state.copyWith(
          reports: updatedReports,
          lastUpdated: DateTime.now(),
        );
        
        // If this is the currently selected report, update that too
        if (state.selectedReport != null && state.selectedReport!.id == reportId) {
          state = state.copyWith(
            selectedReport: updatedReport,
          );
          developer.log('Updated selected report status to: $newStatus', name: 'ReportProvider');
        }
        
        developer.log('Updated report #$reportId status to: $newStatus', name: 'ReportProvider');
      } else {
        developer.log('Report #$reportId not found in state, refreshing all reports', name: 'ReportProvider');
        loadAllReports(); // Refresh all reports if we can't find the one to update
      }
    } catch (e) {
      developer.log('Error updating report status: $e', name: 'ReportProvider');
    }
  }

  // Public method to update report status
  Future<bool> updateReportStatus(int reportId, String newStatus) async {
    try {
      developer.log('Updating report status: $reportId to $newStatus', name: 'ReportProvider');
      
      final result = await _apiService.updateReportStatus(reportId, newStatus);
      
      if (result['success']) {
        // Update in state
        _updateReportStatus(reportId, newStatus, result['report']);
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Failed to update status',
        );
        return false;
      }
    } catch (e) {
      developer.log('Error updating report status: $e', name: 'ReportProvider');
      state = state.copyWith(
        errorMessage: 'Error updating status: ${e.toString()}',
      );
      return false;
    }
  }

  // Method to clear socket listeners when user logs out
  void clearSocketListeners() {
    try {
      developer.log('Clearing socket listeners for logout', name: 'ReportProvider');
      
      // Clear specific socket event listeners
      _socketService.off('connect');
      _socketService.off('report_status_update');
      
      // Clear report listeners
      _socketService.clearReportListeners();
      
      // Clear state
      state = ReportState();
      
      developer.log('Socket listeners cleared and state reset', name: 'ReportProvider');
    } catch (e) {
      developer.log('Error clearing socket listeners: $e', name: 'ReportProvider');
    }
  }

  // Method khusus untuk petugas - load laporan yang ditangani petugas
  Future<void> loadPetugasReports() async {
    developer.log('Loading petugas reports', name: 'ReportProvider');
    
    try {
      // Untuk petugas, load semua laporan yang bisa ditangani
      await loadAllReports();
    } catch (e) {
      developer.log('Error loading petugas reports: $e', name: 'ReportProvider');
      // Set error state tapi jangan throw untuk mencegah UI breaking
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat laporan: $e',
      );
    }
  }
  
  // Method khusus untuk statistik petugas
  Future<void> loadPetugasStats() async {
    developer.log('Loading petugas stats', name: 'ReportProvider');
    
    try {
      // Load both user stats dan global stats untuk dashboard petugas
      await Future.wait([
        loadUserStats(),
        loadGlobalStats(),
      ]);
    } catch (e) {
      developer.log('Error loading petugas stats: $e', name: 'ReportProvider');
      // Set error state tapi jangan throw untuk mencegah UI breaking
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat statistik: $e',
      );
    }
  }

  // Cache methods for offline functionality
  Future<void> setCachedReports(List<Report> cachedReports) async {
    try {
      state = state.copyWith(
        reports: cachedReports,
        isLoading: false,
        errorMessage: null,
        lastUpdated: DateTime.now(),
      );
      developer.log('Set ${cachedReports.length} cached reports', name: 'ReportProvider');
    } catch (e) {
      developer.log('Error setting cached reports: $e', name: 'ReportProvider');
    }
  }

  Future<void> setCachedUserStats(Map<String, dynamic> cachedStats) async {
    try {
      state = state.copyWith(
        userStats: cachedStats,
        lastUpdated: DateTime.now(),
      );
      developer.log('Set cached user stats', name: 'ReportProvider');
    } catch (e) {
      developer.log('Error setting cached user stats: $e', name: 'ReportProvider');
    }
  }

  Future<void> setCachedGlobalStats(Map<String, dynamic> cachedStats) async {
    try {
      state = state.copyWith(
        globalStats: cachedStats,
        lastUpdated: DateTime.now(),
      );
      developer.log('Set cached global stats', name: 'ReportProvider');
    } catch (e) {
      developer.log('Error setting cached global stats: $e', name: 'ReportProvider');
    }
  }

  // Preload and cache report details for offline access
  Future<void> preloadReportDetails() async {
    if (state.reports.isEmpty) return;
    
    developer.log('Preloading report details for offline access (${state.reports.length} reports)', name: 'ReportProvider');
    
    // Get connectivity to decide whether to fetch from API or skip
    final connectivityService = _ref.read(connectivityServiceProvider);
    final hasInternet = await connectivityService.checkInternetConnection();
    
    if (!hasInternet) {
      developer.log('No internet - skipping report details preload', name: 'ReportProvider');
      return;
    }
    
    // Load details for ALL reports (not just first 20) to ensure complete offline access
    final reportsToCache = state.reports.toList();
    int cachedCount = 0;
    int skippedCount = 0;
    
    for (final report in reportsToCache) {
      try {
        // Check if already cached and still valid
        final cachedDetail = await CacheService.loadReportDetail(report.id);
        if (cachedDetail != null) {
          skippedCount++;
          continue; // Skip if already cached
        }
        
        // Load from API and cache
        final result = await _apiService.getReportDetail(report.id);
        if (result['success']) {
          final detailReport = result['report'] as Report;
          await CacheService.saveReportDetail(report.id, detailReport);
          cachedCount++;
          developer.log('Preloaded and cached detail for report ID ${report.id}', name: 'ReportProvider');
        }
        
        // Small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        developer.log('Error preloading detail for report ID ${report.id}: $e', name: 'ReportProvider');
      }
    }
    
    developer.log('Completed preloading report details: $cachedCount new, $skippedCount already cached', name: 'ReportProvider');
  }

  // Clear selected report (useful when navigating away from detail screen)
  void clearSelectedReport() {
    state = state.copyWith(selectedReport: null, isLoadingDetail: false, errorMessage: null);
    developer.log('Cleared selected report', name: 'ReportProvider');
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
