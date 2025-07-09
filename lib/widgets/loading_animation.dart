import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final String? message;
  final bool showBackground;
  
  const LoadingAnimation({
    super.key, 
    this.size = 50.0,
    this.color = const Color(0xFF6366F1),
    this.message,
    this.showBackground = true,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: widget.showBackground ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ) : null,
              padding: widget.showBackground ? const EdgeInsets.all(12) : null,
              child: CustomPaint(
                painter: _LoadingIndicatorPainter(
                  progress: _animation.value,
                  color: widget.color,
                ),
                size: Size.square(widget.size),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _LoadingIndicatorPainter extends CustomPainter {
  final double progress;
  final Color color;

  _LoadingIndicatorPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw background circle
    final backgroundPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    
    canvas.drawCircle(center, radius - 2, backgroundPaint);
    
    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -0.5 * 3.14159, // Start from top
      progress * 2 * 3.14159, // Full circle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_LoadingIndicatorPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
