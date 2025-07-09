import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/report_provider.dart';

class ReportButton extends ConsumerStatefulWidget {
  final VoidCallback? onReportSuccess;

  const ReportButton({
    super.key,
    this.onReportSuccess,
  });

  @override
  ConsumerState<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends ConsumerState<ReportButton>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);
    final isLoading = reportState.isLoading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () async {
                final success =
                    await ref.read(reportProvider.notifier).sendReport(
                      jenisLaporan: 'kemalingan', // Default to kemalingan for quick report button
                      useAccountData: true, // Always use account data for quick report button
                    );

                if (success && context.mounted) {
                  if (widget.onReportSuccess != null) {
                    widget.onReportSuccess!();
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Laporan berhasil dikirim! 🚨',
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Icon(
                          Icons.campaign_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(
                  delay: 2.seconds,
                  duration: 1.seconds,
                  color: Colors.white.withAlpha(77)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'LAPOR DARURAT',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Tekan jika melihat kejadian',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withAlpha(230),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
