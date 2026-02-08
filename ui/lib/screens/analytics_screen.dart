import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';

import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final stats = appState.forestStats;
        final totalMinutes = stats?.totalFocusMinutes ?? 0;
        final streak = stats?.currentStreakDays ?? 0;
        final trees = stats?.treesPlanted ?? 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Analytics & Focus'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Learning Journey',
                    style: Theme.of(context).textTheme.displayMedium,
                  ).animate().fadeIn(duration: 600.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Focus Score / Stats
                  _FocusScoreCard(
                    minutes: totalMinutes,
                    streak: streak,
                    trees: trees,
                  ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),
                  
                  const SizedBox(height: 24),
                  
                  // Weekly Stats (Still Mock for now as we don't have historical data structure yet, but good enough)
                  const _WeeklyChart().animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 24),
                  
                  // Subject Breakdown
                  Text(
                    'Subject Breakdown',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 16),
                  
                  ...[
                    _SubjectProgressBar('Mathematics', 0.85, AppTheme.neonCyan),
                    _SubjectProgressBar('Physics', 0.72, AppTheme.neonPurple),
                    _SubjectProgressBar('Chemistry', 0.68, AppTheme.neonGreen),
                  ]
                      .asMap()
                      .entries
                      .map((e) => e.value.animate(delay: (700 + e.key * 100).ms).fadeIn().slideX(begin: 0.2, end: 0))
                      .toList(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FocusScoreCard extends StatelessWidget {
  final int minutes;
  final int streak;
  final int trees;

  const _FocusScoreCard({
    required this.minutes,
    required this.streak,
    required this.trees,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonCyan.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
         children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 _StatItem(
                   label: 'Total Focus',
                   value: '$minutes m',
                   icon: Icons.timer,
                 ),
                 _StatItem(
                   label: 'Streak',
                   value: '$streak Days',
                   icon: Icons.local_fire_department,
                 ),
                 _StatItem(
                   label: 'Trees',
                   value: '$trees',
                   icon: Icons.park,
                 ),
              ],
            ),
         ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
     return Column(
       children: [
         Icon(icon, color: Colors.white70, size: 24),
         SizedBox(height: 8),
         Text(
           value,
           style: Theme.of(context).textTheme.headlineSmall?.copyWith(
             color: Colors.white,
             fontWeight: FontWeight.bold,
           ),
         ),
         Text(
           label,
           style: TextStyle(color: Colors.white70, fontSize: 12),
         ),
       ],
     );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Time This Week',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBarGroup(0, 2.5),
                  _makeBarGroup(1, 3.2),
                  _makeBarGroup(2, 1.8),
                  _makeBarGroup(3, 4.1),
                  _makeBarGroup(4, 3.5),
                  _makeBarGroup(5, 2.2),
                  _makeBarGroup(6, 1.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppTheme.primaryGradient,
          width: 20,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }
}

class _SubjectProgressBar extends StatelessWidget {
  final String subject;
  final double progress;
  final Color color;

  const _SubjectProgressBar(this.subject, this.progress, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.darkSurface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
