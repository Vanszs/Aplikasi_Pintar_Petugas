import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/animated_app_bar.dart';
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
          'Prosedur Pendaftaran',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B), // Dark text for light background
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Untuk menjaga keamanan dan validitas data, pendaftaran dilakukan secara offline di kantor kelurahan.',
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
            'Cara Mendaftar',
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
        'icon': Icons.description_outlined,
        'title': 'Siapkan Dokumen',
        'description': 'Bawa KTP, Kartu Keluarga, dan bukti kepemilikan rumah.',
      },
      {
        'icon': Icons.location_city_outlined,
        'title': 'Kunjungi Kelurahan',
        'description': 'Datang ke kantor kelurahan pada jam kerja (08:00-15:00).',
      },
      {
        'icon': Icons.edit_note_outlined,
        'title': 'Isi Formulir',
        'description': 'Lengkapi formulir pendaftaran yang disediakan petugas.',
      },
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Verifikasi & Aktivasi',
        'description': 'Akun Anda akan aktif setelah proses verifikasi selesai.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Langkah-langkah',
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
          'Lokasi Pendaftaran',
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
