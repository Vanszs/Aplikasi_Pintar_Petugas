import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/global_offline_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/global_refresh_provider.dart';

class GlobalOfflineWrapper extends ConsumerStatefulWidget {
  final Widget child;
  
  const GlobalOfflineWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GlobalOfflineWrapper> createState() => _GlobalOfflineWrapperState();
}

class _GlobalOfflineWrapperState extends ConsumerState<GlobalOfflineWrapper> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
      reverseCurve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final offlineHandler = ref.watch(globalOfflineHandlerProvider);
        final authState = ref.watch(authProvider);
        final isGlobalRefreshing = ref.watch(globalRefreshStateProvider);
        final lastSync = ref.watch(lastSyncProvider);
        
        // Only show offline popup if user is authenticated and handler says we should show it
        final shouldShowPopup = authState.isAuthenticated && 
                              offlineHandler.isInitialized && 
                              offlineHandler.shouldShowOfflinePopup;
        
        // Handle animation based on shouldShowPopup - use immediate post frame callback
        if (shouldShowPopup) {
          if (!_fadeController.isCompleted && !_fadeController.isAnimating) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _fadeController.forward();
                _slideController.forward();
              }
            });
          }
        } else {
          if (_fadeController.isCompleted && !_fadeController.isAnimating) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _fadeController.reverse();
                _slideController.reverse();
              }
            });
          }
        }
        
        return Stack(
          children: [
            // Main app content
            widget.child,
            
            // Offline popup overlay with DefaultTextStyle
            if (shouldShowPopup || _fadeController.isAnimating || _fadeController.value > 0)
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Inter',
                ),
                child: _buildOfflinePopupOverlay(lastSync, isGlobalRefreshing || _isRefreshing),
              ),
          ],
        );
      },
    );
  }

  Widget _buildOfflinePopupOverlay(DateTime? lastSync, bool isRefreshing) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation]),
      builder: (context, child) {
        return Stack(
          children: [
            // Full screen overlay
            Positioned.fill(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
            
            // Centered popup card
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: 20,
              right: 20,
              height: MediaQuery.of(context).size.height * 0.5,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDF7), // Warna cream untuk theme petugas
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lottie Animation
                          SizedBox(
                            height: 200,
                            width: 200,
                            child: Lottie.asset(
                              'assets/animations/no_internet.json',
                              fit: BoxFit.contain,
                              repeat: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Title
                          Text(
                            'Koneksi Internet Terputus',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          
                          // Subtitle
                          Text(
                            _getOfflineMessageForPetugas(lastSync),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          // Refresh Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isRefreshing ? null : () async {
                                await _handleGlobalRefresh();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                disabledBackgroundColor: const Color(0xFF9CA3AF),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isRefreshing) ...[
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Menghubungkan Ulang...',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ] else ...[
                                    const Icon(
                                      Icons.refresh_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      'Coba Lagi',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGlobalRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      final offlineHandler = ref.read(globalOfflineHandlerProvider);
      final success = await offlineHandler.refreshConnection();
      
      if (success) {
        // Connection restored successfully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Koneksi berhasil dipulihkan!',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Still no internet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Koneksi internet masih tidak tersedia. Coba lagi nanti.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  String _getOfflineMessageForPetugas(DateTime? lastSync) {
    if (lastSync == null) {
      return 'Tidak dapat terhubung ke server pusat.\nPastikan koneksi internet petugas aktif untuk sinkronisasi data laporan.';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Terakhir tersinkron baru saja.\nData laporan dalam mode offline - akan disinkronkan otomatis saat koneksi pulih.';
    } else if (difference.inMinutes < 60) {
      return 'Terakhir tersinkron ${difference.inMinutes} menit lalu.\nMode offline aktif - data laporan lokal tersedia.';
    } else if (difference.inHours < 24) {
      return 'Terakhir tersinkron ${difference.inHours} jam lalu.\nMode offline - segera hubungkan untuk sinkronisasi data terbaru.';
    } else {
      return 'Terakhir tersinkron ${difference.inDays} hari lalu.\nMode offline - diperlukan koneksi untuk update data laporan.';
    }
  }
}
