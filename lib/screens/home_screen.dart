import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'dart:developer' as developer;

import '../config/app_config.dart';
import '../main.dart';
import '../models/report.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../providers/global_refresh_provider.dart';
import '../services/global_offline_handler.dart';
import '../services/cache_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/report_action_button.dart';
import '../widgets/smart_connection_status_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    // Add observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    
    // Setup real-time listeners for report status updates
    _setupRealtimeListeners();
    
    // Jangan update user di initState, hanya refresh laporan/statistik saja
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      // First ensure socket is connected for real-time updates
      _ensureSocketConnection();
      
      // Force check offline state untuk memastikan popup/capsule muncul jika offline
      final globalOfflineHandler = ref.read(globalOfflineHandlerProvider);
      await globalOfflineHandler.forceCheckOfflineState();
      if (!mounted) return;
      
      // Cek koneksi internet
      final connectivityService = ref.read(connectivityServiceProvider);
      await connectivityService.checkInternetConnection();
      if (!mounted) return;
          // Load initial data
    await Future.wait([
      ref.read(reportProvider.notifier).loadUserReports(),
      ref.read(reportProvider.notifier).loadUserStats(),
      ref.read(reportProvider.notifier).loadGlobalStats(),
    ]);
    
    // Preload report details for offline access (background task)
    ref.read(reportProvider.notifier).preloadReportDetails();
      
      // After loading reports, pre-cache report details for offline access
      _preCacheReportDetails();
      
      // Start a periodic connection check
      _connectionCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted) {
          _ensureSocketConnection();
        }
      });
    });
  }
  
  @override
  void dispose() {
    // Remove observer and cancel timer when disposed
    WidgetsBinding.instance.removeObserver(this);
    _connectionCheckTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes from background, ensure we have fresh data
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        _ensureSocketConnection();
        // Force refresh all data when coming back to home screen
        _refreshAllData();
      }
    }
  }
  
  // Ensure socket is connected for real-time updates
  void _ensureSocketConnection() {
    try {
      final socketService = ref.read(socketServiceProvider);
      if (!socketService.isConnected) {
        debugPrint('HomeScreen: Socket not connected, attempting reconnection');
        socketService.connect();
      } else {
        debugPrint('HomeScreen: Socket connection verified');
      }
    } catch (e) {
      debugPrint('HomeScreen: Error checking socket connection: $e');
    }
  }

  // Force refresh all home screen data
  Future<void> _refreshAllData() async {
    if (!mounted) return;
    final globalRefresh = ref.read(globalRefreshProvider);
    await globalRefresh();
    
    // Preload report details after refresh for offline access
    if (mounted) {
      ref.read(reportProvider.notifier).preloadReportDetails();
    }
  }

  // Pre-cache report details for better offline experience
  void _preCacheReportDetails() async {
    try {
      final reportState = ref.read(reportProvider);
      final reports = reportState.reports;
      
      // Only pre-cache first 10 recent reports to avoid overwhelming the cache
      final reportsToCache = reports.take(10).toList();
      
      developer.log('Pre-caching ${reportsToCache.length} report details for offline access', name: 'HomeScreen');
      
      // Cache reports in background without blocking UI
      for (final report in reportsToCache) {
        try {
          // Cache report detail if ID is available
          final cached = await CacheService.loadReportDetail(report.id);
          if (cached == null) {
            // Load detail to trigger caching
            await ref.read(reportProvider.notifier).loadReportById(report.id);
            
            // Small delay to avoid overwhelming the API
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (e) {
          developer.log('Error pre-caching report ${report.id}: $e', name: 'HomeScreen');
          // Continue with other reports even if one fails
        }
        
        // Check if still mounted to avoid memory leaks
        if (!mounted) break;
      }
      
      developer.log('Pre-caching completed', name: 'HomeScreen');
    } catch (e) {
      developer.log('Error in pre-caching report details: $e', name: 'HomeScreen');
    }
  }

  // Setup real-time listeners for report updates
  void _setupRealtimeListeners() {
    try {
      final socketService = ref.read(socketServiceProvider);
      
      // Listen for any report-related updates
      socketService.listenForReports((report) {
        if (mounted) {
          // Force refresh when any report is updated
          _refreshAllData();
        }
      });
      
      // Listen for app resume events that trigger refresh
      socketService.listenForAppResume(() {
        if (mounted) {
          _refreshAllData();
        }
      });
      
    } catch (e) {
      debugPrint('Error setting up realtime listeners: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final reportState = ref.watch(reportProvider);
    final reports = reportState.reports;
    

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GradientBackground(
              colors: const [
                Color(0xFFEFF6FF),  // Light blue
                Color(0xFFEDE9FE),  // Light purple
                Color(0xFFFDF2F8),  // Light pink
                Color(0xFFF0F9FF),  // Lightest blue
              ],
              child: RefreshIndicator(
                onRefresh: _refreshAllData,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    _buildAppBar(user),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildReportButton(),
                            const SizedBox(height: 24),
                            _buildStatsSection(reportState),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildActivityFeed(reports),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Add SmartConnectionStatusCard for offline mode indication
            const SmartConnectionStatusCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(dynamic user) {
    // Fix header overflow issue by using a simpler approach
    return SliverAppBar(
      floating: false,
      pinned: false, // Changed to false to remove sticky behavior
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false, // Remove default back button
      toolbarHeight: 80, // Fixed height to avoid overflow
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.name ?? 'Pengguna',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (AppConfig.isBetaTesting) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBF24),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'MODE BETA',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(50),
              child: Hero(
                tag: 'user_avatar',
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9AA6B2), // Gray background for user avatar
                  ),
                  child: Center(
                    child: Text(
                      user?.name?.isNotEmpty == true
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportButton() {
    return const ReportActionButton();
  }

  Widget _buildStatsSection(ReportState reportState) {
    final globalStats = reportState.globalStats;
    
    // Get global stats 
    final totalReports = globalStats != null && globalStats['total'] != null
        ? globalStats['total'].toString()
        : '0';
    final todayReports = globalStats != null && globalStats['today'] != null
        ? globalStats['today'].toString()
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Laporan Global',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Laporan',
                totalReports,
                Icons.assessment_outlined,
                0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Laporan Hari Ini',
                todayReports,
                Icons.today_outlined,
                1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, int index) {
    // Updated with softer background color
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Softer blue-gray background instead of white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD9EAFD), // Lighter blue for accent
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: const Color(0xFF6366F1), size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B), // Adjusted to match theme
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (200 * index).ms).slideY(begin: 0.3);
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'title': 'Riwayat',
        'icon': Icons.history_outlined,
        'route': '/reports',
        'color': const Color(0xFF7C3AED),
      },
      {
        'title': 'Kontak',
        'icon': Icons.contacts_outlined,
        'route': '/contacts',
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Panduan',
        'icon': Icons.help_outline,
        'route': '/guide',
        'color': const Color(0xFFEAB308),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Akses Cepat',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        Row(
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == actions.length - 1 ? 0 : 8,
                ),
                child: _buildQuickActionCard(
                  action['title'] as String,
                  action['icon'] as IconData,
                  action['color'] as Color,
                  () => context.push(action['route'] as String),
                  index,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    int index,
  ) {
    // Updated with softer background color
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Softer blue-gray background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(26)),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(13),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(51)),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (150 * index).ms).slideY(begin: 0.2);
  }

  Widget _buildActivityFeed(List<Report> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Laporan Terbaru',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/reports'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4F46E5),
              ),
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        reports.isEmpty ? _buildEmptyStateWithLottie() : _buildReportList(reports),
      ],
    );
  }

  Widget _buildEmptyStateWithLottie() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Changed to white as requested
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withAlpha(26)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Centered content
        mainAxisAlignment: MainAxisAlignment.center, // Centered content vertically
        children: [
          Lottie.asset(
            'assets/animations/empty.json',
            height: 120,
            repeat: true,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text( // Kept only this text
            'Belum ada laporan yang dikirimkan warga saat ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600, // Made it bold for better visibility
              color: const Color(0xFF1F2937), // Changed color to match header
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildReportList(List<Report> reports) {
    final displayReports = reports.take(3).toList();

    return Column(
      children: displayReports.asMap().entries.map((entry) {
        final index = entry.key;
        final report = entry.value;

        // Updated with softer background color
        return InkWell(
          onTap: () {
            // Navigate to report detail
            context.push('/report-detail/${report.id}');
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Softer blue-gray background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withAlpha(26)),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9EAFD), // Lighter blue for accent
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign_outlined,
                      color: Color(0xFF6366F1), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.jenisLaporan != null && report.jenisLaporan!.isNotEmpty
                            ? 'Laporan ${report.jenisLaporan}'
                            : 'Laporan dari ${report.userName ?? 'Warga'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.formattedDate(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pelapor: ${report.userName ?? 'Tidak diketahui'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Status badge and arrow aligned horizontally
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(minWidth: 70), // Lebih kecil tapi masih konsisten
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding lebih kecil
                      decoration: BoxDecoration(
                        color: report.getStatusColor(),
                        borderRadius: BorderRadius.circular(10), // Border radius lebih kecil
                        boxShadow: [
                          BoxShadow(
                            color: report.getStatusColor().withValues(alpha: 0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Center( // Center text untuk alignment yang perfect
                        child: Text(
                          report.getStatusDisplay().toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 9, // Font size lebih kecil
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3, // Letter spacing lebih kecil
                          ),
                          textAlign: TextAlign.center, // Pastikan text di center
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF6366F1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.2);
      }).toList(),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 17) return 'Selamat Siang';
    return 'Selamat Malam';
  }

}
