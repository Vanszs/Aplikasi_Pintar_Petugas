import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../services/global_offline_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/global_refresh_provider.dart';
import 'dart:developer' as developer;

class GlobalOfflineWrapperNew extends ConsumerStatefulWidget {
  final Widget child;
  
  const GlobalOfflineWrapperNew({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<GlobalOfflineWrapperNew> createState() => _GlobalOfflineWrapperNewState();
}

class _GlobalOfflineWrapperNewState extends ConsumerState<GlobalOfflineWrapperNew> 
    with TickerProviderStateMixin {
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isRefreshing = false;
  bool _showOfflineCapsule = false;
  OverlayEntry? _overlayEntry; // Use overlay like reference app

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

    // CRITICAL: Check initial state immediately after widget builds (like reference app)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialOfflineState();
    });
  }

  // Check initial state like reference app
  void _checkInitialOfflineState() {
    final authState = ref.read(authProvider);
    final offlineHandler = ref.read(globalOfflineHandlerProvider);
    
    developer.log('GlobalOfflineWrapper: Initial state check - Auth: ${authState.isAuthenticated}, HasInternet: ${offlineHandler.hasInternetConnection}, Initialized: ${offlineHandler.isInitialized}', name: 'GlobalOfflineWrapper');
    
    // CRITICAL: If authenticated user has no internet, show popup immediately
    if (authState.isAuthenticated && 
        offlineHandler.isInitialized && 
        !offlineHandler.hasInternetConnection) {
      _showOfflinePopup();
    }
  }

  // Show popup using overlay like reference app
  void _showOfflinePopup() {
    if (_overlayEntry != null) return;
    
    developer.log('GlobalOfflineWrapper: Showing offline popup via overlay', name: 'GlobalOfflineWrapper');
    
    _overlayEntry = _createOfflineOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  // Hide popup and cleanup overlay
  void _hideOfflinePopup() {
    if (_overlayEntry == null) return;
    
    developer.log('GlobalOfflineWrapper: Hiding offline popup', name: 'GlobalOfflineWrapper');
    
    // Animate out
    _fadeController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
    _slideController.reverse();
    
    setState(() {
      _showOfflineCapsule = false;
    });
  }

  // Create overlay entry for offline popup (like reference app)
  OverlayEntry _createOfflineOverlay() {
    return OverlayEntry(
      builder: (context) => Positioned.fill(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.black.withValues(alpha: 0.6),
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: _buildOfflinePopupContent(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build popup content with Lottie animation
  Widget _buildOfflinePopupContent() {
    final lastSync = ref.watch(lastSyncProvider);
    final shouldShowRefreshing = ref.watch(offlineToOnlineSyncProvider) && ref.watch(globalRefreshStateProvider);
    
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
            // Lottie animation (like in reference)
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
        // Success - connection restored, hide popup
        _hideOfflinePopup();
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
        
        // Instead of keeping popup, show capsule
        _hideOfflinePopup();
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

  // Build small offline capsule
  Widget _buildSmallOfflineCapsule(DateTime? lastSync) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              'Offline',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build sync indicator
  Widget _buildSyncIndicator() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Menyinkronkan...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
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
        developer.log('GlobalOfflineWrapper build - Auth: ${authState.isAuthenticated}, Initialized: ${offlineHandler.isInitialized}, HasInternet: ${offlineHandler.hasInternetConnection}, Overlay: ${_overlayEntry != null}, Capsule: $_showOfflineCapsule', name: 'GlobalOfflineWrapper');
        
        // Show refresh indicator ONLY for offline-to-online sync (not for manual pull-to-refresh)
        final shouldShowRefreshing = isOfflineToOnlineSync && isGlobalRefreshing;
        
        // Listen to real-time changes (like reference app)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authState.isAuthenticated && offlineHandler.isInitialized) {
            if (!offlineHandler.hasInternetConnection && _overlayEntry == null && !_showOfflineCapsule) {
              // Show popup if offline and no popup/capsule is showing
              _showOfflinePopup();
            } else if (offlineHandler.hasInternetConnection && (_overlayEntry != null || _showOfflineCapsule)) {
              // Hide popup/capsule if online
              _hideOfflinePopup();
              setState(() {
                _showOfflineCapsule = false;
              });
            }
          }
        });
        
        // Show capsule if popup was dismissed but still offline
        final shouldShowCapsule = authState.isAuthenticated && 
                                offlineHandler.isInitialized && 
                                !offlineHandler.hasInternetConnection &&
                                _overlayEntry == null &&
                                _showOfflineCapsule;

        return Stack(
          children: [
            // Main app content
            widget.child,
            
            // Small offline capsule (when popup dismissed)
            if (shouldShowCapsule)
              _buildSmallOfflineCapsule(lastSync),
            
            // Sync indicator (only for offline-to-online transitions)
            if (shouldShowRefreshing)
              _buildSyncIndicator(),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
