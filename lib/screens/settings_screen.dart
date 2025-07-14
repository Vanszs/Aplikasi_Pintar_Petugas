import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/gradient_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _notificationSound;

  @override
  void initState() {
    super.initState();
    _loadNotificationSound();
  }

  Future<void> _loadNotificationSound() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationSound = prefs.getString('notification_sound');
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: const [
          Color(0xFFEFF6FF),
          Color(0xFFEDE9FE),
          Color(0xFFFDF2F8),
          Color(0xFFF0F9FF),
        ],
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: Text(
                'Pengaturan',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(
                          'Suara Notifikasi',
                          style: GoogleFonts.inter(),
                        ),
                        subtitle: Text(
                          _notificationSound ?? 'Default',
                          style: GoogleFonts.inter(color: Colors.grey),
                        ),
                        onTap: () {
                          GoRouter.of(context).push('/notification-settings');
                        },
                        trailing: const Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}