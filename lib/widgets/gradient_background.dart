import 'package:flutter/material.dart';
import 'dart:math' as math;

class GradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;

  const GradientBackground({
    super.key, 
    required this.child,
    this.colors,
  });

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 30), 
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        // Back to brighter gradient background
        return Container(
          decoration: BoxDecoration(
            // Brighter gradient color scheme
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors ?? [
                const Color(0xFFF8FAFC),  // Light blue-gray
                const Color(0xFFD9EAFD),  // Light blue
                const Color(0xFFBCCCDC),  // Medium blue-gray
                const Color(0xFF9AA6B2),  // Darker blue-gray
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Minimalist vector patterns
              _buildMinimalistVectorPatterns(_animationController.value),
              
              // Content
              widget.child,
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildMinimalistVectorPatterns(double animationValue) {
    return Stack(
      children: [
        // Simplified vector patterns with CustomPaint
        Positioned.fill(
          child: CustomPaint(
            painter: _MinimalistVectorPainter(animationValue),
          ),
        ),
        
        // Just a few floating shapes for interest - increased opacity for better visibility
        ..._buildFloatingShapes(animationValue),
      ],
    );
  }
  
  List<Widget> _buildFloatingShapes(double animationValue) {
    return [
      // Top-right triangle - keep just one
      Positioned(
        top: -30 + math.sin(animationValue * 2 * math.pi) * 15,
        right: 20 + math.cos(animationValue * 2 * math.pi) * 15,
        child: _buildTriangle(
          const Color(0xFFA78BFA), // Lighter purple for contrast on dark background
          90, // Larger size
          animationValue * 2 * math.pi,
        ),
      ),
      
      // Bottom-left circle - keep just one
      Positioned(
        bottom: 100 + math.sin((animationValue + 0.6) * 2 * math.pi) * 20,
        left: 20 + math.cos((animationValue + 0.6) * 2 * math.pi) * 15,
        child: _buildCircle(
          const Color(0xFF5EEAD4), // Lighter teal for contrast
          120, // Larger size
        ),
      ),
    ];
  }
  
  Widget _buildTriangle(Color color, double size, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: CustomPaint(
        size: Size(size, size),
        painter: _TrianglePainter(color.withOpacity(0.3)), // Increased opacity for visibility
      ),
    );
  }
  
  Widget _buildCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.3), // Increased opacity for visibility
            color.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
      ),
    );
  }
}

// Simplified vector painter with minimal patterns - adjusted for dark background
class _MinimalistVectorPainter extends CustomPainter {
  final double animationValue;
  
  _MinimalistVectorPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw just a few subtle curves
    _drawMinimalCurves(canvas, size);
  }
  
  void _drawMinimalCurves(Canvas canvas, Size size) {
    final paints = [
      Paint()
        ..color = const Color(0xFFA78BFA).withOpacity(0.25) // Lighter purple for visibility
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
      Paint()
        ..color = const Color(0xFF5EEAD4).withOpacity(0.2) // Lighter teal for visibility
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    ];
    
    // Draw only two waves instead of three
    for (int i = 0; i < paints.length; i++) {
      final path = Path();
      // Position them further apart
      final startY = size.height * (0.2 + i * 0.5); 
      final amplitude = 30.0 - (i * 5.0);
      final frequency = 0.003 + (i * 0.002); // Lower frequency means fewer waves
      final phaseShift = animationValue * math.pi * 2 * (1 - i * 0.3);
      
      path.moveTo(0, startY);
      
      // Increase step to make smoother curves with fewer points
      for (double x = 0; x <= size.width; x += 3) {
        final y = startY + math.sin(x * frequency + phaseShift) * amplitude;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paints[i]);
    }
  }
  
  @override
  bool shouldRepaint(_MinimalistVectorPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// Triangle painter - keep this helper class
class _TrianglePainter extends CustomPainter {
  final Color color;
  
  _TrianglePainter(this.color);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
