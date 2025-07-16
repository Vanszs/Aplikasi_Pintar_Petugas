import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/gradient_background.dart';

class GuideScreen extends ConsumerStatefulWidget {
  const GuideScreen({super.key});

  @override
  ConsumerState<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends ConsumerState<GuideScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tabs = [
    {'title': 'Pengenalan', 'icon': Icons.lightbulb_outline},
    {'title': 'Fitur', 'icon': Icons.apps_outlined},
    {'title': 'Cara Lapor', 'icon': Icons.report_problem_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GradientBackground(
          colors: const [
            Color(0xFFEFF6FF),  // Light blue
            Color(0xFFEDE9FE),  // Light purple
            Color(0xFFFDF2F8),  // Light pink
            Color(0xFFF0F9FF),  // Lightest blue
          ],
          child: Column(
            children: [
              // App bar and tab bar
              _buildAppBar(context),
              _buildTabBar(),
              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildIntroductionTab(0),
                    _buildFeaturesTab(0),
                    _buildReportingGuideTab(0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            'Panduan Aplikasi',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF9AA6B2).withAlpha(51),
        ),
        dividerColor: Colors.transparent,
        labelColor: const Color(0xFF334155),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: _tabs.map((tab) => Tab(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(tab['icon'] as IconData, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tab['title'] as String,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildIntroductionTab(double bottomPadding) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildIntroHeader(),
        const SizedBox(height: 24),
        _buildSectionHeader('Tujuan Aplikasi', Icons.track_changes),
        const SizedBox(height: 16),
        ...[
          {'title': 'Meningkatkan Keamanan', 'desc': 'Menciptakan lingkungan yang lebih aman melalui sistem pelaporan cepat', 'icon': Icons.security_rounded},
          {'title': 'Kolaborasi Warga', 'desc': 'Membangun kewaspadaan bersama antar warga kelurahan', 'icon': Icons.groups_rounded},
          {'title': 'Respon Cepat', 'desc': 'Memastikan bantuan segera datang saat situasi darurat', 'icon': Icons.speed_rounded},
        ].asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildInfoItem(
            item['title'] as String,
            item['desc'] as String,
            item['icon'] as IconData,
            index,
          );
        }),
        
        const SizedBox(height: 24),
        _buildSectionHeader('Cara Kerja', Icons.settings),
        const SizedBox(height: 16),
        ...[
          {'step': 1, 'title': 'Registrasi', 'desc': 'Daftar melalui kantor kelurahan untuk memastikan keamanan sistem'},
          {'step': 2, 'title': 'Kirim Laporan', 'desc': 'Gunakan tombol darurat saat melihat kejadian mencurigakan'},
          {'step': 3, 'title': 'Petugas Merespon', 'desc': 'Laporan diterima petugas keamanan dan ditindaklanjuti'},
        ].asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildStepItem(
            item['step'] as int,
            item['title'] as String,
            item['desc'] as String,
            index,
          );
        }),
      ],
    );
  }

  Widget _buildFeaturesTab(double bottomPadding) {
    final features = [
      {
        'title': 'Lapor Darurat',
        'desc': 'Kirim laporan kejadian darurat secara instan ke petugas keamanan kelurahan',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.red,
      },
      {
        'title': 'Riwayat Laporan',
        'desc': 'Lihat status dan riwayat laporan yang telah Anda kirimkan',
        'icon': Icons.history_rounded,
        'color': Colors.blue,
      },
      {
        'title': 'Kontak Darurat',
        'desc': 'Akses cepat ke nomor telepon penting untuk situasi darurat',
        'icon': Icons.contacts_rounded,
        'color': Colors.green,
      },
      {
        'title': 'Panduan Aplikasi',
        'desc': 'Pelajari cara menggunakan aplikasi dan tips keamanan',
        'icon': Icons.menu_book_rounded,
        'color': Colors.amber,
      },
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildFeaturesHeader(),
        const SizedBox(height: 24),
        ...features.asMap().entries.map((entry) {
          final index = entry.key;
          final feature = entry.value;
          return _buildFeatureCard(
            feature['title'] as String,
            feature['desc'] as String,
            feature['icon'] as IconData,
            feature['color'] as Color,
            index,
          );
        }),
      ],
    );
  }

  Widget _buildReportingGuideTab(double bottomPadding) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildReportingHeader(),
        const SizedBox(height: 24),
        _buildSectionHeader('Langkah-langkah Pelaporan', Icons.format_list_numbered),
        const SizedBox(height: 16),
        ...[
          {'step': 1, 'title': 'Buka Aplikasi Simokerto PINTAR', 'desc': 'Pastikan Anda sudah login ke akun Anda'},
          {'step': 2, 'title': 'Tekan Tombol Lapor Darurat', 'desc': 'Tombol merah besar di halaman utama'},
          {'step': 3, 'title': 'Konfirmasi Laporan', 'desc': 'Baca petunjuk dan tekan tombol kirim'},
          {'step': 4, 'title': 'Tunggu Konfirmasi', 'desc': 'Sistem akan memberi notifikasi bahwa laporan terkirim'},
          {'step': 5, 'title': 'Petugas Merespon', 'desc': 'Petugas keamanan akan segera merespon laporan Anda'},
        ].asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return _buildReportingStep(
            step['step'] as int,
            step['title'] as String,
            step['desc'] as String,
            index,
          );
        }),
        
        const SizedBox(height: 24),
        _buildSectionHeader('Hal Penting', Icons.warning_amber),
        const SizedBox(height: 16),
        _buildWarningCard(),
      ],
    );
  }

  Widget _buildIntroHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_outlined,
              color: Color(0xFF6366F1),
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Simokerto PINTAR',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pelaporan Instant Tangkal Ancaman Rawan',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF4B5563),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Aplikasi keamanan warga untuk melaporkan kejadian darurat dan menciptakan lingkungan yang lebih aman.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withAlpha(26),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    ).animate().fadeIn().slideX(begin: -0.2);
  }

  Widget _buildInfoItem(String title, String description, IconData icon, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildStepItem(int step, String title, String description, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildFeaturesHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.apps, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fitur Utama',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Daftar kemampuan aplikasi Simokerto PINTAR',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildReportingHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.campaign_outlined, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cara Melaporkan',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Panduan untuk melaporkan kejadian darurat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(77),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                'Perhatian',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWarningItem('Gunakan fitur ini hanya untuk keadaan darurat'),
          _buildWarningItem('Laporan palsu dapat dikenakan sanksi'),
          _buildWarningItem('Pastikan lokasi Anda akurat saat mengirim laporan'),
          _buildWarningItem('Tetap di lokasi jika memungkinkan hingga petugas datang'),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, Color color, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildReportingStep(int step, String title, String description, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withAlpha(204),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
  }
}
