import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../providers/global_refresh_provider.dart';
import '../providers/jenis_laporan_provider.dart';
import '../widgets/gradient_background.dart';
import '../widgets/report_card.dart';
import '../widgets/smart_connection_status_card.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // Add pagination state variables
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  
  // Add filter and sort state variables
  String _selectedRw = '';
  String _selectedRt = '';
  String _selectedStatus = '';
  String _selectedJenisLaporan = '';
  String _sortBy = 'newest'; // 'newest' or 'oldest'
  final TextEditingController _rwController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  bool _showFilters = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load jenis laporan for filtering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadAllReports();
      ref.read(jenisLaporanProvider.notifier).loadJenisLaporan();
    });
  }

  @override
  void dispose() {
    _rwController.dispose();
    _rtController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshReports() async {
    final globalRefresh = ref.read(globalRefreshProvider);
    await globalRefresh();
    // Reset to first page on refresh
    if (mounted) {
      setState(() {
        _currentPage = 0;
      });
    }
  }

  // Get paginated reports
  List<Report> _getPaginatedReports(List<Report> allReports) {
    // Apply filters and sorting first
    List<Report> filteredReports = _applyFiltersAndSort(allReports);
    
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > filteredReports.length
        ? filteredReports.length
        : startIndex + _itemsPerPage;

    return filteredReports.sublist(startIndex, endIndex);
  }

  // Apply filters and sorting with improved regex for RW/RT and jenis laporan filter
  List<Report> _applyFiltersAndSort(List<Report> reports) {
    var filtered = reports.where((report) {
      // RW filter (case insensitive and flexible matching)
      bool rwMatch = true;
      if (_selectedRw.isNotEmpty) {
        final rwPattern = RegExp(r'rw\s*' + RegExp.escape(_selectedRw.trim()), caseSensitive: false);
        rwMatch = rwPattern.hasMatch(report.address);
      }

      // RT filter (case insensitive and flexible matching)
      bool rtMatch = true;
      if (_selectedRt.isNotEmpty) {
        final rtPattern = RegExp(r'rt\s*' + RegExp.escape(_selectedRt.trim()), caseSensitive: false);
        rtMatch = rtPattern.hasMatch(report.address);
      }

      // Status filter
      bool statusMatch = true;
      if (_selectedStatus.isNotEmpty && _selectedStatus != 'semua') {
        final normalizedStatus = _selectedStatus.toLowerCase();
        final reportStatus = report.status.toLowerCase();
        statusMatch = reportStatus == normalizedStatus ||
                     (normalizedStatus == 'menunggu' && reportStatus == 'pending') ||
                     (normalizedStatus == 'diproses' && reportStatus == 'processing') ||
                     (normalizedStatus == 'selesai' && reportStatus == 'completed') ||
                     (normalizedStatus == 'ditolak' && reportStatus == 'rejected');
      }

      // Jenis Laporan filter (case insensitive with "lainnya" category)
      bool jenisMatch = true;
      if (_selectedJenisLaporan.isNotEmpty && _selectedJenisLaporan != 'semua') {
        final jenisLaporanNotifier = ref.read(jenisLaporanProvider.notifier);
        final reportJenisCategory = jenisLaporanNotifier.categorizeJenisLaporan(report.jenisLaporan);
        jenisMatch = reportJenisCategory == _selectedJenisLaporan.toLowerCase();
      }

      return rwMatch && rtMatch && statusMatch && jenisMatch;
    }).toList();

    // Apply sorting
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return filtered;
  }

  // Reset all filters (no more saving to SharedPreferences)
  void _resetFilters() {
    setState(() {
      _selectedRw = '';
      _selectedRt = '';
      _selectedStatus = '';
      _selectedJenisLaporan = '';
      _sortBy = 'newest';
      _currentPage = 0;
      
      // Clear controllers (no longer needed for dropdowns but keep for compatibility)
      _rwController.clear();
      _rtController.clear();
    });
    
    // Auto scroll to top when filters are reset
    _scrollToTop();
  }

  // Calculate total pages
  int _getTotalPages(List<Report> allReports) {
    final filteredReports = _applyFiltersAndSort(allReports);
    return (filteredReports.length / _itemsPerPage).ceil();
  }

  // Navigate to next page
  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      // Auto scroll to top
      _scrollToTop();
    }
  }

  // Navigate to previous page
  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      // Auto scroll to top
      _scrollToTop();
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final reports = reportState.reports;
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final topSafePadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          GradientBackground(
            // Match profile screen colors
            colors: const [
              Color(0xFFEFF6FF),  // Light blue
              Color(0xFFEDE9FE),  // Light purple
              Color(0xFFFDF2F8),  // Light pink
              Color(0xFFF0F9FF),  // Lightest blue
            ],
            child: Column(
              children: [
                // Solid top safe area
                Container(
                  height: topSafePadding,
                  color: const Color(0xFFEFF6FF),
                ),
                // App bar
                _buildAppBar(),
                // Filter section
                _buildFilterSection(),
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshReports,
                    color: const Color(0xFF6366F1),
                    backgroundColor: Colors.white,
                    child: reportState.isLoading
                        ? _buildLoadingState()
                        : reports.isEmpty
                            ? _buildEmptyState()
                            : _buildReportList(reports),
                  ),
                ),
                // Solid bottom safe area
                Container(
                  height: bottomSafePadding,
                  color: const Color(0xFFF0F9FF),
                ),
              ],
            ),
          ),
          // Add SmartConnectionStatusCard for offline mode indication
          const SmartConnectionStatusCard(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Consumer(
      builder: (context, ref, child) {
        final isGlobalRefreshing = ref.watch(globalRefreshStateProvider);
        
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9AA6B2).withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF334155),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Riwayat Laporan',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              // Filter toggle button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showFilters 
                        ? const Color(0xFF6366F1).withAlpha(51)
                        : const Color(0xFF9AA6B2).withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.filter_list,
                    color: _showFilters 
                        ? const Color(0xFF6366F1)
                        : const Color(0xFF334155),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: isGlobalRefreshing ? null : _refreshReports,
                child: Semantics(
                  label: isGlobalRefreshing 
                      ? 'Sedang memuat ulang laporan'
                      : 'Muat ulang laporan',
                  button: true,
                  enabled: !isGlobalRefreshing,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isGlobalRefreshing
                          ? const Color(0xFF9AA6B2).withAlpha(25)
                          : const Color(0xFF9AA6B2).withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: isGlobalRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF334155).withValues(alpha: 0.6),
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: Color(0xFF334155),
                            size: 20,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation
              SizedBox(
                height: 180,
                width: 180,
                child: LottieBuilder.asset(
                  'assets/animations/empty.json', // Using the empty.lottie file
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Lingkungan Aman',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda belum memiliki riwayat laporan.\nLaporan yang Anda kirim akan muncul di sini.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Kembali ke Beranda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(),
      ],
    );
  }

  Widget _buildReportList(List<Report> reports) {
    // Apply filters first to get the actual filtered count
    final filteredReports = _applyFiltersAndSort(reports);
    final totalPages = _getTotalPages(filteredReports);
    final paginatedReports = _getPaginatedReports(filteredReports);

    // Check if any filter is applied (more precise logic)
    final hasFilters = (_selectedStatus.isNotEmpty && _selectedStatus != 'semua') || 
                      (_selectedJenisLaporan.isNotEmpty && _selectedJenisLaporan != 'semua') || 
                      _selectedRw.isNotEmpty || 
                      _selectedRt.isNotEmpty ||
                      _sortBy != 'newest';

    return Column(
      children: [
        // Total count header - use appropriate count
        _buildTotalCountHeader(filteredReports.length, hasFilters),
        
        Expanded(
          child: ListView.builder(
            controller: _scrollController, // Tambahkan scroll controller
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: paginatedReports.length,
            itemBuilder: (context, index) {
              final report = paginatedReports[index];
              return ReportCard(
                report: report,
                onTap: () => context.push('/report-detail/${report.id}'),
              );
            },
          ),
        ),
        // Add pagination controls
        if (filteredReports.length > _itemsPerPage)
          _buildPaginationControls(totalPages),
      ],
    );
  }

  Widget _buildTotalCountHeader(int filteredCount, bool hasFilters) {
    final reportState = ref.watch(reportProvider);
    final globalStats = reportState.globalStats;
    
    // Use globalStats total if no filters are applied, otherwise use filtered count
    final displayCount = !hasFilters && globalStats != null && globalStats['total'] != null
        ? globalStats['total']
        : filteredCount;
    
    final displayText = hasFilters 
        ? '$filteredCount laporan (terfilter)'
        : '$displayCount laporan';
        
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(51),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.assignment_outlined,
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
                  'Total Laporan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withAlpha(204),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayText,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getFilterStatusText(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2);
  }

  String _getFilterStatusText() {
    bool hasFilters = _selectedRw.isNotEmpty || 
                     _selectedRt.isNotEmpty || 
                     (_selectedStatus.isNotEmpty && _selectedStatus != 'semua') || 
                     (_selectedJenisLaporan.isNotEmpty && _selectedJenisLaporan != 'semua');
    
    return hasFilters ? 'Terfilter' : 'Semua';
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          _buildPaginationButton(
            onTap: _currentPage > 0 ? _prevPage : null,
            icon: Icons.chevron_left,
            label: 'Sebelumnya',
          ),

          // Page indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_currentPage + 1}/$totalPages',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          // Next button
          _buildPaginationButton(
            onTap: _currentPage < totalPages - 1 ? () => _nextPage(totalPages) : null,
            icon: Icons.chevron_right,
            label: 'Selanjutnya',
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required VoidCallback? onTap,
    required IconData icon,
    required String label,
  }) {
    final isEnabled = onTap != null;

    return Material(
      color: isEnabled ? Colors.white : Colors.white.withAlpha(128),
      borderRadius: BorderRadius.circular(8),
      elevation: isEnabled ? 2 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isEnabled ? const Color(0xFF6366F1) : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? const Color(0xFF6366F1) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    if (!_showFilters) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RW and RT filters - Modern Dropdown Style
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RW',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 44, // Tinggi yang lebih proporsional
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRw.isEmpty ? '' : _selectedRw,
                        onChanged: (value) {
                          setState(() {
                            _selectedRw = value ?? '';
                            _currentPage = 0;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Pilih RW',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0), // Remove vertical padding untuk center alignment
                        ),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
                        menuMaxHeight: 200,
                        items: _buildRwDropdownItems(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 44, // Tinggi yang lebih proporsional
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedRt.isEmpty ? '' : _selectedRt,
                        onChanged: (value) {
                          setState(() {
                            _selectedRt = value ?? '';
                            _currentPage = 0;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Pilih RT',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
                        menuMaxHeight: 200,
                        items: _buildRtDropdownItems(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Jenis Laporan filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Jenis Laporan',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 44, // Tinggi yang lebih proporsional
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedJenisLaporan.isEmpty ? 'semua' : _selectedJenisLaporan,
                  onChanged: (value) {
                    setState(() {
                      _selectedJenisLaporan = value ?? '';
                      _currentPage = 0;
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                  isExpanded: true,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
                  menuMaxHeight: 200,
                  items: _buildJenisLaporanDropdownItems(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status and Sort filters
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 44, // Tinggi yang lebih proporsional
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus.isEmpty ? 'semua' : _selectedStatus,
                        onChanged: (value) {
                          setState(() {
                            _selectedStatus = value ?? '';
                            _currentPage = 0;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
                        items: [
                          DropdownMenuItem(value: 'semua', child: Text('Semua Status', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'pending', child: Text('Menunggu', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'processing', child: Text('Diproses', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'completed', child: Text('Selesai', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'rejected', child: Text('Ditolak', style: GoogleFonts.inter(fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urutkan',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 44, // Tinggi yang lebih proporsional
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value ?? 'newest';
                            _currentPage = 0;
                          });
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF9CA3AF)),
                        items: [
                          DropdownMenuItem(value: 'newest', child: Text('Terbaru', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'oldest', child: Text('Terlama', style: GoogleFonts.inter(fontSize: 12))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action button - Reset filters only (no save feature)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _resetFilters();
                    setState(() {
                      _showFilters = false; // Close filter popup
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Reset Filter',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3).fadeIn();
  }

  // Build dropdown items for jenis laporan filter
  List<DropdownMenuItem<String>> _buildJenisLaporanDropdownItems() {
    final jenisLaporanState = ref.watch(jenisLaporanProvider);
    
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(
        value: 'semua',
        child: Text('Semua Jenis', style: GoogleFonts.inter(fontSize: 12)),
      ),
    ];
    
    // Add jenis laporan from backend
    for (final jenis in jenisLaporanState.jenisLaporanList) {
      items.add(DropdownMenuItem(
        value: jenis.nama.toLowerCase(),
        child: Text(
          jenis.nama[0].toUpperCase() + jenis.nama.substring(1),
          style: GoogleFonts.inter(fontSize: 12),
        ),
      ));
    }
    
    // Always add "Lainnya" at the end
    items.add(DropdownMenuItem(
      value: 'lainnya',
      child: Text('Lainnya', style: GoogleFonts.inter(fontSize: 12)),
    ));
    
    return items;
  }

  // Build dropdown items for RW filter (14 RW total)
  List<DropdownMenuItem<String>> _buildRwDropdownItems() {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(
        value: '',
        child: Text('Semua RW', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
      ),
    ];
    
    for (int i = 1; i <= 14; i++) {
      final rw = i.toString().padLeft(2, '0'); // Format with leading zero
      items.add(DropdownMenuItem(
        value: rw,
        child: Text('RW $rw', style: GoogleFonts.inter(fontSize: 12)),
      ));
    }
    
    return items;
  }

  // Build dropdown items for RT filter (10 RT total)
  List<DropdownMenuItem<String>> _buildRtDropdownItems() {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(
        value: '',
        child: Text('Semua RT', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
      ),
    ];
    
    for (int i = 1; i <= 10; i++) {
      final rt = i.toString().padLeft(2, '0'); // Format with leading zero
      items.add(DropdownMenuItem(
        value: rt,
        child: Text('RT $rt', style: GoogleFonts.inter(fontSize: 12)),
      ));
    }
    
    return items;
  }

}
