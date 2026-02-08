import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../domain/models/extended_models.dart';
import '../../widgets/ai_avatar_widget.dart';
import '../../widgets/slide_viewer.dart';
import '../../widgets/meeting_controls.dart';
import 'dashboard_screen.dart';

class LiveMeetingScreen extends StatefulWidget {
  final ScheduledMeeting? session;
  final String? channelId;
  final String? meetingTitle;

  const LiveMeetingScreen({
    super.key, 
    this.session,
    this.channelId,
    this.meetingTitle,
  });

  @override
  State<LiveMeetingScreen> createState() => _LiveMeetingScreenState();
}

class _LiveMeetingScreenState extends State<LiveMeetingScreen> with TickerProviderStateMixin {
  late ScheduledMeeting _session;
  bool _isMicOn = true;
  bool _isCamOn = true;
  bool _isScreenSharing = false;
  bool _showNotes = true; // Open by default as per request to replace chat
  bool _isRecording = false;
  bool _showCaptions = false;
  String _captionText = '';
  
  // Notes Logic
  final TextEditingController _notesController = TextEditingController();
  final List<String> _bulletPoints = [];
  bool _isAiGeneratingSummary = false;
  
  // Note Styles
  int _selectedNoteColor = 0xFFFFFFFF; // White
  final List<int> _noteColors = [
    0xFFFFFFFF, // White
    0xFFFFEB3B, // Yellow
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFF2196F3, // Blue
  ];

