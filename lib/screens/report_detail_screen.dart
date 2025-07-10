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
      
      // Check if report was actually loaded successfully
      final reportState = ref.read(reportProvider);
      if (reportState.errorMessage != null) {
        throw Exception(reportState.errorMessage);
      }
      if (reportState.selectedReport == null) {
        throw Exception('Laporan tidak dapat dimuat. Silakan coba lagi.');
      }
      
      debugPrint('loadReportDetail completed successfully');
    } catch (e) {
      debugPrint('ERROR in loadReportDetail: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat detail: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        // Return to previous screen after delay
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
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
          // Status Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  report.getStatusColor().withOpacity(0.1),
                  report.getStatusColor().withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: report.getStatusColor().withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: report.getStatusColor().withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: report.getStatusColor().withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.assignment_turned_in_rounded,
                        color: report.getStatusColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.getStatusDisplay(),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: report.getStatusColor(),
                            ),
                          ),
                          Text(
                            'Laporan #${report.id}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.formattedDate(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.2),
          
          const SizedBox(height: 20),

          // Laporan Information Section
          _buildSectionTitle('Informasi Laporan'),
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.category_outlined,
                  label: 'Jenis Laporan',
                  value: report.getReportType(),
                  iconColor: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.tag_outlined,
                  label: 'ID Laporan',
                  value: '#${report.id}',
                  iconColor: const Color(0xFF6B7280),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.access_time_outlined,
                  label: 'Tanggal Laporan',
                  value: report.formattedDate(),
                  iconColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.info_outline,
                  label: 'Status',
                  value: report.getStatusDisplay(),
                  iconColor: report.getStatusColor(),
                  valueColor: report.getStatusColor(),
                ),
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 100)).slideY(begin: 0.2),
          
          const SizedBox(height: 24),

          // Lokasi Information Section
          _buildSectionTitle('Lokasi Kejadian'),
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Alamat Lengkap',
                  value: report.address,
                  iconColor: const Color(0xFFEF4444),
                ),
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.2),
          
          const SizedBox(height: 24),

          // Pelapor Information Section
          _buildSectionTitle('Informasi Pelapor'),
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Nama Pelapor',
                  value: report.userName ?? 'Tidak diketahui',
                  iconColor: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  icon: Icons.badge_outlined,
                  label: 'ID Pelapor',
                  value: '#${report.userId}',
                  iconColor: const Color(0xFF6B7280),
                ),
                if (report.phone != null && report.phone != '-') ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: report.phone!,
                    iconColor: const Color(0xFF10B981),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    icon: Icons.phone_disabled_outlined,
                    label: 'Nomor Telepon',
                    value: 'Tidak tersedia',
                    iconColor: const Color(0xFF6B7280),
                    valueColor: const Color(0xFF6B7280),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: const Duration(milliseconds: 300)).slideY(begin: 0.2),
          
          const SizedBox(height: 24),

          // Action Buttons Section
          if (report.phone != null && report.phone != '-')
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _launchWhatsApp(report.phone!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Hubungi via WhatsApp',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          report.phone!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 500)).scale(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _launchWhatsApp(String phone) {
    // Format nomor untuk WhatsApp
    String phoneNumber = phone.trim();
    
    if (phoneNumber.startsWith('+62')) {
      phoneNumber = '62${phoneNumber.substring(3)}';
    } else if (phoneNumber.startsWith('0')) {
      phoneNumber = '62${phoneNumber.substring(1)}';
    } else if (!phoneNumber.startsWith('62')) {
      phoneNumber = '62$phoneNumber';
    }
    
    final whatsappUrl = 'https://wa.me/$phoneNumber';
    final uri = Uri.parse(whatsappUrl);
    
    launchUrl(uri, mode: LaunchMode.externalApplication).then((success) {
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Tidak dapat membuka WhatsApp'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Membuka WhatsApp untuk $phone')),
              ],
            ),
            backgroundColor: const Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    });
  }
}
