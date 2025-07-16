import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/global_refresh_provider.dart';

// Simplified SmartConnectionStatusCard that only shows a small connection indicator
// Main offline handling is now done by GlobalOfflineWrapper
class SmartConnectionStatusCard extends ConsumerStatefulWidget {
  final Function? onRefreshComplete;
  
  const SmartConnectionStatusCard({
    super.key,
    this.onRefreshComplete,
  });

  @override
  ConsumerState<SmartConnectionStatusCard> createState() => _SmartConnectionStatusCardState();
}

class _SmartConnectionStatusCardState extends ConsumerState<SmartConnectionStatusCard> {
  
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authProvider);
        final isGlobalRefreshing = ref.watch(globalRefreshStateProvider);
        final internetConnection = ref.watch(internetConnectionProvider);
        final lastSync = ref.watch(lastSyncProvider);
        
        // Only show a small indicator when authenticated and either refreshing or offline
        if (!authState.isAuthenticated) {
          return const SizedBox.shrink();
        }
        
        // Show small refreshing indicator when global refresh is happening
        if (isGlobalRefreshing) {
          return _buildRefreshingIndicator();
        }
        
        // Show small offline indicator in corner when offline (main popup handled by GlobalOfflineWrapper)
        if (!internetConnection) {
          return _buildSmallOfflineIndicator(lastSync);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildRefreshingIndicator() {
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

  Widget _buildSmallOfflineIndicator(DateTime? lastSync) {
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
}
