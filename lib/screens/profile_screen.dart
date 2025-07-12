import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/report_provider.dart';
import '../widgets/gradient_background.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final topSafePadding = MediaQuery.of(context).padding.top;
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

    // Show loading state if no user data
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Use the modern gradient background that matches other screens
    return Scaffold(
      body: GradientBackground(
        // Use a special profile gradient for visual differentiation
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
            
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final authNotifier = ref.read(authProvider.notifier);
                  final apiService = ref.read(apiServiceProvider);
                  final profileResult = await apiService.getUserProfile();
                  if (profileResult['success']) {
                    authNotifier.updateUser(profileResult['user']);
                  }
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Modernized App Bar
                    _buildAppBar(context, user),
                    // Profile Content
                    SliverPadding(
                      padding: const EdgeInsets.all(20.0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildProfileHeader(user).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                          const SizedBox(height: 24),
                          // Account Information
                          _buildSectionTitle("Informasi Akun"),
                          const SizedBox(height: 16),
                          _buildAccountInfoCard(user).animate(delay: 100.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
                          const SizedBox(height: 32),
                          // Additional Information Section
                          _buildSectionTitle("Aktivitas"),
                          const SizedBox(height: 16),
                          _buildActivityCard(ref).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.2),
                          const SizedBox(height: 32),
                          // Logout Button
                          _buildLogoutButton(context, ref).animate(delay: 300.ms).fadeIn(duration: 500.ms),
                          SizedBox(height: 20 + bottomSafePadding),
                        ]),
                      ),
                    )
                  ],
                ),
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
    );
  }

  Widget _buildAppBar(BuildContext context, User user) {
    return SliverAppBar(
      floating: false,  // Change from true to false - only appear when at the top
      pinned: false,    // Keep this false so it fully disappears when scrolling down
      snap: false,  
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: CircleAvatar(
          backgroundColor: const Color(0xFF6366F1).withAlpha(26),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF6366F1)),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      title: Text(
        'Profil Saya',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
        ),
      ),
      actions: [
        // Add a share button with animation
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF6366F1)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan akan datang di versi berikutnya'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(51),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile avatar
          Hero(
            tag: 'user_avatar',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(51),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(user.name),
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // User name
          Text(
            user.name,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          // Username badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '@${user.username}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // Admin/Officer badge
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(77),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(128), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user.role != null && user.role!.isNotEmpty 
                      ? user.role!
                      : 'Petugas',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(2),
          ),
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
    );
  }

  Widget _buildAccountInfoCard(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoItem(
            Icons.person_outlined,
            'Nama Lengkap',
            user.name,
            const Color(0xFF6366F1),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoItem(
            Icons.alternate_email,
            'Username',
            user.username,
            const Color(0xFF8B5CF6),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoItem(
            Icons.shield_outlined,
            'Peran',
            user.role != null && user.role!.isNotEmpty
               ? user.role!
               : 'Petugas',
            const Color(0xFFEF4444),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoItem(
            Icons.location_on_outlined,
            'Alamat',
            user.address,
            const Color(0xFFEC4899),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoItem(
            Icons.phone_outlined,
            'No. Telepon',
            user.phone,
            const Color(0xFF10B981),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF3F4F6)),
          _buildInfoItem(
            Icons.calendar_today_outlined,
            'Bergabung Sejak',
            _formatDate(user.createdAt),
            const Color(0xFF14B8A6),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(WidgetRef ref) {
    final reportState = ref.watch(reportProvider);
    final reportCount = reportState.reports.length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Laporan',
                  '$reportCount',
                  Icons.report_outlined,
                  const Color(0xFF6366F1),
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: const Color(0xFFF3F4F6),
              ),
              Expanded(
                child: _buildStatItem(
                  'Bulan Ini',
                  '${_getCurrentMonthReports(reportState.reports)}',
                  Icons.calendar_month_outlined,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // View all reports button
          TextButton.icon(
            onPressed: () => GoRouter.of(ref.context).push('/reports'),
            icon: const Icon(Icons.history_outlined, size: 18),
            label: const Text('Lihat Semua Riwayat'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String? value, Color iconColor) {
    // Handle null or empty values by showing a dash
    final displayValue = (value == null || value.isEmpty) ? "-" : value;
    
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: iconColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        // Show modern confirmation dialog
        final result = await _showModernLogoutDialog(context);
        
        if (result == true && context.mounted) {
          // Clear report state
          ref.read(reportProvider.notifier).resetState();
          
          // Logout user
          await ref.read(authProvider.notifier).logout();
          
          if (context.mounted) {
            context.go('/login');
          }
        }
      },
      icon: const Icon(Icons.logout_rounded),
      label: Text(
        'Keluar dari Akun',
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }
  
  Future<bool?> _showModernLogoutDialog(BuildContext context) async {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuint,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      size: 32,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Keluar dari Akun?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anda akan keluar dari akun saat ini. Apakah Anda yakin?',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Batal',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Ya, Keluar',
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
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final names = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (names.length > 1) {
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return names.first[0].toUpperCase();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
  
  int _getCurrentMonthReports(dynamic reports) {
    if (reports == null || reports.isEmpty) return 0;
    
    final now = DateTime.now();
    int count = 0;
    
    for (var report in reports) {
      final reportDate = report.createdAt;
      if (reportDate.year == now.year && reportDate.month == now.month) {
        count++;
      }
    }
    
    return count;
  }
}