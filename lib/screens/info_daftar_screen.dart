import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/gradient_background.dart';

class InfoDaftarScreen extends StatelessWidget {
  const InfoDaftarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;
    final topSafePadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFF8FAFC), // Light blue-gray
          Color(0xFFD9EAFD), // Light blue
          Color(0xFFBCCCDC), // Medium blue-gray
          Color(0xFF9AA6B2), // Darker blue-gray
        ],
        child: Column(
          children: [
            // Solid top safe area
            Container(
              height: topSafePadding,
              color: const Color(0xFFF8FAFC),
            ),

            // App bar - updating to match lighter scheme
            _buildAppBar(context),

            // Content - update text colors for better contrast with light background
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSectionLight(),
                    const SizedBox(height: 32),
                    _buildRegistrationSteps(),
                    const SizedBox(height: 32),
                    _buildLocationSection(),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
              ),
            ),

            // Solid bottom safe area
            Container(
              height: bottomSafePadding,
              color: const Color(0xFF9AA6B2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSectionLight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pendaftaran Akun Petugas',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B), // Dark text for light background
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Akun petugas didaftarkan oleh superadmin kelurahan. Petugas tidak dapat mendaftar sendiri untuk menjaga keamanan sistem.',
          style: GoogleFonts.inter(
            fontSize: 16,
            color: const Color(0xFF64748B), // Medium gray for light background
            height: 1.5,
          ),
        ),
      ],
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
                color: Color(0xFF334155), // Darker color for visibility
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Cara Menjadi Petugas',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B), // Dark text for light background
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationSteps() {
    final steps = [
      {
        'icon': Icons.person_add_outlined,
        'title': 'Seleksi Kandidat',
        'description': 'Superadmin kelurahan melakukan seleksi calon petugas berdasarkan kriteria tertentu.',
      },
      {
        'icon': Icons.assignment_outlined,
        'title': 'Verifikasi Data',
        'description': 'Data calon petugas diverifikasi dan divalidasi oleh tim kelurahan.',
      },
      {
        'icon': Icons.account_circle_outlined,
        'title': 'Pembuatan Akun',
        'description': 'Superadmin membuat akun petugas dengan username dan password unik.',
      },
      {
        'icon': Icons.key_outlined,
        'title': 'Penyerahan Kredensial',
        'description': 'Username dan password diserahkan kepada petugas untuk akses aplikasi.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Proses Pendaftaran',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937), // Changed to dark color
          ),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          int index = entry.key;
          Map<String, Object> step = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)), // Lighter border
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF4F46E5),
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['title'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937), // Changed to dark color
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF6B7280), // Changed to medium gray
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      step['icon'] as IconData,
                      color: const Color(0xFF4F46E5).withAlpha(128),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (200 * index).ms).slideX(begin: -0.2);
        }),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kantor Kelurahan',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937), // Changed to dark color
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)), // Lighter border
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.location_city,
                          color: Color(0xFF4F46E5),
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kantor Kelurahan Sukajadi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937), // Changed to dark color
                            ),
                          ),
                          Text(
                            'Jl. Sukajadi No. 123, Kota Jakarta',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280), // Changed to medium gray
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE2E8F0)), // Lighter divider
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(Icons.access_time, 'Jam Operasional', '08:00 - 15:00'),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.phone, 'Telepon', '021-5551234'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildInfoItem(IconData icon, String title, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280), // Changed to medium gray
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937), // Changed to dark color
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
