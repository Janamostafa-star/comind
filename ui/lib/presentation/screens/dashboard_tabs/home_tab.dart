import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import 'package:share_plus/share_plus.dart';
import '../../../widgets/glassmorphism_card.dart';
import '../../../widgets/animated_background.dart';
import '../../../domain/models/extended_models.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/screens/google_meet_style_meeting.dart';
import '../../../domain/models/scheduled_session_model.dart';
import '../../../presentation/providers/session_provider.dart';
import '../schedule_session_screen.dart';
import '../analytics_screen.dart';
import '../dashboard_tabs/focus_forest_tab.dart';
import '../notes_summary_screen.dart';
import '../note_detail_screen.dart';
import '../calendar_screen.dart';
import '../../screens/join_session_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  List<ScheduledSession> _sessions = [];
  bool _isLoading = true;
  DateTime _currentTime = DateTime.now();
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _loadSessions();
    // Update time every minute
    Future.doWhile(() async {
      await Future.delayed(const Duration(minutes: 1));
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
        return true;
      }
      return false;
    });
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final sessions = await sessionProvider.getUserSessions(userId);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading sessions: $e');
      }
    }
  }

  Future<void> _navigateToSchedule() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleSessionScreen()),
    );

    if (result == true) {
      _loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Student';
    final greeting = _getGreeting();

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background
          // Dynamic background from Theme
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),

          // Subtle animated background
          AnimatedBackground(
            primaryColor: AppTheme.neonCyan.withValues(alpha: 0.3),
            secondaryColor: AppTheme.neonPurple.withValues(alpha: 0.2),
            particleCount: 25,
            intensity: 0.3,
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadSessions,
              color: AppTheme.neonCyan,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Premium Time & Date Header Card
                  SliverToBoxAdapter(
                    child: _buildPremiumTimeCard(greeting, userName),
                  ),

                  // AI Coach Tip Widget
                  SliverToBoxAdapter(
                    child: _buildAiCoachWidget(),
                  ),

                  // Quick Action Buttons with premium design
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: Consumer<AppState>(
                        builder: (context, appState, child) {
                          final notesCount = appState.savedNotes.length + appState.notes.length;
                          final seedsCount = appState.forest?.seeds ?? 0;
                          return _buildQuickActions(notesCount, seedsCount);
                        },
                      ),
                    ),
                  ),

                  // Upcoming Sessions Section
                  if (_sessions.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming Sessions',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                            TextButton(
                              onPressed: _navigateToSchedule,
                              child: Text(
                                'New',
                                style: TextStyle(color: AppTheme.neonCyan),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Sessions List or Empty State
                  if (_isLoading)
                    SliverFillRemaining(
                      child: Center(
                        child: _buildLoadingState(),
                      ),
                    )
                  else if (_sessions.isEmpty)
                    const SliverToBoxAdapter(child: SizedBox(height: 20)) // Hiding empty state as requested
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final session = _sessions[index];
                            return _buildSessionCard(session, index);
                          },
                          childCount: _sessions.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 5) return 'Late Night Hustle?';
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    if (hour < 21) return 'Good Evening,';
    return 'Good Night,';
  }



  Widget _buildPremiumTimeCard(String greeting, String userName) {
    final authProvider = context.watch<AuthProvider>();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Subtle background pattern
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  painter: _TimeCardPatternPainter(
                    progress: 0.5, // Static
                    primaryColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    secondaryColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting with subtle icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Row(
                            children: [
                              // Profile Picture next to greeting
                              Container(
                                width: 45,
                                height: 45,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: authProvider.user?.avatarUrl != null
                                      ? (authProvider.user!.avatarUrl!.startsWith('data:')
                                          ? Image.memory(
                                              base64Decode(authProvider.user!.avatarUrl!.split(',').last),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(userName),
                                            )
                                          : Image.network(
                                              authProvider.user!.avatarUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(userName),
                                            ))
                                      : _buildAvatarPlaceholder(userName),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      greeting,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ),
                      const SizedBox(width: 8),

                    ],
                  ).animate().fadeIn().slideX(begin: -0.1),

                  const SizedBox(height: 20),

                  // Large time display
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        DateFormat('hh:mm').format(_currentTime),
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w200,
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1,
                          shadows: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('a').format(_currentTime),
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.neonCyan,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 8),

                  // Date display
                  Text(
                    DateFormat('EEEE, MMMM d').format(_currentTime),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 16),

                  // Motivational quote
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.neonCyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMotivationalQuote(),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.neonCyan.withValues(alpha: 0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  IconData _getGreetingIcon() {
    final hour = _currentTime.hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  String _getMotivationalQuote() {
    final quotes = [
      'Every hour of study brings you closer.',
      'Focus is your superpower.',
      'Small steps lead to big achievements.',
      'Your future self will thank you.',
      'Learn something new today.',
    ];
    return quotes[_currentTime.minute % quotes.length];
  }

  Widget _buildRecentNoteCard(BuildContext context, dynamic note) {
    final noteColor = Color(note.color).withValues(alpha: 0.2);
    final borderColor = Color(note.color).withValues(alpha: 0.5);
    final preview = note.content.split('\n').first;
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(0),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailScreen(
                  existingTitle: preview.isEmpty ? 'Untitled' : preview,
                  initialContent: note.content,
                  existingNote: note,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: borderColor, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: noteColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('MMM d').format(note.timestamp),
                    style: TextStyle(
                      color: Color(note.color),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  preview.isEmpty ? 'Untitled Note' : preview,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  note.content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildQuickActions(int notesCount, int seedsCount) {
    // Converted to full-width cards/list as requested
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), // Standard padding
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildPremiumActionButton(
                  'Schedule',
                  'Study Session',
                  Icons.calendar_today_rounded,
                  [AppTheme.neonCyan, const Color(0xFF00B4D8)],
                  _navigateToSchedule,
                  delay: 0,
                  width: double.infinity, // stretch
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  'Forest',
                  '$seedsCount Seeds', 
                  Icons.park_rounded,
                  [AppTheme.neonGreen, const Color(0xFF2DD4BF)],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Focus Forest'),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          body: const FocusForestTab(),
                        ),
                      ),
                    );
                  },
                  delay: 100,
                  width: double.infinity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPremiumActionButton(
                  'Notes',
                  '$notesCount Saved',
                  Icons.auto_stories_rounded,
                  [AppTheme.neonPurple, const Color(0xFF9D4EDD)],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NotesSummaryScreen()),
                    );
                  },
                  delay: 200,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  'Analytics',
                  'Your Progress',
                  Icons.insights_rounded,
                  [const Color(0xFFFF9F1C), const Color(0xFFFFBF69)],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                    );
                  },
                  delay: 300,
                  width: double.infinity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPremiumActionButton(
                  'Calendar',
                  'View Sessions',
                  Icons.calendar_month_rounded,
                  [AppTheme.neonCyan, AppTheme.neonBlue],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarScreen()),
                    );
                  },
                  delay: 400,
                  width: double.infinity,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPremiumActionButton(
                  'Join Session',
                  'Enter Meeting ID',
                  Icons.video_call_rounded,
                  [AppTheme.neonGreen, const Color(0xFF2DD4BF)],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinSessionScreen()),
                    );
                  },
                  delay: 500,
                  width: double.infinity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumActionButton(
    String title,
    String subtitle,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onTap, {
    required int delay,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
          width: width ?? 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                gradientColors[0].withValues(alpha: 0.2),
                gradientColors[1].withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: gradientColors[0].withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 400 + delay)).scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.neonCyan),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading sessions...',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonCyan.withValues(alpha: 0.1),
                    AppTheme.neonPurple.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonCyan.withValues(alpha: 0.2),
                ),
              ),
              child: SizedBox(height: 64, width: 64),
            ).animate().scale().then().shimmer(duration: 2000.ms),

            const SizedBox(height: 24),

            const Text(
              'No Sessions Yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 12),

            Text(
              'Schedule your first study session\nand start your learning journey!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 32),

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _navigateToSchedule,
                child: const Text('Schedule Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 500.ms).scale(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSessionCard(ScheduledSession session, int index) {
    final isUpcoming = session.isUpcoming;
    final isActive = session.isActive;
    final hasEnded = session.hasEnded;

    Color statusColor = AppTheme.neonCyan;
    String statusText = 'Upcoming';
    IconData statusIcon = Icons.schedule_rounded;

    if (isActive) {
      statusColor = AppTheme.neonGreen;
      statusText = 'Live Now';
      statusIcon = Icons.play_circle_rounded;
    } else if (hasEnded) {
      statusColor = Colors.grey;
      statusText = 'Ended';
      statusIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.sessionName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.aiMode.toUpperCase()} • ${session.durationMinutes} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Time info
            Row(
              children: [
                Text(
                  DateFormat('MMM dd').format(session.startTime),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat('hh:mm a').format(session.startTime),
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),

            if (isActive || isUpcoming) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [AppTheme.neonGreen, AppTheme.neonGreen.withValues(alpha: 0.8)]
                              : [AppTheme.neonCyan, AppTheme.neonPurple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          final meetingSession = ScheduledMeeting(
                            id: session.id,
                            title: session.sessionName,
                            hostName: 'You',
                            meetingId: 'SESSION-${session.id.substring(0, 4)}',
                            startTime: session.startTime,
                            endTime: session.endTime,
                            participants: ['You', 'AI ${session.aiMode}'],
                            aiRole: session.aiMode,
                            durationMinutes: session.durationMinutes,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GoogleMeetStyleMeetingScreen(session: meetingSession),
                            ),
                          );
                        },
                        child: Text(isActive ? 'Join Now' : 'Start'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                      onPressed: () {
                        Share.share('Join my YallaStudy session: ${session.sessionName}\nLink: ${session.shareableLink}');
                      },
                      child: const Text('Share', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 500 + index * 80)).slideX(begin: 0.05);
  }

  Widget _buildAiCoachWidget() {
    final tips = [
      'Try the "Focus Fade" mode during deep work to minimize distractions.',
      'Take a 5-minute break every 25 minutes to stay fresh.',
      'Review your notes before sleeping to improve retention.',
      'Teaching what you learned is the best way to master it.',
      'Drink water! Hydration improves cognitive function.',
      'Set specific goals for each study session.',
    ];
    final tip = tips[_currentTime.day % tips.length];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('AI Coach: "How can I help you study better today?"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'AI Study Coach',
                          style: TextStyle(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tip: $tip',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1);
  }
}

// Custom painter for time card background pattern
class _TimeCardPatternPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  _TimeCardPatternPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw flowing curves
    for (int i = 0; i < 3; i++) {
      paint.color = i % 2 == 0 ? primaryColor : secondaryColor;
      final path = Path();
      final yOffset = size.height * (0.3 + i * 0.2);
      
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        final y = yOffset + math.sin((x / 50) + progress * math.pi * 2 + i) * 20;
        path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TimeCardPatternPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
