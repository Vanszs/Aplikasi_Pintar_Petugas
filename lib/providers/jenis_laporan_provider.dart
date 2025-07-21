import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;
import '../services/api.dart';
import '../main.dart';

// Model untuk jenis laporan
class JenisLaporan {
  final int id;
  final String nama;

  JenisLaporan({
    required this.id,
    required this.nama,
  });

  factory JenisLaporan.fromJson(Map<String, dynamic> json) {
    return JenisLaporan(
      id: json['id'],
      nama: json['nama'],
    );
  }
}

// State untuk jenis laporan
class JenisLaporanState {
  final List<JenisLaporan> jenisLaporanList;
  final bool isLoading;
  final String? errorMessage;

  JenisLaporanState({
    this.jenisLaporanList = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  JenisLaporanState copyWith({
    List<JenisLaporan>? jenisLaporanList,
    bool? isLoading,
    String? errorMessage,
  }) {
    return JenisLaporanState(
      jenisLaporanList: jenisLaporanList ?? this.jenisLaporanList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Provider untuk jenis laporan
class JenisLaporanNotifier extends StateNotifier<JenisLaporanState> {
  final ApiService _apiService;

  JenisLaporanNotifier(this._apiService) : super(JenisLaporanState());

  // Load jenis laporan dari backend
  Future<void> loadJenisLaporan() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _apiService.getJenisLaporan();
      
      if (result['success']) {
        final List<dynamic> data = result['data'];
        final jenisLaporanList = data.map((item) => JenisLaporan.fromJson(item)).toList();
        
        state = state.copyWith(
          jenisLaporanList: jenisLaporanList,
          isLoading: false,
        );
        
        developer.log('Loaded ${jenisLaporanList.length} jenis laporan', name: 'JenisLaporanNotifier');
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'],
        );
        developer.log('Failed to load jenis laporan: ${result['message']}', name: 'JenisLaporanNotifier');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading jenis laporan: ${e.toString()}',
      );
      developer.log('Error loading jenis laporan: $e', name: 'JenisLaporanNotifier');
    }
  }

  // Get list dengan format string untuk dropdown (dengan "Lainnya" di akhir)
  List<String> getJenisLaporanOptions() {
    final options = state.jenisLaporanList.map((item) => item.nama.toLowerCase()).toList();
    if (!options.contains('lainnya')) {
      options.add('lainnya');
    }
    return options;
  }

  // Check if jenis laporan exists in master data (case insensitive)
  bool isJenisLaporanValid(String jenisLaporan) {
    final normalizedInput = jenisLaporan.toLowerCase().trim();
    return state.jenisLaporanList.any((item) => 
      item.nama.toLowerCase() == normalizedInput
    );
  }

  // Categorize jenis laporan for filtering
  String categorizeJenisLaporan(String? jenisLaporan) {
    if (jenisLaporan == null || jenisLaporan.isEmpty) {
      return 'lainnya';
    }
    
    final normalizedInput = jenisLaporan.toLowerCase().trim();
    
    // Check if it exists in master data
    for (final item in state.jenisLaporanList) {
      if (item.nama.toLowerCase() == normalizedInput) {
        return item.nama.toLowerCase();
      }
    }
    
    // If not found in master data, categorize as "lainnya"
    return 'lainnya';
  }
}

final jenisLaporanProvider = StateNotifierProvider<JenisLaporanNotifier, JenisLaporanState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return JenisLaporanNotifier(apiService);
});
