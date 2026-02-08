import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../widgets/animated_background.dart';
import 'package:provider/provider.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/screens/dashboard_screen.dart';
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Start minimum splash duration
    final minSplashFuture = Future.delayed(AppConstants.splashDuration);
    
    // Wait for auth to be determined
    final authProvider = context.read<AuthProvider>();
    if (authProvider.status == AuthStatus.initial) {
      final completer = Completer<void>();
      void listener() {
        if (authProvider.status != AuthStatus.initial) {
          authProvider.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        }
      }
      authProvider.addListener(listener);
      
      // Double check
      if (authProvider.status != AuthStatus.initial) {
        authProvider.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      }
      
      await completer.future;
    }

    await minSplashFuture;
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layered gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.darkBackground,
                  const Color(0xFF0D1B2A),
                  const Color(0xFF1B263B),
                ],
              ),
            ),
          ),

          // Animated particle background
          AnimatedBackground(
            particleCount: 80,
            showConnections: true,
            primaryColor: AppTheme.neonCyan.withValues(alpha: 0.6),
            secondaryColor: AppTheme.neonPurple.withValues(alpha: 0.4),
            intensity: 0.5,
          ),

          // Floating study elements
          ..._buildFloatingElements(),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium logo with orbital rings
                _buildLogo(),

                const SizedBox(height: 48),

                // App Name with gradient text
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.white,
                      AppTheme.neonCyan.withValues(alpha: 0.9),
                    ],
                  ).createShader(bounds),
                  child: Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 800.ms)
                    .slideY(begin: 0.2, end: 0, duration: 800.ms),

                const SizedBox(height: 16),

                // Tagline with subtle glow
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary.withValues(alpha: 0.8),
                          fontSize: 16,
                          letterSpacing: 0.5,
                          height: 1.5,
                        ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 900.ms, duration: 800.ms)
                    .slideY(begin: 0.15, end: 0, duration: 800.ms),

                const SizedBox(height: 80),

                // Premium loading indicator
                _buildLoadingIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring
            Container(
              width: 160 + (pulseValue * 20),
              height: 160 + (pulseValue * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2 - (pulseValue * 0.1)),
                  width: 1,
                ),
              ),
            ),
            // Middle glow ring
            Container(
              width: 140 + (pulseValue * 10),
              height: 140 + (pulseValue * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonPurple.withValues(alpha: 0.3 - (pulseValue * 0.15)),
                  width: 1.5,
                ),
              ),
            ),
            // Main logo container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.neonCyan,
                    AppTheme.neonPurple,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.4 + (pulseValue * 0.2)),
                    blurRadius: 40 + (pulseValue * 20),
                    spreadRadius: 5 + (pulseValue * 5),
                  ),
                  BoxShadow(
                    color: AppTheme.neonPurple.withValues(alpha: 0.3),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1, 1),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .shimmer(
          duration: 2000.ms,
          color: Colors.white.withValues(alpha: 0.2),
        );
  }

  List<Widget> _buildFloatingElements() {
    return [
      // Floating book
      _buildFloatingIcon(
        Icons.menu_book_rounded,
        left: 40,
        top: 150,
        size: 28,
        color: AppTheme.neonCyan.withValues(alpha: 0.4),
        delay: 0,
      ),
      // Floating lightbulb
      _buildFloatingIcon(
        Icons.lightbulb_outline_rounded,
        right: 50,
        top: 200,
        size: 24,
        color: const Color(0xFFFFD700).withValues(alpha: 0.4),
        delay: 0.3,
      ),
      // Floating pencil
      _buildFloatingIcon(
        Icons.edit_rounded,
        left: 60,
        bottom: 200,
        size: 22,
        color: AppTheme.neonGreen.withValues(alpha: 0.4),
        delay: 0.5,
      ),
      // Floating graduation cap
      _buildFloatingIcon(
        Icons.school_rounded,
        right: 40,
        bottom: 250,
        size: 26,
        color: AppTheme.neonPurple.withValues(alpha: 0.4),
        delay: 0.7,
      ),
      // Floating star
      _buildFloatingIcon(
        Icons.star_rounded,
        left: 80,
        top: 350,
        size: 20,
        color: Colors.amber.withValues(alpha: 0.3),
        delay: 0.4,
      ),
      // Floating brain
      _buildFloatingIcon(
        Icons.psychology_rounded,
        right: 70,
        top: 380,
        size: 24,
        color: AppTheme.neonBlue.withValues(alpha: 0.35),
        delay: 0.6,
      ),
    ];
  }

  Widget _buildFloatingIcon(
    IconData icon, {
    double? left,
    double? right,
    double? top,
    double? bottom,
    required double size,
    required Color color,
    required double delay,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _floatController,
        child: Icon(
          icon,
          size: size,
          color: color,
        ).animate().fadeIn(
          delay: Duration(milliseconds: (delay * 1000).toInt()),
          duration: 1000.ms,
        ),
        builder: (context, child) {
          final floatOffset = math.sin(_floatController.value * math.pi * 2 + delay * math.pi) * 15;
          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        // Custom animated dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.neonCyan,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              )
                  .animate(
                    onPlay: (controller) => controller.repeat(),
                  )
                  .fadeIn(delay: Duration(milliseconds: 1200 + (index * 150)))
                  .then()
                  .scaleXY(
                    begin: 1,
                    end: 1.5,
                    duration: 600.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scaleXY(
                    begin: 1.5,
                    end: 1,
                    duration: 600.ms,
                    curve: Curves.easeInOut,
                  ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text(
          'Preparing your space...',
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.6),
            fontSize: 12,
            letterSpacing: 1,
          ),
        )
            .animate()
            .fadeIn(delay: 1400.ms, duration: 600.ms),
      ],
    );
  }
}
