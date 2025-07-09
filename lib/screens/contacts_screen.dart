import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/gradient_background.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      await launchUrl(launchUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka aplikasi telepon: $phoneNumber'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyContacts = [
      {'name': 'Polisi', 'number': '110', 'icon': Icons.local_police_rounded, 'color': Colors.blue},
      {'name': 'Ambulans', 'number': '119', 'icon': Icons.medical_services_rounded, 'color': Colors.green},
      {'name': 'Pemadam', 'number': '113', 'icon': Icons.fire_truck_rounded, 'color': Colors.red},
    ];

    final securityContacts = [
      {'name': 'Kantor Kelurahan', 'number': '021-5551234', 'icon': Icons.location_city_rounded},
      {'name': 'Pos Keamanan', 'number': '021-5556789', 'icon': Icons.security_rounded},
      {'name': 'Ketua RT', 'number': '0812-3456-7890', 'icon': Icons.people_alt_rounded},
    ];

    final topSafePadding = MediaQuery.of(context).padding.top;
    final bottomSafePadding = MediaQuery.of(context).padding.bottom;

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
            // Solid top safe area
            Container(
              height: topSafePadding,
              color: const Color(0xFFF8FAFC),
            ),
            // App bar
            _buildAppBar(),
            // Content
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomSafePadding),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Text(
                    'Layanan Nasional',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  _buildEmergencyContactsGrid(emergencyContacts),
                  const SizedBox(height: 24),
                  Text(
                    'Kontak Lokal',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2),
                  const SizedBox(height: 16),
                  ...securityContacts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final contact = entry.value;
                    return _buildContactCard(
                      contact['name'] as String,
                      contact['number'] as String,
                      contact['icon'] as IconData,
                      index,
                    );
                  }),
                ],
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

  Widget _buildAppBar() {
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
            'Kontak Darurat',
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

  Widget _buildHeader() {
    // Light theme header with better contrast
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBCCCDC)), // Medium blue-gray border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9AA6B2).withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.support_agent, color: Theme.of(context).primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bantuan Cepat',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Gunakan kontak ini untuk situasi darurat',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildEmergencyContactsGrid(List<Map<String, dynamic>> contacts) {
    // This ensures we avoid overflow by using LayoutBuilder
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate item width based on available width
        final itemWidth = (constraints.maxWidth - 32) / 3;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: contacts.asMap().entries.map((entry) {
            final index = entry.key;
            final contact = entry.value;
            return SizedBox(
              width: itemWidth,
              child: _buildEmergencyContactCard(
                contact['name'] as String,
                contact['number'] as String,
                contact['icon'] as IconData,
                contact['color'] as Color,
                index,
              ),
            );
          }).toList(),
        );
      }
    );
  }

  Widget _buildEmergencyContactCard(
    String name,
    String number,
    IconData icon,
    Color color,
    int index,
  ) {
    // Light theme emergency card
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _makePhoneCall(number),
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withAlpha(38),
        highlightColor: color.withAlpha(26),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (100 * index).ms).fadeIn().slideY(begin: 0.2);
  }

  Widget _buildContactCard(
    String name,
    String number,
    IconData icon,
    int index,
  ) {
    // Light theme contact card
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makePhoneCall(number),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.grey.withAlpha(26),
          highlightColor: Colors.grey.withAlpha(13),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Theme.of(context).primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        number,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.call, color: Theme.of(context).primaryColor, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (150 * index).ms).fadeIn().slideY(begin: 0.2);
  }
}