  late Timer _meetingTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Use passed session or generate one from passed ID/Title, or fallback to test
    _session = widget.session ?? ScheduledMeeting(
      id: widget.channelId ?? 'test',
      title: widget.meetingTitle ?? 'Live Session',
      hostName: 'User',
      meetingId: '123 456 7890',
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(minutes: 60)),
      participants: ['You', 'AI Tutor'],
      aiRole: 'tutor',
      durationMinutes: 60,
    );
    
    _meetingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  @override
  void dispose() {
    _meetingTimer.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _endSession() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('End Session?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will save your notes and study hours to the Forest.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('End & Save', style: TextStyle(color: AppTheme.neonRed)),
            onPressed: () {
              // Save to Forest
              // Save to Forest & Notes
              final appState = context.read<AppState>();
              appState.recordSession(_elapsed.inMinutes);
              appState.saveSessionNotes();
              
              Navigator.pop(ctx); // Close dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isGridView = false; // Grid View Toggle

  String get _remainingTime {
    final remaining = _session.endTime.difference(DateTime.now());
    if (remaining.isNegative) return '00:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(remaining.inMinutes)}:${twoDigits(remaining.inSeconds.remainder(60))}';
  }

  void _uploadFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening File Picker... (Simulation)'), backgroundColor: AppTheme.neonCyan),
    );
    // Logic to pick file and add to _session resources
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true, // Allow resize for keyboard
      body: Stack(
        children: [
          // 1. Center Stage (Slides / Video / Grid)
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Main Content Area
                      Expanded(
                        flex: _showNotes ? 3 : 1, // Dynamic sizing
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 60, 16, 16), // Adjusted margins
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: _isGridView 
                              ? _buildParticipantGrid() 
                              : _buildFocusView(),
                        ),
                      ),
                      
                      // Side Panel (Notes/Chat)
                      if (_showNotes)
                      Expanded(
                        flex: 1,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(0, 60, 16, 16), // Reduced bottom margin to prevent overflow
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              // Toggle Header
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () {}, // Already in notes
                                        icon: const Icon(Icons.edit_note, size: 18, color: AppTheme.neonCyan),
                                        label: const Text('Notes', style: TextStyle(color: Colors.white)),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextButton.icon(
                                        onPressed: () => setState(() => _showNotes = false),
                                        icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                                        label: const Text('Close', style: TextStyle(color: Colors.white54)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(child: _buildNotesPanel()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Top Info Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // View Toggle
                    IconButton(
                      icon: Icon(_isGridView ? Icons.grid_view : Icons.crop_square, color: Colors.white),
                      tooltip: 'Toggle View',
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),

                     // Time Remaining (Requested)
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getTimerColor(_session.endTime.difference(DateTime.now()))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.hourglass_empty, size: 14, color: Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            '$_remainingTime remaining', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Row(
                      children: [
                        _buildHeaderAction(Icons.upload_file, 'Upload', _uploadFile),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(_showCaptions ? Icons.closed_caption : Icons.closed_caption_off, color: _showCaptions ? AppTheme.neonCyan : Colors.white54),
                          onPressed: () => setState(() => _showCaptions = !_showCaptions),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 3. Bottom Controls
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: MeetingControls(
                onToggleVoice: () => setState(() => _isMicOn = !_isMicOn),
                onToggleChat: () => setState(() => _showNotes = !_showNotes), // Toggle Sidebar
                onToggleNotes: () => setState(() => _showNotes = !_showNotes),
                onToggleShare: () => setState(() => _isScreenSharing = !_isScreenSharing), // Logic handled in FocusView
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Content (Slides/Screen Share)
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _isScreenSharing 
              ? Container(color: Colors.black, child: const Center(child: Text('You are sharing your screen', style: TextStyle(color: Colors.white))))
              : SlideViewer(),
        ),
        
        // Host/AI Avatar Picture-in-Picture
        Positioned(
          right: 16,
          top: 16,
          child: SizedBox(
            width: 120,
            height: 160,
            child: AiAvatarWidget(aiRole: _session.aiRole),
          ),
        ),
        
        // Captions
        if (_showCaptions)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _captionText.isEmpty ? 'Captions...' : _captionText,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildParticipantGrid() {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 0.8, // Taller tiles to fill space as requested
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      padding: const EdgeInsets.all(16),
      children: [
        _buildGridTile('You', _isMicOn, true), // Me
        _buildGridTile('AI Tutor', true, false, isAi: true), // AI
      ],
    );
  }

  Widget _buildGridTile(String name, bool micOn, bool isMe, {bool isAi = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: micOn ? AppTheme.neonGreen : Colors.transparent, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isAi)
             Center(child: AiAvatarWidget(aiRole: _session.aiRole))
          else if (isMe && !_isCamOn)
              Center(
                child: SizedBox(
                   width: 60,
                   height: 60,
                   child: context.watch<AuthProvider>().user?.avatarUrl != null
                       ? ClipOval(
                           child: context.watch<AuthProvider>().user!.avatarUrl!.startsWith('data:')
                               ? Image.memory(
                                   base64Decode(context.watch<AuthProvider>().user!.avatarUrl!.split(',').last),
                                   fit: BoxFit.cover,
                                   errorBuilder: (_, __, ___) => Text(name[0], style: const TextStyle(fontSize: 24, color: Colors.white)),
                                 )
                               : Image.network(
                                   context.watch<AuthProvider>().user!.avatarUrl!,
                                   fit: BoxFit.cover,
                                   errorBuilder: (_, __, ___) => Text(name[0], style: const TextStyle(fontSize: 24, color: Colors.white)),
                                 ),
                         )
                       : CircleAvatar(
                           radius: 30, 
                           backgroundColor: AppTheme.neonPurple, 
                           child: Text(name[0], style: const TextStyle(fontSize: 24, color: Colors.white)),
                         ),
                ),
              )
          else
             const Center(child: Icon(Icons.person, size: 64, color: Colors.white24)),
             
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
              child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // Refactored Notes Panel
  Widget _buildNotesPanel() {
    final appState = context.watch<AppState>();
    return Column(
      children: [
        Expanded(
          child: appState.notes.isEmpty
              ? const Center(child: Text('No notes yet', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appState.notes.length,
                  itemBuilder: (context, index) {
                    final note = appState.notes[index];
                    final isDarkBg = note.color != 0xFFFFFFFF;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(note.color).withValues(alpha: isDarkBg ? 0.3 : 1.0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.content,
                        style: TextStyle(color: isDarkBg ? Colors.white : Colors.black),
                      ),
                    );
                  },
                ),
        ),
        // Input Area
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _notesController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: 'Type a note...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: AppTheme.neonCyan),
                onPressed: () {
                  if (_notesController.text.isNotEmpty) {
                    appState.addNote(_notesController.text, color: _selectedNoteColor);
                    _notesController.clear();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _participantTile(String name, bool isMuted, {bool isAi = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isAi ? AppTheme.primaryGradient : null,
              color: isAi ? null : AppTheme.neonPurple,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isAi 
                ? const Icon(Icons.smart_toy, color: Colors.white, size: 20)
                : Text(name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)), // Initials
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: Theme.of(context).textTheme.titleSmall),
          ),
          Icon(isMuted ? Icons.mic_off : Icons.mic, size: 18, color: isMuted ? Colors.red : AppTheme.neonGreen),
        ],
      ),
    );
  }

  Color _getTimerColor(Duration remaining) {
    if (remaining.inMinutes < 5) return Colors.red;
    if (remaining.inMinutes < 10) return Colors.orange;
    return AppTheme.neonCyan;
  }

  String _formatDuration(Duration duration) {
    // Deprecated for display in favor of _remainingTime but kept for utilities
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

