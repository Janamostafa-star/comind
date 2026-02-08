import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../core/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import 'google_meet_style_meeting.dart';
import '../../widgets/animated_background.dart';
import '../../domain/models/extended_models.dart';

class JoinSessionScreen extends StatefulWidget {
  const JoinSessionScreen({super.key});

  @override
  State<JoinSessionScreen> createState() => _JoinSessionScreenState();
}

class _JoinSessionScreenState extends State<JoinSessionScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleJoin() async {
    String code = _codeController.text.trim();
    
    // Extract ID if a URL is pasted (e.g., yallastudy.app/join/123456)
    final urlRegExp = RegExp(r'(?:join\/|\?id=)(\d+)');
    final match = urlRegExp.firstMatch(code);
    if (match != null) {
      code = match.group(1)!;
      _codeController.text = code; // Update UI to show extracted ID
    }
    
    code = code.replaceAll(' ', ''); // remove spaces
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Meeting ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simulate network lookup
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    // Validate using AppState (local verification)
    final appState = Provider.of<AppState>(context, listen: false);
    // Refresh to ensure we have latest list
    if (appState.meetings == null) await appState.refreshData();
    
    // Check if any meeting matches the ID (ignore spaces/formatting)
    try {
      final matchingMeeting = appState.meetings?.firstWhere(
        (m) => m.meetingId.replaceAll(' ', '') == code,
        orElse: () => ScheduledMeeting(
          id: 'personal_meeting',
          title: 'Personal Meeting',
          hostName: 'You',
          meetingId: '123 456 7890',
          startTime: DateTime.now(),
          endTime: DateTime.now().add(const Duration(hours: 1)),
          participants: ['You', 'AI Tutor'],
          aiRole: 'tutor',
          durationMinutes: 60,
        ),
      );
      
      // If found or defaulted (we check if code matches the default ID if not found in list)
      bool isValid = matchingMeeting?.id != 'personal_meeting' || code == '1234567890';
      
      if (!isValid) { 
         // Double check if code matches our hardcoded default ID to force success
         if (code == '1234567890') {
           isValid = true;
         } else {
           throw StateError('Not found');
         }
      }

      setState(() => _isLoading = false);

      if (matchingMeeting != null) {
        // Success! Navigate to live meeting with details
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GoogleMeetStyleMeetingScreen(
              channelId: matchingMeeting.id,
              meetingTitle: matchingMeeting.title,
            ),
          ),
        );
      } else {
        // ID valid format but verified as non-existent
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meeting not found. Check the ID and try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // firstWhere throws StateError if not found
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Meeting ID. Please check and try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Join Meeting'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Theme Background
          AnimatedBackground(
            primaryColor: AppTheme.neonCyan.withValues(alpha: 0.1),
            secondaryColor: AppTheme.neonPurple.withValues(alpha: 0.1),
            particleCount: 20,
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Enter Meeting ID',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the code provided by the meeting host.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _codeController,
                    label: 'Meeting ID',
                    prefixIcon: Icons.keyboard,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: _isLoading ? 'Joining...' : 'Join',
                    onPressed: _isLoading ? () {} : _handleJoin,
                    gradient: AppTheme.getPrimaryGradient(AppThemeType.deepFocus),
                  ).animate().scale(delay: 200.ms),
                  
                  const Spacer(),
                  
                  // Numeric Keypad hint
                  Text(
                    'If you received a link, tap on the link to join directly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
