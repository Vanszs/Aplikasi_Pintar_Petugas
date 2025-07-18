import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report.dart';
import '../providers/report_provider.dart';
import '../providers/global_refresh_provider.dart';
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
  String _sortBy = 'newest'; // 'newest' or 'oldest'
  final TextEditingController _rwController = TextEditingController();
  final TextEditingController _rtController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadSavedFilters(); // Load saved filters on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportProvider.notifier).loadAllReports();
    });
  }

  @override
  void dispose() {
    _rwController.dispose();
    _rtController.dispose();
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

  // Apply filters and sorting
  List<Report> _applyFiltersAndSort(List<Report> reports) {
    List<Report> filtered = List.from(reports);

    // Filter by RW (regex to handle different formats: RW1, RW 1, RW 01, etc.)
    if (_selectedRw.isNotEmpty) {
      final rwRegex = RegExp(r'RW\s*0*' + _selectedRw.replaceAll(RegExp(r'[^\d]'), '') + r'\b', caseSensitive: false);
      filtered = filtered.where((report) => rwRegex.hasMatch(report.address)).toList();
    }

    // Filter by RT (regex to handle different formats: RT1, RT 1, RT 01, etc.)
    if (_selectedRt.isNotEmpty) {
      final rtRegex = RegExp(r'RT\s*0*' + _selectedRt.replaceAll(RegExp(r'[^\d]'), '') + r'\b', caseSensitive: false);
      filtered = filtered.where((report) => rtRegex.hasMatch(report.address)).toList();
    }

    // Filter by status
    if (_selectedStatus.isNotEmpty && _selectedStatus != 'semua') {
      filtered = filtered.where((report) => 
        report.status.toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    // Apply sorting (using UTC+7 time)
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return filtered;
  }

  // Save filter preferences
  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reports_filter_rw', _selectedRw);
    await prefs.setString('reports_filter_rt', _selectedRt);
    await prefs.setString('reports_filter_status', _selectedStatus);
    await prefs.setString('reports_filter_sort', _sortBy);
  }

  // Load saved filter preferences
  Future<void> _loadSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedRw = prefs.getString('reports_filter_rw') ?? '';
      _selectedRt = prefs.getString('reports_filter_rt') ?? '';
      _selectedStatus = prefs.getString('reports_filter_status') ?? '';
      _sortBy = prefs.getString('reports_filter_sort') ?? 'newest';
      
      // Update controllers
      _rwController.text = _selectedRw;
      _rtController.text = _selectedRt;
    });
  }

  // Clear saved filters
  Future<void> _clearSavedFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reports_filter_rw');
    await prefs.remove('reports_filter_rt');
    await prefs.remove('reports_filter_status');
    await prefs.remove('reports_filter_sort');
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
    }
  }

  // Navigate to previous page
  void _prevPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
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
    final totalPages = _getTotalPages(reports);
    final paginatedReports = _getPaginatedReports(reports);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
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
        if (reports.length > _itemsPerPage)
          _buildPaginationControls(totalPages),
      ],
    );
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
          // RW and RT filters
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
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _rwController,
                        onChanged: (value) {
                          setState(() {
                            _selectedRw = value;
                            _currentPage = 0; // Reset to first page
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 1, 01',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
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
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: _rtController,
                        onChanged: (value) {
                          setState(() {
                            _selectedRt = value;
                            _currentPage = 0; // Reset to first page
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 1, 01',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                  ],
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
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151)),
                        items: [
                          DropdownMenuItem(value: 'semua', child: Text('Semua Status', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'menunggu', child: Text('Menunggu', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'diajukan', child: Text('Diajukan', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'diproses', child: Text('Diproses', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'selesai', child: Text('Selesai', style: GoogleFonts.inter(fontSize: 12))),
                          DropdownMenuItem(value: 'ditolak', child: Text('Ditolak', style: GoogleFonts.inter(fontSize: 12))),
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
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF374151)),
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
          // Action buttons - Clear filters and Save
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await _clearSavedFilters();
                  setState(() {
                    _selectedRw = '';
                    _selectedRt = '';
                    _selectedStatus = '';
                    _sortBy = 'newest';
                    _rwController.clear();
                    _rtController.clear();
                    _currentPage = 0;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(
                  'Hapus Filter',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  await _saveFilters();
                  setState(() {
                    _showFilters = false; // Close filter popup
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Filter berhasil disimpan',
                        style: GoogleFonts.inter(color: Colors.white),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Simpan',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().slideY(begin: -0.3).fadeIn();
  }

}
