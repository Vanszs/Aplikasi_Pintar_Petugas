import 'package:flutter/material.dart';
import 'dart:math' as math;

class ModernGraphicBackground extends StatefulWidget {
  final Color color1;
  final Color color2;

  const ModernGraphicBackground({
    super.key,
    required this.color1,
    required this.color2,
  });

  @override
  State<ModernGraphicBackground> createState() => _ModernGraphicBackgroundState();
}

class _ModernGraphicBackgroundState extends State<ModernGraphicBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_animationController, _pulseController]),
      builder: (context, child) {
        return Stack(
          children: [
            // Base gradient with subtle animation
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color1,
                    widget.color2,
                    widget.color1.withAlpha(204),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            
            // Dynamic geometric patterns
            Positioned.fill(
              child: CustomPaint(
                painter: _ModernPatternPainter(
                  color1: widget.color1,
                  color2: widget.color2,
                  animationValue: _animationController.value,
                  pulseValue: _pulseController.value,
                ),
              ),
            ),

            // Floating orbs with parallax effect
            Positioned.fill(
              child: _buildFloatingOrbs(),
            ),

            // Mesh gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topRight,
                    radius: 1.5,
                    colors: [
                      Colors.white.withAlpha(26),
                      Colors.transparent,
                      widget.color1.withAlpha(51),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingOrbs() {
    return Stack(
      children: [
        // Large orb
        Positioned(
          top: 50 + math.sin(_animationController.value * 2 * math.pi) * 20,
          right: 60 + math.cos(_animationController.value * 2 * math.pi) * 15,
          child: Container(
            width: 150 + _pulseController.value * 30,
            height: 150 + _pulseController.value * 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withAlpha(38),
                  Colors.white.withAlpha(13),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Medium orb
        Positioned(
          top: 200 + math.cos(_animationController.value * 1.5 * math.pi) * 25,
          left: 40 + math.sin(_animationController.value * 1.5 * math.pi) * 20,
          child: Container(
            width: 100 + _pulseController.value * 20,
            height: 100 + _pulseController.value * 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withAlpha(51),
                  Colors.white.withAlpha(20),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Small orb
        Positioned(
          bottom: 150 + math.sin(_animationController.value * 3 * math.pi) * 15,
          right: 100 + math.cos(_animationController.value * 2.5 * math.pi) * 10,
          child: Container(
            width: 60 + _pulseController.value * 10,
            height: 60 + _pulseController.value * 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withAlpha(64),
                  Colors.white.withAlpha(26),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernPatternPainter extends CustomPainter {
  final Color color1;
  final Color color2;
  final double animationValue;
  final double pulseValue;

  const _ModernPatternPainter({
    required this.color1,
    required this.color2,
    required this.animationValue,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw animated wave patterns
    _drawAnimatedWaves(canvas, size);
    
    // Draw geometric shapes with rotation
    _drawRotatingShapes(canvas, size);
    
    // Draw flowing lines
    _drawFlowingLines(canvas, size);
  }

  void _drawAnimatedWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    const waveHeight = 30.0;
    const waveLength = 200.0;

    for (int i = 0; i < 3; i++) {
      path.reset();
      final yOffset = size.height * 0.3 + (i * 60);
      final phase = animationValue * 2 * math.pi + (i * math.pi / 3);

      path.moveTo(0, yOffset);
      
      for (double x = 0; x <= size.width; x += 5) {
        final y = yOffset + math.sin((x / waveLength) * 2 * math.pi + phase) * waveHeight;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  void _drawRotatingShapes(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.fill;

    canvas.save();
    
    // Rotating hexagon
    final hexCenter = Offset(size.width * 0.8, size.height * 0.6);
    canvas.translate(hexCenter.dx, hexCenter.dy);
    canvas.rotate(animationValue * 2 * math.pi);
    
    final hexPath = Path();
    const hexRadius = 40.0;
    
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x = hexRadius * math.cos(angle);
      final y = hexRadius * math.sin(angle);
      
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    
    canvas.drawPath(hexPath, paint);
    canvas.restore();

    // Rotating triangle
    canvas.save();
    final triCenter = Offset(size.width * 0.2, size.height * 0.8);
    canvas.translate(triCenter.dx, triCenter.dy);
    canvas.rotate(-animationValue * 1.5 * math.pi);
    
    final triPath = Path();
    const triRadius = 25.0;
    
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi) / 3;
      final x = triRadius * math.cos(angle);
      final y = triRadius * math.sin(angle);
      
      if (i == 0) {
        triPath.moveTo(x, y);
      } else {
        triPath.lineTo(x, y);
      }
    }
    triPath.close();
    
    canvas.drawPath(triPath, paint);
    canvas.restore();
  }

  void _drawFlowingLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Flowing curves
    for (int i = 0; i < 4; i++) {
      final path = Path();
      final startX = (size.width / 4) * i;
      final phase = animationValue * math.pi + (i * math.pi / 2);
      
      path.moveTo(startX, 0);
      
      for (double t = 0; t <= 1; t += 0.01) {
        final x = startX + (size.width * 0.3 * t);
        final y = size.height * t + math.sin(t * 4 * math.pi + phase) * 20;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ModernPatternPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.pulseValue != pulseValue;
  }
}
