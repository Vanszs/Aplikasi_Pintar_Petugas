import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../models/report.dart';
import '../main.dart';

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
  final Ref? _ref;

  ReportNotifier(this._apiService, this._socketService, [this._ref]) 
      : super(ReportState()) {
    _listenForReports();
    _loadInitialData();
  }

  void _listenForReports() {
    try {
      _socketService.on('new_report', (data) {
        developer.log('New report received via socket: $data', name: 'ReportProvider');
        // Force reload reports when we receive a new one via socket
        loadAllReports(); // Changed to loadAllReports for petugas
      });
    } catch (e) {
      developer.log('Error setting up socket listener: $e', name: 'ReportProvider');
    }
  }

  Future<void> _loadInitialData() async {
    // We'll load this data when it's needed, not automatically
  }

  void resetState() {
    state = ReportState();
  }

  // Ubah untuk petugas: load semua laporan
  Future<void> loadAllReports() async {
    developer.log('Loading all reports', name: 'ReportProvider');
    state = state.copyWith(isLoading: true);
    
    try {
      final result = await _apiService.getAllReports();
      
      if (result['success']) {
        state = state.copyWith(
          reports: result['reports'] as List<Report>,
          isLoading: false,
          errorMessage: null,
        );
        developer.log('All reports loaded successfully', name: 'ReportProvider');
      } else {
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
    state = state.copyWith(isLoadingDetail: true);
    
    try {
      final result = await _apiService.getReportDetail(reportId);
      
      if (result['success']) {
        state = state.copyWith(
          selectedReport: result['report'] as Report,
          isLoadingDetail: false,
          errorMessage: null,
        );
        developer.log('Report detail loaded successfully', name: 'ReportProvider');
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
    String? detailLaporan,
    String? rwNumber
  }) async {
    developer.log('Petugas mengirim laporan', name: 'ReportProvider');
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _apiService.sendReport(
        name: name,
        address: address,
        phone: phone,
        jenisLaporan: jenisLaporan,
        detailLaporan: detailLaporan,
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
}

final reportProvider = StateNotifierProvider<ReportNotifier, ReportState>((ref) {
  throw UnimplementedError();
});

// Provider for socket connection status
final socketConnectedProvider = Provider<bool>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  return socketService.isConnected;
});
