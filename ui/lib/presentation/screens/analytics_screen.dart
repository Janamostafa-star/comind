import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/animated_background.dart';
import '../../providers/app_state.dart';
import '../../presentation/providers/auth_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _selectedPeriod = 0; // 0: Week, 1: Month, 2: All Time

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final totalHours = appState.totalStudyHours;

    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Your Progress'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: user?.avatarUrl != null
                      ? (user!.avatarUrl!.startsWith('data:')
                          ? Image.memory(
                              base64Decode(user.avatarUrl!.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user.name),
                            )
                          : Image.network(
                              user.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(user.name),
                            ))
                      : _buildAvatarPlaceholder(user?.name ?? 'G'),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1B263B),
                  Color(0xFF0A0E27),
                ],
              ),
            ),
          ),

          AnimatedBackground(
            primaryColor: AppTheme.neonCyan.withValues(alpha: 0.2),
            secondaryColor: AppTheme.neonPurple.withValues(alpha: 0.15),
            particleCount: 20,
            intensity: 0.2,
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  
                  const SizedBox(height: 24),

                  // Main focus ring
                  _buildFocusRing(totalHours),

                  const SizedBox(height: 32),

                  // Quick stats row
                  _buildQuickStats(appState),

                  const SizedBox(height: 32),

                  // Weekly activity
                  _buildWeeklyActivity(),

                  const SizedBox(height: 32),

                  // Subject breakdown
                  _buildSubjectBreakdown(),

                  const SizedBox(height: 32),

                  // Forest impact
                  _buildForestImpact(appState),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['This Week', 'This Month', 'All Time'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: periods.asMap().entries.map((entry) {
          final isSelected = _selectedPeriod == entry.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.neonCyan.withValues(alpha: 0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.4))
                      : null,
                ),
                child: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppTheme.neonCyan : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildFocusRing(double totalHours) {
    return Center(
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          // Dynamic goal: let's assume a daily goal of 2 hours for now, 
          // or just scale based on a reasonable 10h weekly milestone
          final progress = totalHours > 0 ? (totalHours / 10.0).clamp(0.0, 1.0) : 0.0;
          
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonCyan.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              
              // Custom painted ring
              CustomPaint(
                size: const Size(200, 200),
                painter: _RingPainter(
                  progress: _animController.value * progress,
                  primaryColor: AppTheme.neonCyan,
                  secondaryColor: AppTheme.neonPurple,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
              ),

              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${totalHours.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'hours studied',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildQuickStats(AppState appState) {
    final sessions = appState.sessionsCompleted;
    final streak = appState.streakDays;
    final focusScore = appState.focusScore.toInt();
    
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: Icons.psychology_rounded,
            label: 'Focus Score',
            value: focusScore > 0 ? '$focusScore%' : '--',
            color: AppTheme.neonGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Sessions',
            value: sessions > 0 ? '$sessions' : '--',
            color: AppTheme.neonCyan,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: streak > 0 ? '${streak}d' : '--',
            color: const Color(0xFFFF9F1C),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildWeeklyActivity() {
    final appState = context.watch<AppState>();
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    
    // Calculate real weekly values from backend dailyHistory
    final now = DateTime.now();
    final List<double> values = [];
    final monday = now.subtract(Duration(days: now.weekday - 1));
    
    double maxMinutes = 60.0; // Base for scaling (1 hour)
    
    for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
        final minutes = appState.dailyHistory[dateStr] ?? 0.0;
        values.add(minutes);
        if (minutes > maxMinutes) maxMinutes = minutes;
    }

    // Normalize values for the bar height (0.0 to 1.0)
    final normalizedValues = values.map((v) => maxMinutes > 0 ? (v / maxMinutes) : 0.0).toList();
    
    final hasData = values.any((v) => v > 0);
    final today = DateTime.now().weekday - 1; // 0 = Monday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Activity',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: hasData 
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (index) {
                  return _buildDayBar(days[index], normalizedValues[index], index == today);
                }),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.bar_chart_rounded, color: Colors.white24, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'Start studying to see your activity',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildDayBar(String day, double value, bool isToday) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final animatedValue = value * _animController.value;
            return Container(
              width: 28,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 28,
                  height: 80 * animatedValue,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isToday
                          ? [AppTheme.neonCyan, AppTheme.neonPurple]
                          : [
                              AppTheme.neonCyan.withValues(alpha: 0.6),
                              AppTheme.neonPurple.withValues(alpha: 0.4),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: isToday ? AppTheme.neonCyan : Colors.white60,
            fontSize: 12,
            fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectBreakdown() {
    final appState = context.watch<AppState>();
    final breakdown = appState.subjectBreakdown;
    final totalMinutes = breakdown.values.fold(0.0, (sum, m) => sum + m);
    final hasData = totalMinutes > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject Breakdown',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: hasData
            ? Column(
                children: breakdown.entries.map((entry) {
                  final color = _getSubjectColor(entry.key);
                  final percent = totalMinutes > 0 ? (entry.value / totalMinutes) : 0.0;
                  final hours = entry.value / 60;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildSubjectRow(
                      entry.key, 
                      percent, 
                      color, 
                      '${hours.toStringAsFixed(1)}h'
                    ),
                  );
                }).toList(),
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Icon(Icons.school_rounded, color: Colors.white24, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        'No subjects tracked yet',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete study sessions to see breakdown',
                        style: TextStyle(color: Colors.white24, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Color _getSubjectColor(String name) {
    // Deterministic colors based on name
    final colors = [
      AppTheme.neonCyan,
      AppTheme.neonPurple,
      AppTheme.neonGreen,
      Colors.orange,
      Colors.pink,
      Colors.amber,
    ];
    final index = name.length % colors.length;
    return colors[index];
  }

  Widget _buildSubjectRow(String name, double percent, Color color, String hours) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(name, style: const TextStyle(color: Colors.white)),
                  ],
                ),
                Text(
                  hours,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent * _animController.value,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForestImpact(AppState appState) {
    final trees = appState.forestStats?.treesPlanted ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forest Impact',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.neonGreen.withValues(alpha: 0.2),
                AppTheme.neonCyan.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.neonGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.park_rounded,
                  color: AppTheme.neonGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$trees trees grown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Each hour of focus grows your forest',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }
  Widget _buildAvatarPlaceholder(String name) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 12.0;

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring with gradient
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: math.pi * 1.5,
      colors: [primaryColor, secondaryColor, primaryColor],
    );

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
