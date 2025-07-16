import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/global_offline_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/global_refresh_provider.dart';
import '../main.dart';
import 'dart:developer' as developer;

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
  bool _showOfflineCapsule = false; // State untuk capsule offline

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

    // Force check offline state on cold boot - dengan delay untuk memastikan provider sudah ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Immediate check tanpa delay untuk cold boot scenarios
      _performColdBootCheck();
      
      // Check tambahan dengan delay untuk memastikan state sudah settle
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _performSecondaryOfflineCheck();
        }
      });
      
      // Check terakhir dengan delay paling lama sebagai safety net
      Future.delayed(const Duration(milliseconds: 4000), () {
        if (mounted) {
          _performFinalOfflineCheck();
        }
      });
    });
  }

  void _performColdBootCheck() async {
    try {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);
      
      developer.log('Cold boot check - Auth: ${authState.isAuthenticated}', name: 'GlobalOfflineWrapper');
      
      // Jika belum authenticated, skip check
      if (!authState.isAuthenticated) {
        developer.log('User not authenticated, skipping offline check', name: 'GlobalOfflineWrapper');
        return;
      }

      // Force connectivity check first dengan multiple attempts
      final connectivityService = container.read(connectivityServiceProvider);
      bool hasInternet = false;
      
      // Try connectivity check multiple times untuk memastikan akurat
      for (int i = 0; i < 3; i++) {
        hasInternet = await connectivityService.checkInternetConnection();
        if (hasInternet) break;
        
        // Wait sebelum retry
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
      // Update internet connection provider
      container.read(internetConnectionProvider.notifier).state = hasInternet;
      
      developer.log('Cold boot connectivity check result after ${hasInternet ? 1 : 3} attempts: $hasInternet', name: 'GlobalOfflineWrapper');
      
      if (!hasInternet) {
        // Show offline indication immediately
        developer.log('Cold boot: No internet - showing offline indication', name: 'GlobalOfflineWrapper');
        
        // Get offline handler and force it to show offline state
        final offlineHandler = container.read(globalOfflineHandlerProvider);
        
        // Force check offline state untuk memastikan handler dalam sync
        await offlineHandler.forceCheckOfflineState();
        
        // Force show popup if user authenticated and offline
        if (authState.isAuthenticated) {
          offlineHandler.checkOfflineStateForAuthenticatedUser();
          
          // Double check: jika popup masih tidak muncul, force show capsule
          await Future.delayed(const Duration(milliseconds: 500));
          if (!offlineHandler.shouldShowOfflinePopup && !_showOfflineCapsule) {
            if (mounted) {
              setState(() {
                _showOfflineCapsule = true;
              });
              developer.log('Cold boot: Forcing capsule show as fallback', name: 'GlobalOfflineWrapper');
            }
          }
        }
      }
      
    } catch (e) {
      developer.log('Error in cold boot check: $e', name: 'GlobalOfflineWrapper');
      
      // On error, assume offline dan show indication
      try {
        final container = ProviderScope.containerOf(context);
        final authState = container.read(authProvider);
        
        if (authState.isAuthenticated && mounted) {
          setState(() {
            _showOfflineCapsule = true;
          });
          developer.log('Cold boot error: Showing offline capsule as safeguard', name: 'GlobalOfflineWrapper');
        }
      } catch (fallbackError) {
        developer.log('Cold boot fallback error: $fallbackError', name: 'GlobalOfflineWrapper');
      }
    }
  }

  void _performSecondaryOfflineCheck() async {
    try {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);
      final internetConnection = container.read(internetConnectionProvider);
      
      // Jika user authenticated dan belum ada check internet, force check
      if (authState.isAuthenticated && internetConnection == null) {
        developer.log('Secondary check: Internet connection still unchecked - performing check', name: 'GlobalOfflineWrapper');
        
        final connectivityService = container.read(connectivityServiceProvider);
        final hasInternet = await connectivityService.checkInternetConnection();
        container.read(internetConnectionProvider.notifier).state = hasInternet;
        
        if (!hasInternet && !_showOfflineCapsule) {
          developer.log('Secondary check: No internet detected - showing offline indication', name: 'GlobalOfflineWrapper');
          if (mounted) {
            setState(() {
              _showOfflineCapsule = true;
            });
          }
        }
      }
      
      // Jika user authenticated tapi offline dan belum ada indikasi, force show
      if (authState.isAuthenticated && internetConnection == false && !_showOfflineCapsule) {
        developer.log('Secondary check: Offline but no indication shown - forcing capsule', name: 'GlobalOfflineWrapper');
        if (mounted) {
          setState(() {
            _showOfflineCapsule = true;
          });
        }
      }
      
    } catch (e) {
      developer.log('Error in secondary offline check: $e', name: 'GlobalOfflineWrapper');
    }
  }

  void _performFinalOfflineCheck() async {
    try {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authProvider);
      final internetConnection = container.read(internetConnectionProvider);
      
      // Final safety check - jika semua check sebelumnya gagal
      if (authState.isAuthenticated && internetConnection == null) {
        developer.log('Final check: Internet connection still null - performing final connectivity check', name: 'GlobalOfflineWrapper');
        
        final connectivityService = container.read(connectivityServiceProvider);
        final hasInternet = await connectivityService.checkInternetConnection();
        container.read(internetConnectionProvider.notifier).state = hasInternet;
        
        if (!hasInternet && !_showOfflineCapsule) {
          developer.log('Final check: No internet detected - showing offline indication as last resort', name: 'GlobalOfflineWrapper');
          if (mounted) {
            setState(() {
              _showOfflineCapsule = true;
            });
          }
        }
      }
      
      // Force show capsule jika offline dan belum ada indication
      if (authState.isAuthenticated && internetConnection == false && !_showOfflineCapsule) {
        developer.log('Final check: Still offline without indication - forcing capsule show', name: 'GlobalOfflineWrapper');
        if (mounted) {
          setState(() {
            _showOfflineCapsule = true;
          });
        }
      }
    } catch (e) {
      developer.log('Error in final offline check: $e', name: 'GlobalOfflineWrapper');
    }
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
        final isOfflineToOnlineSync = ref.watch(offlineToOnlineSyncProvider);
        final lastSync = ref.watch(lastSyncProvider);
        
        // Show refresh indicator only for offline-to-online sync or manual refresh
        final shouldShowRefreshing = isGlobalRefreshing || isOfflineToOnlineSync || _isRefreshing;
        
        // Show offline popup if user is authenticated and handler says we should show it (and capsule is not active)
        final shouldShowPopup = authState.isAuthenticated && 
                              offlineHandler.isInitialized && 
                              offlineHandler.shouldShowOfflinePopup &&
                              !_showOfflineCapsule;
        
        // Show capsule if offline but popup was dismissed by user (after "Coba Lagi" click)
        // OR if we're offline and initialized but no popup is showing
        final shouldShowCapsule = authState.isAuthenticated && 
                                offlineHandler.isInitialized && 
                                !offlineHandler.hasInternetConnection &&
                                (_showOfflineCapsule || (!offlineHandler.shouldShowOfflinePopup && !shouldShowPopup));
        
        // Auto reset capsule state when internet is restored
        if (offlineHandler.hasInternetConnection && _showOfflineCapsule) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showOfflineCapsule = false;
              });
            }
          });
        }
        
        // Auto show capsule if offline and no popup is showing (fallback logic)
        if (authState.isAuthenticated && 
            offlineHandler.isInitialized && 
            !offlineHandler.hasInternetConnection &&
            !offlineHandler.shouldShowOfflinePopup &&
            !_showOfflineCapsule) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showOfflineCapsule = true;
              });
              developer.log('Auto-showing capsule: offline but no popup', name: 'GlobalOfflineWrapper');
            }
          });
        }
        
        // Handle animation based on shouldShowPopup
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
            // Main app content - always allow interaction unless popup is blocking
            IgnorePointer(
              ignoring: shouldShowPopup, // Only block interaction when popup is shown
              child: widget.child,
            ),
            
            // Offline popup overlay with DefaultTextStyle
            if (shouldShowPopup || _fadeController.isAnimating || _fadeController.value > 0)
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  fontFamily: 'Inter',
                ),
                child: _buildOfflinePopupOverlay(lastSync, shouldShowRefreshing),
              ),
            
            // Offline capsule di pojok kanan atas - doesn't block interaction
            if (shouldShowCapsule)
              _buildOfflineCapsule(lastSync),
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
        // Connection restored successfully - hide both popup and capsule
        setState(() {
          _showOfflineCapsule = false;
        });
        
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
        // Still no internet - hide popup and show capsule (dismiss popup, allow offline mode)
        setState(() {
          _showOfflineCapsule = true;
        });
        
        // Also tell the offline handler to dismiss the popup
        offlineHandler.dismissOfflinePopup();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Koneksi internet masih tidak tersedia. Mode offline aktif.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.orange.shade600,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Error occurred - hide popup and show capsule (allow offline mode)
      setState(() {
        _showOfflineCapsule = true;
      });
      
      // Also tell the offline handler to dismiss the popup
      final offlineHandler = ref.read(globalOfflineHandlerProvider);
      offlineHandler.dismissOfflinePopup();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Koneksi internet masih tidak tersedia. Mode offline aktif.',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.orange.shade600,
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

  Widget _buildOfflineCapsule(DateTime? lastSync) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade500.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Offline',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
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
