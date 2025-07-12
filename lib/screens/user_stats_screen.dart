import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../widgets/gradient_background.dart';

class UserStatsScreen extends ConsumerStatefulWidget {
  final String? username;
  const UserStatsScreen({super.key, this.username});

  @override
  ConsumerState<UserStatsScreen> createState() => _UserStatsScreenState();
}

class _UserStatsScreenState extends ConsumerState<UserStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = ref.read(apiServiceProvider);
    Map<String, dynamic> result;
    if (widget.username != null) {
      result = await api.getUserStatsByUsername(widget.username!);
    } else {
      result = await api.getUserStats();
    }
    if (mounted) {
      if (result['success']) {
        setState(() {
          _stats = result['data'] as Map<String, dynamic>;
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
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;
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
            Container(height: top, color: const Color(0xFFEFF6FF)),
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
                    'Statistik Pengguna',
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
            Container(height: bottom, color: const Color(0xFFF0F9FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final data = _stats!;
    final user = data['user'] as Map<String, dynamic>;
    final reports = data['reports'] as Map<String, dynamic>;
    final recent = reports['recent'] as List<dynamic>;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nama: ${user['name'] ?? '-'}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Alamat: ${user['address'] ?? '-'}', style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 4),
          Text('Telepon: ${user['phone'] != null ? user['phone'].toString() : '-'}', style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 20),
          _statTile('Total Laporan', reports['total'] != null ? reports['total'].toString() : '0'),
          const SizedBox(height: 12),
          _statTile('Hari Ini', reports['today'] != null ? reports['today'].toString() : '0'),
          const SizedBox(height: 20),
          Text('Laporan Terbaru', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...recent.map((e) => _recentTile(e)),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _recentTile(dynamic data) {
    final created = DateTime.parse(data['created_at']).toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['address'] ?? '-', style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 4),
          Text('${created.day}-${created.month}-${created.year} ${created.hour}:${created.minute.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
