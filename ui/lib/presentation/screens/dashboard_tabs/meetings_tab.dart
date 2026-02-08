import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../domain/models/extended_models.dart';
import '../../../widgets/glassmorphism_card.dart';
import '../google_meet_style_meeting.dart';

class MeetingsTab extends StatefulWidget {
  const MeetingsTab({super.key});

  @override
  State<MeetingsTab> createState() => _MeetingsTabState();
}

class _MeetingsTabState extends State<MeetingsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.meetings == null) {
        appState.refreshData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Meetings'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.neonCyan),
            onPressed: () => _showAddMeetingDialog(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          return RefreshIndicator(
            onRefresh: appState.refreshData,
             color: AppTheme.neonCyan,
             backgroundColor: AppTheme.darkCard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Meeting ID
                  GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Personal Meeting ID (PMI)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('123 456 7890', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        ElevatedButton(
                           onPressed: () {
                             Navigator.of(context).push(
                               MaterialPageRoute(
                                 builder: (_) => const GoogleMeetStyleMeetingScreen(
                                   channelId: 'personal_meeting',
                                   meetingTitle: 'Personal Meeting',
                                 ),
                               ),
                             );
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppTheme.neonBlue,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                           ),
                           child: const Text('Start'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 24),
                  
                  if (appState.meetings == null)
                     const Center(child: Padding(
                       padding: EdgeInsets.all(20.0),
                       child: CircularProgressIndicator(),
                     ))
                  else if (appState.meetings!.isEmpty)
                     const Center(child: Text('No upcoming meetings', style: TextStyle(color: Colors.white54)))
                  else ...[
                    Text('Upcoming', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary)),
                    const SizedBox(height: 12),
                    ...appState.meetings!.asMap().entries.map((entry) {
                      return _MeetingCard(meeting: entry.value, index: entry.key);
                    }),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddMeetingDialog(BuildContext context) {
    final titleController = TextEditingController();
    final hostController = TextEditingController(text: 'Me');
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(minutes: 30)));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Schedule Meeting', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Meeting Title',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: hostController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Host Name',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
              ),
            ),
            const SizedBox(height: 16),
            // Date Picker Trigger
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date & Time', style: TextStyle(color: AppTheme.textSecondary)),
              subtitle: Text(
                '${DateFormat('MMM d, y').format(selectedDate)} at ${selectedTime.format(context)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  // ignore: use_build_context_synchronously
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    selectedDate = date;
                    selectedTime = time;
                    (context as Element).markNeedsBuild(); // Force rebuild to update text
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                final startDateTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
                
                final newMeeting = ScheduledMeeting(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  startTime: startDateTime,
                  endTime: startDateTime.add(const Duration(hours: 1)), // Default 1 hour
                  meetingId: '${DateTime.now().millisecondsSinceEpoch}'.substring(5), // Mock ID
                  hostName: hostController.text,
                  participants: ['You', hostController.text],
                  aiRole: 'tutor',
                  durationMinutes: 60,
                );
                
                context.read<AppState>().addMeeting(newMeeting);
                Navigator.pop(context);
              }
            },
            child: const Text('Schedule', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final ScheduledMeeting meeting;
  final int index;

  const _MeetingCard({required this.meeting, required this.index});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');
    final timeString = '${dateFormat.format(meeting.startTime)} - ${DateFormat('h:mm a').format(meeting.endTime)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  meeting.title, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GoogleMeetStyleMeetingScreen(session: meeting)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 30),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(timeString, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Meeting ID: ${meeting.meetingId}', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  // Copy link logic
                  final link = 'https://yallastudy.app/join/${meeting.meetingId.replaceAll(' ', '')}';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Copied: $link')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                       Icon(Icons.link, size: 12, color: AppTheme.neonCyan),
                       SizedBox(width: 4),
                       Text('Copy Link', style: TextStyle(color: AppTheme.neonCyan, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  context.read<AppState>().deleteMeeting(meeting.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Meeting deleted')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1, end: 0);
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  const _ActionButton(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}
