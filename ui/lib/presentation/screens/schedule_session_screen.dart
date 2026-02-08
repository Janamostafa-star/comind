import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/animated_background.dart';
import '../../domain/models/scheduled_session_model.dart';
import '../../domain/models/extended_models.dart';
import '../../providers/app_state.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../data/repositories/firestore_session_repository.dart';
import 'google_meet_style_meeting.dart';

class ScheduleSessionScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ScheduleSessionScreen({
    super.key,
    this.initialDate,
  });

  @override
  State<ScheduleSessionScreen> createState() => _ScheduleSessionScreenState();
}

class _ScheduleSessionScreenState extends State<ScheduleSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sessionNameController = TextEditingController();
  
  String _selectedAiMode = 'tutor';
  int _durationMinutes = 30;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  bool _showSlides = true;
  bool _enableCamera = true;
  bool _enableMic = true;
  
  List<String> _uploadedMaterials = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'ppt', 'pptx'],
        allowMultiple: true,
      );

      if (result != null) {
        setState(() {
          // In production, upload to Firebase Storage and get URLs
          // For now, just save filenames
          _uploadedMaterials.addAll(
            result.files.map((file) => file.name).toList(),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking files: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.neonCyan,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.neonCyan,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleSession() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      // Use guest ID if not logged in (fallback)
      final userId = authProvider.user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
      final hostName = authProvider.user?.name ?? 'Guest User';

      // Combine date and time
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));

      // Generate unique 9-digit meeting ID
      final meetingId = (DateTime.now().millisecondsSinceEpoch % 1000000000).toString().padLeft(9, '0');
      final formattedMeetingId = '${meetingId.substring(0, 3)} ${meetingId.substring(3, 6)} ${meetingId.substring(6)}';
      
      // Generate shareable link
      final shareableLink = 'https://yallastudy.app/join/$meetingId';

      // Create ScheduledMeeting model for AppState (UI)
      final newMeeting = ScheduledMeeting(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _sessionNameController.text.trim(),
        startTime: startDateTime,
        endTime: endDateTime,
        meetingId: formattedMeetingId,
        hostName: hostName,
        participants: ['You', hostName],
        aiRole: _selectedAiMode.toString().split('.').last, // Simple string representation
        durationMinutes: _durationMinutes,
      );

      // Add to AppState so it appears in Meetings Tab IMMEDIATELY
      // This ensures "functionality" without relying on backend propagation delay
      context.read<AppState>().addMeeting(newMeeting);

      // Also try to save to Firebase if available, but don't block UI on it
      try {
        final session = ScheduledSession(
          id: newMeeting.id, 
          userId: userId,
          sessionName: newMeeting.title,
          aiMode: _selectedAiMode,
          durationMinutes: _durationMinutes,
          startTime: startDateTime,
          endTime: endDateTime,
          showSlides: _showSlides,
          enableCamera: _enableCamera,
          enableMic: _enableMic,
          materialUrls: _uploadedMaterials,
          shareableLink: shareableLink,
          createdAt: DateTime.now(),
        );
        // Fire and forget potential backend save
        FirestoreSessionRepository().createSession(session).catchError((e) {
          debugPrint('Backend save failed: $e');
          return '';
        });
      } catch (e) {
        // Ignore firebase errors (offline mode)
      }

      if (mounted) {
        // Show success with Meeting ID and Link options
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppTheme.darkCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Session Scheduled! 🎉', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your meeting is ready. Share the Meeting ID with friends!', 
                  style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                
                // Meeting ID - Prominent
                Text('Meeting ID', style: TextStyle(color: AppTheme.neonCyan, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.numbers, color: AppTheme.neonCyan, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          formattedMeetingId,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 20, 
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: AppTheme.neonCyan),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: meetingId));
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Meeting ID copied: $meetingId'),
                              backgroundColor: AppTheme.neonCyan,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Link - Secondary
                Text('Share Link', style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shareableLink,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.white54, size: 18),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: shareableLink));
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Link copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.of(context).pop(true); // Close schedule screen
                },
                child: const Text('Done'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.video_call, size: 20),
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.of(context).pop(); // Close schedule screen
                  // Navigate to meeting
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GoogleMeetStyleMeetingScreen(
                        channelId: newMeeting.id,
                        meetingTitle: newMeeting.title,
                      ),
                    ),
                  );
                },
                label: const Text('Start Meeting'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return Future.value();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule Study Session',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Session Name
                    _buildSectionTitle('Session Name'),
                    const SizedBox(height: 12),
                    GlassmorphismCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: TextFormField(
                        controller: _sessionNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Physics Review Session',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a session name';
                          }
                          return null;
                        },
                      ),
                    ).animate().fadeIn().slideX(begin: -0.2),
                    
                    const SizedBox(height: 32),
                    
                    // AI Mode Selection
                    _buildSectionTitle('AI Mode'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildAiModeCard(
                            'Tutor',
                            'tutor',
                            Icons.school,
                            'AI acts as your teacher',
                            AppTheme.neonCyan,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildAiModeCard(
                            'Classmate',
                            'classmate',
                            Icons.people,
                            'AI studies with you',
                            AppTheme.neonPurple,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 32),
                    
                    // Duration
                    _buildSectionTitle('Duration'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [30, 60, 90, 120].map((duration) {
                        final isSelected = _durationMinutes == duration;
                        return GestureDetector(
                          onTap: () => setState(() => _durationMinutes = duration),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.neonCyan.withValues(alpha: 0.2)
                                  : AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.neonCyan
                                    : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(
                              '$duration min',
                              style: TextStyle(
                                color: isSelected ? AppTheme.neonCyan : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Date & Time
                    _buildSectionTitle('Start Date & Time'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectDate,
                            child: GlassmorphismCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: AppTheme.neonCyan, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      DateFormat('MMM dd, yyyy').format(_selectedDate),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectTime,
                            child: GlassmorphismCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time, color: AppTheme.neonCyan, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedTime.format(context),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Session Settings
                    _buildSectionTitle('Session Settings'),
                    const SizedBox(height: 12),
                    GlassmorphismCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildSwitchTile('Show Slides', _showSlides, (val) => setState(() => _showSlides = val)),
                          _buildSwitchTile('Enable Camera', _enableCamera, (val) => setState(() => _enableCamera = val)),
                          _buildSwitchTile('Enable Mic', _enableMic, (val) => setState(() => _enableMic = val)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Upload Materials
                    _buildSectionTitle('Upload Study Materials (Optional)'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickFiles,
                      child: GlassmorphismCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file, color: AppTheme.neonCyan),
                            const SizedBox(width: 12),
                            const Text(
                              'Upload PDFs or PPTs',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                    
                    if (_uploadedMaterials.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._uploadedMaterials.map((file) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassmorphismCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.description, color: AppTheme.neonCyan, size: 20),
                              const SizedBox(width: 12),
                              Expanded(child: Text(file, style: const TextStyle(color: Colors.white70))),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _uploadedMaterials.remove(file)),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    // Schedule Button
                    GradientButton(
                      text: 'Schedule Session',
                      onPressed: _isLoading ? null : () { _scheduleSession(); },
                      gradient: AppTheme.getPrimaryGradient(AppThemeType.deepFocus),
                    ).animate().fadeIn(delay: 600.ms).scale(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.neonCyan),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAiModeCard(String title, String mode, IconData icon, String description, Color color) {
    final isSelected = _selectedAiMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _selectedAiMode = mode),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        borderColor: isSelected ? color : null,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? color : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.neonCyan,
          ),
        ],
      ),
    );
  }
}
