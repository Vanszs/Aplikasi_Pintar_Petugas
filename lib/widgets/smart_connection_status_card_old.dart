import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../providers/auth_provider.dart';
import '../providers/global_refresh_provider.dart';
import '../main.dart';

class SmartConnectionStatusCard extends ConsumerStatefulWidget {
  final VoidCallback? onRefreshComplete;
  
  const SmartConnectionStatusCard({
    super.key,
    this.onRefreshComplete,
  });

  @override
  ConsumerState<SmartConnectionStatusCard> createState() => _SmartConnectionStatusCardState();
}

class _SmartConnectionStatusCardState extends ConsumerState<SmartConnectionStatusCard> 
    with TickerProviderStateMixin {
  bool _isRefreshing = false;
  Timer? _hideTimer;
  Timer? _periodicCheckTimer; // Tambahkan timer untuk periodic check
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _hasInternetConnection = true;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    
    // Listen to auth state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialState();
      _setupConnectivityListener();
      _performInitialConnectivityCheck();
      _startPeriodicInternetCheck(); // Tambahkan periodic check untuk auto-detect
    });
  }

  void _checkInitialState() {
    final authState = ref.read(authProvider);
    final internetConnection = ref.read(internetConnectionProvider);
    
    if (authState.isAuthenticated && internetConnection == false) {
      _showOfflineMode();
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _handleConnectivityChange(result);
    });
  }

  Future<void> _performInitialConnectivityCheck() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Ada koneksi basic, cek internet sesungguhnya
        final connectivityService = ref.read(connectivityServiceProvider);
        final hasRealInternet = await connectivityService.checkInternetConnection();
        
        _hasInternetConnection = hasRealInternet;
        ref.read(internetConnectionProvider.notifier).state = hasRealInternet;
        
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated && !hasRealInternet) {
          _showOfflineMode();
        }
      } else {
        // Tidak ada koneksi sama sekali
        _hasInternetConnection = false;
        ref.read(internetConnectionProvider.notifier).state = false;
        
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          _showOfflineMode();
        }
      }
    } catch (e) {
      // Handle connectivity check error silently
    }
  }

  void _handleConnectivityChange(ConnectivityResult result) async {
    // Jangan hanya cek connectivity result, tapi cek internet sesungguhnya
    final hasBasicConnection = result != ConnectivityResult.none;
    
    if (hasBasicConnection) {
      // Ada koneksi WiFi/mobile, sekarang cek internet sesungguhnya
      final connectivityService = ref.read(connectivityServiceProvider);
      final hasRealInternet = await connectivityService.checkInternetConnection();
      
      if (_hasInternetConnection != hasRealInternet) {
        _hasInternetConnection = hasRealInternet;
        ref.read(internetConnectionProvider.notifier).state = hasRealInternet;
        
        final authState = ref.read(authProvider);
        
        if (authState.isAuthenticated) {
          if (!hasRealInternet) {
            _showOfflineMode();
          } else {
            _handleConnectionRestored();
          }
        }
      }
    } else {
      // Tidak ada koneksi sama sekali
      if (_hasInternetConnection) {
        _hasInternetConnection = false;
        ref.read(internetConnectionProvider.notifier).state = false;
        
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          _showOfflineMode();
        }
      }
    }
  }

  void _showOfflineMode() {
    if (!mounted) return;
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _hideOfflineMode() {
    if (!mounted) return;
    
    _fadeController.reverse();
    _slideController.reverse();
  }

  Future<void> _handleConnectionRestored() async {
    // Auto-refresh when connection is restored
    final globalRefresh = ref.read(globalRefreshProvider);
    
    try {
      final success = await globalRefresh();
      
      if (success) {
        _hideOfflineMode();
        
        // Show brief online status
        _hideTimer?.cancel();
        _hideTimer = Timer(const Duration(seconds: 3), () {
          // Connection restored successfully
        });
        
        widget.onRefreshComplete?.call();
      } else {
        // Connection restored but refresh failed - keep showing offline mode
      }
    } catch (e) {
      // Handle auto-refresh error silently
    }
  }

  Future<void> _handleGlobalRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // Pertama, cek koneksi internet sesungguhnya
      final connectivityService = ref.read(connectivityServiceProvider);
      final hasRealInternet = await connectivityService.checkInternetConnection();
      
      if (!hasRealInternet) {
        // Masih tidak ada internet
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
        return;
      }
      
      // Update status koneksi
      _hasInternetConnection = true;
      ref.read(internetConnectionProvider.notifier).state = true;
      
      // Coba refresh data
      final globalRefresh = ref.read(globalRefreshProvider);
      final success = await globalRefresh();
      
      if (success) {
        _hideOfflineMode();
        widget.onRefreshComplete?.call();
        
        // Show success message
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
        // Refresh gagal meskipun ada internet
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memuat data. Coba lagi nanti.',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.orange.shade600,
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

  // Tambahkan method untuk periodic check
  void _startPeriodicInternetCheck() {
    // Check setiap 10 detik kalau lagi offline
    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        timer.cancel();
        return;
      }
      
      // Hanya cek kalau lagi dalam mode offline
      if (!_hasInternetConnection) {
        final connectivityService = ref.read(connectivityServiceProvider);
        final hasRealInternet = await connectivityService.checkInternetConnection();
        
        if (hasRealInternet && _hasInternetConnection != hasRealInternet) {
          // Internet sudah kembali!
          _hasInternetConnection = true;
          ref.read(internetConnectionProvider.notifier).state = true;
          _handleConnectionRestored();
        }
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _connectivitySubscription?.cancel();
    _hideTimer?.cancel();
    _periodicCheckTimer?.cancel(); // Cancel periodic timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        final isGlobalRefreshing = ref.watch(globalRefreshStateProvider);
        final internetConnection = ref.watch(internetConnectionProvider);
        final lastSync = ref.watch(lastSyncProvider);
        
        final isOnline = (internetConnection == true) && authState.isAuthenticated;
        final currentRefreshState = isGlobalRefreshing || _isRefreshing;
        
        // Show offline status as a full-screen overlay dengan pesan khusus petugas
        if (!isOnline && authState.isAuthenticated) {
          return _buildOfflinePopupCard(lastSync, currentRefreshState);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildOfflinePopupCard(DateTime? lastSync, bool isGlobalRefreshing) {
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
                          // Lottie Animation - ukuran 200x200
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
                          
                          // Title untuk petugas
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
                          
                          // Subtitle khusus petugas
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
                          
                          // Refresh Button - sesuaikan warna dengan theme petugas
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isGlobalRefreshing ? null : () async {
                                await _handleGlobalRefresh();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1), // Primary color untuk petugas
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
                                  if (isGlobalRefreshing) ...[
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
