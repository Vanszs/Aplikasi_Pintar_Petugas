import 'package:flutter/material.dart';
import 'dart:math' as math;

class WaveBackground extends StatefulWidget {
  final Color color1;
  final Color color2;
  final Color? color3;
  
  const WaveBackground({
    super.key,
    required this.color1,
    required this.color2,
    this.color3,
  });
  
  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
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
        return RepaintBoundary(
          child: CustomPaint(
            painter: _WavePainter(
              animationValue: _animationController.value,
              color1: widget.color1,
              color2: widget.color2,
              color3: widget.color3,
            ),
            child: child,
          ),
        );
      },
      child: const SizedBox.expand(),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double animationValue;
  final Color color1;
  final Color color2;
  final Color? color3;
  
  const _WavePainter({
    required this.animationValue,
    required this.color1,
    required this.color2,
    this.color3,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Draw wave 1
    final path1 = Path();
    final y1 = size.height * 0.8;
    path1.moveTo(0, y1);
    
    for (int i = 0; i < size.width.toInt(); i++) {
      final dx = i.toDouble();
      final dy = y1 + 
          math.sin((dx * 0.01) + (animationValue * math.pi * 2)) * 10.0 +
          math.sin((dx * 0.02) - (animationValue * math.pi * 2)) * 15.0;
      path1.lineTo(dx, dy);
    }
    
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    
    paint.color = color1.withAlpha(204);
    canvas.drawPath(path1, paint);
    
    // Draw wave 2
    final path2 = Path();
    final y2 = size.height * 0.85;
    path2.moveTo(0, y2);
    
    for (int i = 0; i < size.width.toInt(); i++) {
      final dx = i.toDouble();
      final dy = y2 + 
          math.sin((dx * 0.015) - (animationValue * math.pi * 2)) * 15.0 +
          math.sin((dx * 0.025) + (animationValue * math.pi * 2)) * 10.0;
      path2.lineTo(dx, dy);
    }
    
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    
    paint.color = color2.withAlpha(153);
    canvas.drawPath(path2, paint);
    
    // Draw wave 3 if color3 is provided
    if (color3 != null) {
      final path3 = Path();
      final y3 = size.height * 0.9;
      path3.moveTo(0, y3);
      
      for (int i = 0; i < size.width.toInt(); i++) {
        final dx = i.toDouble();
        final dy = y3 + 
            math.sin((dx * 0.02) + (animationValue * math.pi * 2)) * 8.0 +
            math.sin((dx * 0.01) - (animationValue * math.pi * 2)) * 12.0;
        path3.lineTo(dx, dy);
      }
      
      path3.lineTo(size.width, size.height);
      path3.lineTo(0, size.height);
      path3.close();
      
      paint.color = color3!.withAlpha(102);
      canvas.drawPath(path3, paint);
    }
  }
  
  @override
  bool shouldRepaint(_WavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
