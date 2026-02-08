import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Particle orbit animation widget for AI avatar thinking state
class ParticleOrbit extends StatefulWidget {
  final double size;
  final Color particleColor;
  final int particleCount;
  final Duration duration;
  
  const ParticleOrbit({
    super.key,
    this.size = 100,
    this.particleColor = AppTheme.neonCyan,
    this.particleCount = 8,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<ParticleOrbit> createState() => _ParticleOrbitState();
}

class _ParticleOrbitState extends State<ParticleOrbit>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _OrbitPainter(
              progress: _controller.value,
              particleCount: widget.particleCount,
              particleColor: widget.particleColor,
            ),
          );
        },
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  final double progress;
  final int particleCount;
  final Color particleColor;
  
  _OrbitPainter({
    required this.progress,
    required this.particleCount,
    required this.particleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    
    // Draw orbit path
    final orbitPaint = Paint()
      ..color = particleColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    
    canvas.drawCircle(center, radius, orbitPaint);
    
    // Draw particles
    final particlePaint = Paint()
      ..color = particleColor
      ..style = PaintingStyle.fill;
    
    final glowPaint = Paint()
      ..color = particleColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    
    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * math.pi / particleCount) * i + (progress * 2 * math.pi);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final particlePos = Offset(x, y);
      
      // Glow
      canvas.drawCircle(particlePos, 4, glowPaint);
      // Particle
      canvas.drawCircle(particlePos, 2, particlePaint);
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => true;
}
