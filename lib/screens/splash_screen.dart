import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/modern_graphic_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Show splash screen for a short time
    await Future.delayed(const Duration(milliseconds: 1800));
    
    if (mounted) {
      // Check authentication state
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      
      // Navigate to appropriate screen
      context.go(isAuthenticated ? '/home' : '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          const ModernGraphicBackground(
            color1: Color(0xFF4338CA),
            color2: Color(0xFF6D28D9),
          ),
          
          // Content centered - just logo and text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 24),
                
                // App name
                Text(
                  'Simokerto PINTAR',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Pelayanan Informasi Terpadu dan Responsif',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
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