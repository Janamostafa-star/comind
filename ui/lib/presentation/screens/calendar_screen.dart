import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../widgets/animated_background.dart';
import '../../core/theme.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../domain/models/scheduled_session_model.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/extended_models.dart';
import 'schedule_session_screen.dart';
import 'google_meet_style_meeting.dart';
import '../widgets/share_session_sheet.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../providers/app_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().refreshData();
    });
  }

  List<ScheduledMeeting> _getSessionsForDay(DateTime day, List<ScheduledMeeting> allSessions) {
    return allSessions.where((session) {
      return isSameDay(session.startTime, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allSessions = appState.meetings ?? [];
    final selectedSessions = _getSessionsForDay(_selectedDay, allSessions);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              context.read<AppState>().refreshData();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Theme Background
          const AnimatedBackground(
            primaryColor: Color(0xFF0D1B2A),
            secondaryColor: Color(0xFF1B263B),
            particleCount: 15,
          ),
          
          SafeArea(
            child: Column(
            children: [
              GlassmorphismCard(
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (!isSameDay(_selectedDay, selectedDay)) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    }
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) {
                    return _getSessionsForDay(day, allSessions);
                  },
                  calendarStyle: CalendarStyle(
                    defaultTextStyle: const TextStyle(color: Colors.white),
                    weekendTextStyle: const TextStyle(color: Colors.white70),
                    selectedDecoration: BoxDecoration(
                      color: AppTheme.neonCyan,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.neonCyan.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
                      color: AppTheme.neonPurple,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 18),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: selectedSessions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No sessions for this day',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedSessions.length,
                        itemBuilder: (context, index) {
                          final session = selectedSessions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassmorphismCard(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                                  child: Icon(Icons.video_call, color: AppTheme.neonCyan),
                                ),
                                title: Text(
                                  session.title,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${DateFormat('h:mm a').format(session.startTime)} - ${session.durationMinutes} min',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GoogleMeetStyleMeetingScreen(
                                          session: session,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX(begin: 0.1);
                        },
                      ),
              ),
            ],
          ),
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleSessionScreen(initialDate: _selectedDay),
            ),
          );
        },
        backgroundColor: AppTheme.neonCyan,
        child: const Icon(Icons.add),
      ),
    );
  }
}
