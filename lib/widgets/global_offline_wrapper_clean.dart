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
  bool _showOfflineCapsule = false;

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

    // Check initial state immediately after widget builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialOfflineState();
    });
  }

  // Check initial state for cold boot scenarios
  void _checkInitialOfflineState() {
    final authState = ref.read(authProvider);
    final offlineHandler = ref.read(globalOfflineHandlerProvider);
    
    developer.log('GlobalOfflineWrapper: Initial state check - Auth: ${authState.isAuthenticated}, HasInternet: ${offlineHandler.hasInternetConnection}, Initialized: ${offlineHandler.isInitialized}', name: 'GlobalOfflineWrapper');
    
    // If authenticated user has no internet, trigger offline state
    if (authState.isAuthenticated && 
        offlineHandler.isInitialized && 
        !offlineHandler.hasInternetConnection) {
      // Force the handler to show popup
      offlineHandler.checkOfflineStateForAuthenticatedUser();
      
      // If popup still doesn't show after a short delay, show capsule as fallback
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !offlineHandler.shouldShowOfflinePopup) {
          setState(() {
            _showOfflineCapsule = true;
          });
          developer.log('Initial check: Showing capsule as fallback', name: 'GlobalOfflineWrapper');
        }
      });
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
        
        // Debug logging untuk troubleshooting
        developer.log('GlobalOfflineWrapper build - Auth: ${authState.isAuthenticated}, Initialized: ${offlineHandler.isInitialized}, HasInternet: ${offlineHandler.hasInternetConnection}, ShouldShowPopup: ${offlineHandler.shouldShowOfflinePopup}, ShowCapsule: $_showOfflineCapsule', name: 'GlobalOfflineWrapper');
        
        // Show refresh indicator ONLY for offline-to-online sync (not for manual pull-to-refresh)
        final shouldShowRefreshing = isOfflineToOnlineSync && isGlobalRefreshing;
        
        // Show offline popup if user is authenticated and handler says we should show it (prioritize popup over capsule)
        final shouldShowPopup = authState.isAuthenticated && 
                              offlineHandler.isInitialized && 
                              offlineHandler.shouldShowOfflinePopup;
        
        // Show capsule if offline but popup was dismissed by user or popup is not showing
        final shouldShowCapsule = authState.isAuthenticated && 
                                offlineHandler.isInitialized && 
                                !offlineHandler.hasInternetConnection &&
                                !shouldShowPopup &&
                                (_showOfflineCapsule || !offlineHandler.shouldShowOfflinePopup);
        
        // Auto reset capsule state when internet is restored
        if (offlineHandler.hasInternetConnection && _showOfflineCapsule) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _showOfflineCapsule = false;
              });
              developer.log('Internet restored: Hiding capsule', name: 'GlobalOfflineWrapper');
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
            
            // Offline popup overlay with proper animation
            if (shouldShowPopup || _fadeController.isAnimating || _fadeController.value > 0)
              _buildOfflinePopupOverlay(lastSync, shouldShowRefreshing),
            
            // Offline capsule di pojok kanan atas - doesn't block interaction
            if (shouldShowCapsule)
              _buildOfflineCapsule(lastSync),
          ],
        );
      },
    );
  }

  // Build popup overlay with animation
  Widget _buildOfflinePopupOverlay(DateTime? lastSync, bool shouldShowRefreshing) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              constraints: const BoxConstraints(maxHeight: 500),
              child: _buildOfflinePopupContent(lastSync, shouldShowRefreshing),
            ),
          ),
        ),
      ),
    );
  }

  // Build popup content with Lottie animation
  Widget _buildOfflinePopupContent(DateTime? lastSync, bool shouldShowRefreshing) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
            // Lottie animation
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.asset(
                'assets/animations/no_internet.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if Lottie fails
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.wifi_off_rounded,
                      size: 80,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Tidak Ada Koneksi Internet',
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
            
            // Retry Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: shouldShowRefreshing ? null : () async {
                  await _handleGlobalRefresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (shouldShowRefreshing) ...[
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
                        'Menghubungkan...',
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
    );
  }

  // Get offline message for petugas
  String _getOfflineMessageForPetugas(DateTime? lastSync) {
    if (lastSync == null) {
      return 'Tidak dapat terhubung ke server.\nPastikan koneksi internet Anda aktif.';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) {
      return 'Terakhir tersinkron baru saja.\nSedang dalam mode offline.';
    } else if (difference.inMinutes < 60) {
      return 'Terakhir tersinkron ${difference.inMinutes} menit lalu.\nSedang dalam mode offline.';
    } else if (difference.inHours < 24) {
      return 'Terakhir tersinkron ${difference.inHours} jam lalu.\nSedang dalam mode offline.';
    } else {
      return 'Terakhir tersinkron ${difference.inDays} hari lalu.\nSedang dalam mode offline.';
    }
  }

  // Handle global refresh (retry connection)
  Future<void> _handleGlobalRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    developer.log('GlobalOfflineWrapper: Starting global refresh...', name: 'GlobalOfflineWrapper');
    
    try {
      // Use the global refresh function to ensure synchronization
      final globalRefresh = ref.read(globalRefreshProvider);
      final success = await globalRefresh();
      
      developer.log('GlobalOfflineWrapper: Global refresh result: $success', name: 'GlobalOfflineWrapper');
      
      if (success && mounted) {
        // Success - connection restored, let handler manage popup state
        final offlineHandler = ref.read(globalOfflineHandlerProvider);
        offlineHandler.hideOfflinePopup();
      } else if (mounted) {
        // Still no connection - show error feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Masih tidak ada koneksi internet',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Hide popup and show capsule instead
        final offlineHandler = ref.read(globalOfflineHandlerProvider);
        offlineHandler.hideOfflinePopup();
        setState(() {
          _showOfflineCapsule = true;
        });
      }
    } catch (e) {
      developer.log('GlobalOfflineWrapper: Error in global refresh: $e', name: 'GlobalOfflineWrapper');
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
            const Icon(
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
}
