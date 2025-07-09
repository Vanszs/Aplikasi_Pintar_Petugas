import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../widgets/gradient_background.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Use Future.microtask to avoid modifying provider during widget build
    Future.microtask(() => _loadReportDetail());
  }

  Future<void> _loadReportDetail() async {
    final reportId = int.tryParse(widget.reportId);
    debugPrint('=== ReportDetailScreen _loadReportDetail ===');
    debugPrint('Parsed reportId: $reportId from widget.reportId: ${widget.reportId}');
    
    if (reportId == null) {
      debugPrint('ERROR: Invalid reportId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID Laporan tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
        context.pop();
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });
    debugPrint('Set _isLoading = true');

    try {
      debugPrint('Calling loadReportDetail with ID: $reportId');
      
      // Add timeout to prevent indefinite loading
      await Future.any([
        ref.read(reportProvider.notifier).loadReportDetail(reportId),
        Future.delayed(const Duration(seconds: 15), () {
          throw TimeoutException('Timeout loading report detail', const Duration(seconds: 15));
        }),
      ]);
      
      debugPrint('loadReportDetail completed');
    } catch (e) {
      debugPrint('ERROR in loadReportDetail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat detail: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Set _isLoading = false');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final report = reportState.selectedReport;
    final isLoading = _isLoading || reportState.isLoadingDetail;
    final errorMessage = reportState.errorMessage;
    
    // Debug logging
    debugPrint('=== ReportDetailScreen build ===');
    debugPrint('ReportDetailScreen build - isLoading: $isLoading');
    debugPrint('ReportDetailScreen build - _isLoading: $_isLoading');
    debugPrint('ReportDetailScreen build - reportState.isLoadingDetail: ${reportState.isLoadingDetail}');
    debugPrint('ReportDetailScreen build - report: ${report?.id}');
    debugPrint('ReportDetailScreen build - errorMessage: $errorMessage');
    if (report != null) {
      debugPrint('ReportDetailScreen build - jenisLaporan: "${report.jenisLaporan}"');
      debugPrint('ReportDetailScreen build - userName: "${report.userName}"');
      debugPrint('ReportDetailScreen build - address: "${report.address}"');
    }
    
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFEFF6FF),  // Light blue
          Color(0xFFEDE9FE),  // Light purple
          Color(0xFFFDF2F8),  // Light pink
          Color(0xFFF0F9FF),  // Lightest blue
        ],
        child: Column(
          children: [
            // Top safe area with solid background
            Container(
              height: topPadding,
              color: const Color(0xFFEFF6FF),
            ),
            
            // Custom app bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Detail Laporan',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Memuat detail laporan...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              _loadReportDetail();
                            },
                            child: Text(
                              'Coba Lagi',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : errorMessage != null
                      ? _buildErrorState(errorMessage)
                      : report != null
                          ? _buildReportDetail(report)
                          : _buildNoDataState(),
            ),
            
            // Bottom safe area
            Container(
              height: bottomPadding,
              color: const Color(0xFFF0F9FF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _loadReportDetail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 16),
          Text(
            'Laporan Tidak Ditemukan',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data laporan tidak ditemukan atau belum dimuat.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _loadReportDetail(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Muat Ulang'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportDetail(Report report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Laporan',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Terkirim',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      report.formattedDate(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          
          const SizedBox(height: 20),
          
          // Report Info
          _buildInfoSection(
            'Detail Laporan',
            [
              _buildInfoRow('Jenis Laporan', report.getReportType()),
              _buildInfoRow('ID Laporan', '#${report.id}'),
              _buildInfoRow('Tanggal', report.formattedDate()),
              _buildInfoRow('Alamat', report.address),
            ],
          ).animate().fadeIn(delay: const Duration(milliseconds: 100)).slideY(begin: 0.2),
          
          const SizedBox(height: 20),
          
          // Reporter Info
          _buildInfoSection(
            'Informasi Pelapor',
            [
              _buildInfoRow('Nama', report.userName ?? 'Tidak diketahui'),
              _buildInfoRow('ID Pelapor', '#${report.userId}'),
              _buildInfoRow('Telepon', (report.phone != null && report.phone != '-') ? report.phone! : 'Tidak tersedia'),
            ],
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.2),
          
          const SizedBox(height: 20),
          
          // Action button - hubungi pelapor via WhatsApp
          Container(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Implementasi hubungi pelapor via WhatsApp
                if (report.phone != null && report.phone != '-') {
                  // Format nomor untuk WhatsApp: pastikan diawali dengan 628
                  String phoneNumber = report.phone!.trim();
                  
                  // Hapus awalan +62 jika ada
                  if (phoneNumber.startsWith('+62')) {
                    phoneNumber = '62${phoneNumber.substring(3)}';
                  } 
                  // Hapus awalan 0 dan ganti dengan 62
                  else if (phoneNumber.startsWith('0')) {
                    phoneNumber = '62${phoneNumber.substring(1)}';
                  }
                  // Jika tidak diawali 62, tambahkan
                  else if (!phoneNumber.startsWith('62')) {
                    phoneNumber = '62$phoneNumber';
                  }
                  
                  // Buka WhatsApp
                  final whatsappUrl = 'https://wa.me/$phoneNumber';
                  debugPrint('Opening WhatsApp with URL: $whatsappUrl');
                  
                  // Buka browser dengan URL WhatsApp
                  Uri uri = Uri.parse(whatsappUrl);
                  
                  // Gunakan try-catch untuk menangani jika tidak bisa membuka WhatsApp
                  try {
                    launchUrl(uri, mode: LaunchMode.externalApplication).then((success) {
                      if (!success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tidak dapat membuka WhatsApp, pastikan aplikasi sudah terpasang'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
                  } catch (e) {
                    debugPrint('Error opening WhatsApp: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terjadi kesalahan saat membuka WhatsApp'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Membuka WhatsApp untuk nomor ${report.phone}'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor telepon tidak tersedia'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.chat),
              label: const Text('Hubungi via WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // Warna WhatsApp
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
