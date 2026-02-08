import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProceduralTree extends StatelessWidget {
  final String type; // 'oak', 'pine', 'sakura'
  final double growth; // 0.0 to 1.0
  final double size;

  const ProceduralTree({
    super.key,
    required this.type,
    this.growth = 1.0,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: TreePainter(
          type: type,
          growth: growth,
        ),
      ),
    );
  }
}

class TreePainter extends CustomPainter {
  final String type;
  final double growth;

  TreePainter({required this.type, required this.growth});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height;
    
    // Growth scale affects the overall height and spread
    final scale = growth;
    
    // Draw Trunk
    _drawTrunk(canvas, centerX, bottomY, size.height * 0.6 * scale);

    // Draw Foliage based on type
    if (type == 'pine') {
      _drawPineFoliage(canvas, centerX, bottomY - (size.height * 0.2 * scale), size.width * scale);
    } else if (type == 'sakura') {
      _drawOakFoliage(canvas, centerX, bottomY - (size.height * 0.4 * scale), size.width * scale, color: const Color(0xFFFFB7CE)); // Pink Sakura
    } else if (type == 'willow') {
      _drawWillowFoliage(canvas, centerX, bottomY - (size.height * 0.3 * scale), size.width * scale);
    } else if (type == 'crystal') {
      _drawCrystalFoliage(canvas, centerX, bottomY - (size.height * 0.4 * scale), size.width * scale);
    } else {
      // Oak / Default
      _drawOakFoliage(canvas, centerX, bottomY - (size.height * 0.4 * scale), size.width * scale);
    }
  }

  void _drawTrunk(Canvas canvas, double x, double y, double height) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF5D4037), const Color(0xFF3E2723)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(x - (height * 0.1), y - height, height * 0.2, height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(x - (height * 0.1), y); // Bottom left
    path.lineTo(x + (height * 0.1), y); // Bottom right
    path.lineTo(x + (height * 0.05), y - height); // Top right (thinner)
    path.lineTo(x - (height * 0.05), y - height); // Top left (thinner)
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawPineFoliage(Canvas canvas, double x, double bottomY, double width) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;
      
    // Pine consists of 3 stacked triangles
    final segmentHeight = width * 0.6;
    
    for (int i = 0; i < 3; i++) {
        final currentWidth = width * (1.0 - (i * 0.2));
        final currentBottom = bottomY - (i * (segmentHeight * 0.6));
        
        final path = Path();
        path.moveTo(x - (currentWidth / 2), currentBottom);
        path.lineTo(x + (currentWidth / 2), currentBottom);
        path.lineTo(x, currentBottom - segmentHeight);
        path.close();
        
        canvas.drawPath(path, paint);
    }
  }

  void _drawOakFoliage(Canvas canvas, double x, double y, double width, {Color? color}) {
    final baseColor = color ?? const Color(0xFF4CAF50);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [baseColor, baseColor.withValues(alpha: 0.8)],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: width / 2))
      ..style = PaintingStyle.fill;
    
    // Oak/Sakura consists of multiple circles (bubbles)
    canvas.drawCircle(Offset(x, y - (width * 0.2)), width * 0.35, paint);
    canvas.drawCircle(Offset(x - (width * 0.25), y), width * 0.25, paint);
    canvas.drawCircle(Offset(x + (width * 0.25), y), width * 0.25, paint);
    canvas.drawCircle(Offset(x, y - (width * 0.5)), width * 0.25, paint);
  }

  void _drawWillowFoliage(Canvas canvas, double x, double y, double width) {
    final paint = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draping branches
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final startX = x + math.cos(angle) * (width * 0.2);
      final startY = y + math.sin(angle) * (width * 0.2);
      
      final path = Path();
      path.moveTo(startX, startY);
      path.quadraticBezierTo(
        startX + (i % 2 == 0 ? 10 : -10), 
        startY + (width * 0.4), 
        startX, 
        startY + (width * 0.6)
      );
      canvas.drawPath(path, paint);
    }
    
    // Top mass
    final topPaint = Paint()
      ..color = const Color(0xFF66BB6A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), width * 0.3, topPaint);
  }

  void _drawCrystalFoliage(Canvas canvas, double x, double y, double width) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, const Color(0xFFB3E5FC), Colors.transparent],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(x, y - (width * 0.3)), radius: width * 0.6))
      ..style = PaintingStyle.fill;

    // A glowing orb with floating fragments
    canvas.drawCircle(Offset(x, y - (width * 0.3)), width * 0.4, paint);
    
    final accentPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    for (int i = 0; i < 5; i++) {
        final angle = (i * 72) * math.pi / 180;
        final dx = x + math.cos(angle) * (width * 0.5);
        final dy = y - (width * 0.3) + math.sin(angle) * (width * 0.5);
        canvas.drawRect(Rect.fromCenter(center: Offset(dx, dy), width: 4, height: 4), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
