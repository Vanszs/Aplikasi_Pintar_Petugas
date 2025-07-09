import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

enum StatusType {
  error,
  success,
  warning,
  info
}

class StatusAnimation extends StatelessWidget {
  final StatusType type;
  final String message;
  final String? subMessage;
  final IconData? icon;
  final VoidCallback? onRetry;
  
  const StatusAnimation({
    super.key,
    required this.type,
    required this.message,
    this.subMessage,
    this.icon,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          const SizedBox(height: 20),
          _buildMessage(),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            _buildSubMessage(),
          ],
          if (onRetry != null && type == StatusType.error) ...[
            const SizedBox(height: 24),
            _buildRetryButton(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusIcon() {
    Color color;
    IconData statusIcon;
    
    switch (type) {
      case StatusType.error:
        color = const Color(0xFFEF4444);
        statusIcon = icon ?? Icons.error_outline;
        break;
      case StatusType.success:
        color = const Color(0xFF22C55E);
        statusIcon = icon ?? Icons.check_circle_outline;
        break;
      case StatusType.warning:
        color = const Color(0xFFF59E0B);
        statusIcon = icon ?? Icons.warning_amber_rounded;
        break;
      case StatusType.info:
        color = const Color(0xFF3B82F6);
        statusIcon = icon ?? Icons.info_outline;
        break;
    }
    
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        statusIcon,
        size: 40,
        color: color,
      ),
    ).animate()
      .fadeIn(duration: 400.ms)
      .then(delay: 200.ms)
      .custom(
        duration: 600.ms, 
        builder: (context, value, child) {
          // Special animation for error state - shake
          if (type == StatusType.error) {
            // Shake animation
            final shake = (value <= 0.25 || (value > 0.5 && value <= 0.75)) ? -1.0 : 1.0;
            final offsetX = shake * 5 * value * (1 - value) * 4; // Quadratic ease in/out
            return Transform.translate(offset: Offset(offsetX, 0), child: child);
          } 
          // Scale animation for others
          else {
            final scale = 0.9 + (value * 0.2);
            return Transform.scale(scale: scale, child: child);
          }
        }
      );
  }
  
  Widget _buildMessage() {
    return Text(
      message,
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2937),
      ),
      textAlign: TextAlign.center,
    ).animate().fadeIn().slideY(begin: 0.5);
  }
  
  Widget _buildSubMessage() {
    return Text(
      subMessage!,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: const Color(0xFF6B7280),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.5);
  }
  
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Coba Lagi'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.5);
  }
}
