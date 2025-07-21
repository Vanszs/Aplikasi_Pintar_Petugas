import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/gradient_background.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  String? _selectedStatus;

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
      
      // Clear any previous error messages
      ref.read(reportProvider.notifier).clearErrorMessage();
      
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
            duration: const Duration(seconds: 3),
          ),
        );
        // Return to previous screen after delay
        Future.delayed(const Duration(seconds: 2), () {
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

  Future<void> _updateReportStatus(int reportId, String newStatus) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final result = await ref.read(reportProvider.notifier).updateReportStatus(reportId, newStatus);
      
      if (result && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Status laporan berhasil diperbarui'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        // Clear any previous error message and reload report detail to get the updated data
        ref.read(reportProvider.notifier).clearErrorMessage();
        await _loadReportDetail();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Gagal memperbarui status laporan'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  void _showStatusUpdateDialog(Report report) {
    final statusOptions = [
      {'value': 'pending', 'display': 'Menunggu', 'color': const Color(0xFFF59E0B), 'icon': Icons.schedule},
      {'value': 'processing', 'display': 'Diproses', 'color': const Color(0xFF3B82F6), 'icon': Icons.sync},
      {'value': 'completed', 'display': 'Selesai', 'color': const Color(0xFF10B981), 'icon': Icons.check_circle},
      {'value': 'rejected', 'display': 'Ditolak', 'color': const Color(0xFFEF4444), 'icon': Icons.cancel},
    ];

    setState(() {
      _selectedStatus = report.status;
    });

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: FadeTransition(
            opacity: animation,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(20),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with gradient
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ubah Status Laporan',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      'Laporan #${report.id}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withAlpha(204),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Status Baru:',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Status options with modern design
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  children: statusOptions.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final option = entry.value;
                                    final isSelected = _selectedStatus == option['value'];
                                    final isFirst = index == 0;
                                    final isLast = index == statusOptions.length - 1;
                                    
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() {
                                              _selectedStatus = option['value'] as String;
                                            });
                                          },
                                          borderRadius: BorderRadius.only(
                                            topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                                            topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                                            bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                            bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? (option['color'] as Color).withAlpha(25)
                                                  : Colors.transparent,
                                              border: Border(
                                                bottom: isLast 
                                                    ? BorderSide.none 
                                                    : BorderSide(color: const Color(0xFFE5E7EB)),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Custom radio button with icon
                                                AnimatedContainer(
                                                  duration: const Duration(milliseconds: 200),
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isSelected 
                                                        ? (option['color'] as Color)
                                                        : Colors.transparent,
                                                    border: Border.all(
                                                      color: isSelected 
                                                          ? (option['color'] as Color)
                                                          : const Color(0xFFD1D5DB),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 14,
                                                          color: Colors.white,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // Status icon
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: (option['color'] as Color).withAlpha(25),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Icon(
                                                    option['icon'] as IconData,
                                                    size: 20,
                                                    color: option['color'] as Color,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                
                                                // Status text
                                                Expanded(
                                                  child: Text(
                                                    option['display'] as String,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 16,
                                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                      color: isSelected 
                                                          ? (option['color'] as Color)
                                                          : const Color(0xFF374151),
                                                    ),
                                                  ),
                                                ),
                                                
                                                // Selection indicator
                                                if (isSelected)
                                                  Container(
                                                    width: 4,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: option['color'] as Color,
                                                      borderRadius: BorderRadius.circular(2),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                                    ),
                                  ),
                                  child: Text(
                                    'Batal',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _selectedStatus != null && _selectedStatus != report.status
                                      ? () {
                                          Navigator.of(context).pop();
                                          _updateReportStatus(report.id, _selectedStatus!);
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                                    disabledForegroundColor: const Color(0xFF9CA3AF),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Simpan Perubahan',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final authState = ref.watch(authProvider);
    final report = reportState.selectedReport;
    final isLoading = _isLoading || reportState.isLoadingDetail;
    final errorMessage = reportState.errorMessage;
    final isAdmin = authState.user?.isAdmin == true;
    
    // Debug logging
    debugPrint('=== ReportDetailScreen build ===');
    debugPrint('ReportDetailScreen build - isLoading: $isLoading');
    debugPrint('ReportDetailScreen build - _isLoading: $_isLoading');
    debugPrint('ReportDetailScreen build - reportState.isLoadingDetail: ${reportState.isLoadingDetail}');
    debugPrint('ReportDetailScreen build - report: ${report?.id}');
    debugPrint('ReportDetailScreen build - errorMessage: $errorMessage');
    debugPrint('ReportDetailScreen build - isAdmin: $isAdmin');
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
                            color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                          ? _buildReportDetail(report, isAdmin)
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

  Widget _buildReportDetail(Report report, bool isAdmin) {
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
                  report.getStatusColor().withAlpha(26),
                  report.getStatusColor().withAlpha(13),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: report.getStatusColor().withAlpha(51),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: report.getStatusColor().withAlpha(26),
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
                        color: report.getStatusColor().withAlpha(38),
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
                        color: Colors.white.withAlpha(204),
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
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailRow(
                        icon: Icons.info_outline,
                        label: 'Status',
                        value: report.getStatusDisplay(),
                        iconColor: report.getStatusColor(),
                        valueColor: report.getStatusColor(),
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isUpdatingStatus ? null : () => _showStatusUpdateDialog(report),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withAlpha(51),
                                width: 1,
                              ),
                            ),
                            child: _isUpdatingStatus
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  )
                                : const Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: Color(0xFF3B82F6),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ],
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
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                  color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                    color: const Color(0xFF25D366).withAlpha(77),
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
                            color: Colors.white.withAlpha(230),
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
            color: iconColor.withAlpha(26),
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
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
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

  @override
  void dispose() {
    // Clear selected report when navigating away to free memory and ensure fresh loading next time
    ref.read(reportProvider.notifier).clearSelectedReport();
    super.dispose();
  }
}
