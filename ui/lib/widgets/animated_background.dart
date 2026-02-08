import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../providers/visual_state_provider.dart';
import 'dart:ui' as ui;

class Particle {
  Offset position;
  Offset velocity;
  double size;
  double opacity;
  Color color;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.opacity,
    required this.color,
  });
}

/// Animated background with floating particles and reactive behavior
class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final int particleCount;
  final bool showConnections;
  final bool reactive;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double intensity; // 0.0 to 1.0
  final bool aiSpeaking;
  final bool handRaised;
  
  const AnimatedBackground({
    super.key,
    this.child,
    this.particleCount = 50,
    this.showConnections = false,
    this.reactive = true,
    this.primaryColor,
    this.secondaryColor,
    this.intensity = 0.5,
    this.aiSpeaking = false,
    this.handRaised = false,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _controller;
  late Size _size;
  double _gradientRotation = 0.0;
  Timer? _gradientTimer;

  @override
  void initState() {
    super.initState();
    particles = [];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..repeat();
    
    _gradientTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {
          _gradientRotation += 0.001;
          if (_gradientRotation > 2 * math.pi) _gradientRotation = 0;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _size = MediaQuery.of(context).size;
    if (particles.isEmpty) {
      _initializeParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _gradientTimer?.cancel();
    super.dispose();
  }

  void _initializeParticles() {
    final random = math.Random();
    final theme = Theme.of(context);
    particles = List.generate(widget.particleCount, (index) {
      return Particle(
        position: Offset(
          random.nextDouble() * _size.width,
          random.nextDouble() * _size.height,
        ),
        velocity: Offset(
          (random.nextDouble() - 0.5) * 0.5,
          (random.nextDouble() - 0.5) * 0.5,
        ),
        size: random.nextDouble() * 4 + 2,
        opacity: random.nextDouble() * 0.5 + 0.3,
        color: random.nextBool() 
          ? (widget.primaryColor ?? theme.colorScheme.primary) 
          : (widget.secondaryColor ?? theme.colorScheme.secondary),
      );
    });
  }

  void _updateParticles(VisualStateProvider visualState) {
    if (_size.width == 0 || _size.height == 0) return;
    if (!visualState.isMotionEnabled) return;

    double speedMultiplier = visualState.dynamicMode == DynamicMode.softDrift ? 0.5 : 1.0;
    
    if (visualState.dynamicMode == DynamicMode.antiGravity) {
      speedMultiplier = 1.5;
    }

    if (widget.reactive) {
      if (widget.aiSpeaking) speedMultiplier *= 2.0;
      else if (widget.handRaised) speedMultiplier *= 0.3;
    }

    if (visualState.blendMode == BlendModeType.dimMotion) {
      speedMultiplier *= 0.5;
    }
    
    for (var particle in particles) {
      particle.position = Offset(
        particle.position.dx + particle.velocity.dx * speedMultiplier,
        particle.position.dy + particle.velocity.dy * speedMultiplier,
      );
      
      if (particle.position.dx < 0) particle.position = Offset(_size.width, particle.position.dy);
      else if (particle.position.dx > _size.width) particle.position = Offset(0, particle.position.dy);
      
      if (particle.position.dy < 0) particle.position = Offset(particle.position.dx, _size.height);
      else if (particle.position.dy > _size.height) particle.position = Offset(particle.position.dx, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visualState = context.watch<VisualStateProvider>();
    final theme = Theme.of(context);

    Widget background = Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(math.cos(_gradientRotation), math.sin(_gradientRotation)),
              end: Alignment(-math.cos(_gradientRotation), -math.sin(_gradientRotation)),
              colors: [
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
                theme.cardColor.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        if (visualState.isMotionEnabled)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              _updateParticles(visualState);
              return CustomPaint(
                painter: BackgroundPainter(
                  particles: particles,
                  showConnections: widget.showConnections || visualState.dynamicMode == DynamicMode.thinkWithMe,
                  connectionDistance: visualState.dynamicMode == DynamicMode.thinkWithMe ? 150 : 120,
                  opacityMultiplier: visualState.blendMode == BlendModeType.dimMotion ? 0.3 : 1.0,
                  dynamicMode: visualState.dynamicMode,
                  primaryColor: widget.primaryColor ?? theme.colorScheme.primary,
                ),
                size: Size.infinite,
              );
            },
          ),
      ],
    );

    // Apply Blend Modes
    if (visualState.blendMode == BlendModeType.softBlur) {
      background = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: background,
      );
    } else if (visualState.blendMode == BlendModeType.monochrome) {
      background = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]),
        child: background,
      );
    }

    return Stack(
      children: [
        background,
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final List<Particle> particles;
  final bool showConnections;
  final double connectionDistance;
  final double opacityMultiplier;
  final DynamicMode dynamicMode;
  final Color primaryColor;
  
  BackgroundPainter({
    required this.particles,
    required this.showConnections,
    required this.connectionDistance,
    this.opacityMultiplier = 1.0,
    required this.dynamicMode,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dynamicMode == DynamicMode.forestSky) {
      _paintForestSky(canvas, size);
      return;
    }

    final theme = Paint()..strokeWidth = 0.5..style = PaintingStyle.stroke;
    
    for (int i = 0; i < particles.length; i++) {
      if (showConnections) {
        for (int j = i + 1; j < particles.length; j++) {
          final distance = (particles[i].position - particles[j].position).distance;
          if (distance < connectionDistance) {
            double opacity = (1 - distance / connectionDistance) * 0.3 * opacityMultiplier;
            
            // Neural network mode lines are a bit more prominent
            if (dynamicMode == DynamicMode.thinkWithMe) {
              opacity *= 1.5;
              theme.strokeWidth = 1.0;
            } else {
              theme.strokeWidth = 0.5;
            }

            canvas.drawLine(
              particles[i].position,
              particles[j].position,
              theme..color = particles[i].color.withValues(alpha: opacity),
            );
          }
        }
      }
      
      final paint = Paint()
        ..color = particles[i].color.withValues(alpha: particles[i].opacity * opacityMultiplier)
        ..style = PaintingStyle.fill;
      
      // Different shapes for different modes
      if (dynamicMode == DynamicMode.thinkWithMe) {
        // Draw squares/nodes for neural network
        canvas.drawRect(
          Rect.fromCenter(center: particles[i].position, width: particles[i].size * 1.5, height: particles[i].size * 1.5),
          paint,
        );
      } else {
        // Default circles
        final glowPaint = Paint()
          ..color = particles[i].color.withValues(alpha: particles[i].opacity * 0.2 * opacityMultiplier)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
        canvas.drawCircle(particles[i].position, particles[i].size * 2, glowPaint);
        canvas.drawCircle(particles[i].position, particles[i].size, paint);
      }
    }
  }

  void _paintForestSky(Canvas canvas, Size size) {
    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 100 + 50;
      
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.1 * opacityMultiplier),
            primaryColor.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
        
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
