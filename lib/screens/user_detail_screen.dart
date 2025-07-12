import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../main.dart';
import '../widgets/gradient_background.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String username;
  const UserDetailScreen({super.key, required this.username});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  User? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ref.read(apiServiceProvider);
    final result = await api.getUserByUsername(widget.username);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _user = result['user'] as User;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message'];
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFEFF6FF),
          Color(0xFFEDE9FE),
          Color(0xFFFDF2F8),
          Color(0xFFF0F9FF),
        ],
        child: Column(
          children: [
            Container(height: topPad, color: const Color(0xFFEFF6FF)),
            Padding(
              padding: const EdgeInsets.all(20),
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
                      child: const Icon(Icons.arrow_back, color: Color(0xFF334155), size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Info Pengguna',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _buildContent(),
            ),
            Container(height: bottomPad, color: const Color(0xFFF0F9FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final user = _user!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(user.name, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('@${user.username}', style: GoogleFonts.inter(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _infoTile('Alamat', user.address, Icons.location_on_outlined),
          const SizedBox(height: 12),
          _infoTile('No. Telepon', user.phone, Icons.phone_outlined),
          const SizedBox(height: 12),
          _infoTile('Bergabung', _formatDate(user.createdAt), Icons.calendar_today_outlined),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String? value, IconData icon) {
    // Handle null or empty values by showing a dash
    final displayValue = (value == null || value.isEmpty) ? "-" : value;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(displayValue, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1F2937))),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
