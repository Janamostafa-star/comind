import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../domain/models/extended_models.dart';
import '../../widgets/ai_avatar_widget.dart';
import '../../widgets/meeting_controls.dart';
import '../../widgets/glassmorphism_card.dart';
import 'advanced_notes_panel.dart';
import '../../widgets/quiz_competition_overlay.dart';
import 'dashboard_screen.dart';

class GoogleMeetStyleMeetingScreen extends StatefulWidget {
  final ScheduledMeeting? session;
  final String? channelId;
  final String? meetingTitle;

  const GoogleMeetStyleMeetingScreen({
    super.key,
    this.session,
    this.channelId,
    this.meetingTitle,
  });

  @override
  State<GoogleMeetStyleMeetingScreen> createState() => _GoogleMeetStyleMeetingScreenState();
}

class _GoogleMeetStyleMeetingScreenState extends State<GoogleMeetStyleMeetingScreen>
    with TickerProviderStateMixin {
  late ScheduledMeeting _session;
  
  // Local state for the user
  bool _isMicOn = true;
  bool _isCamOn = true;
  bool _isScreenSharing = false;
  bool _isRecording = false;
  bool _isHandRaised = false;
  
  // UI toggles
  bool _showCaptions = false;
  bool _showNotes = false;
  bool _showParticipants = false;
  bool _showChat = false;
  
  String _captionText = '';
  int _gridColumns = 2;
  int _gridRows = 2;
  
  late Timer _meetingTimer;
  Duration _elapsed = Duration.zero;
  
  Timer? _captionTimer;
  
  // Participants list (Mutable)
  late List<Map<String, dynamic>> _participants;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];

  // AI Interaction State
  bool _isAiAnswering = false;
  bool _showQuiz = false;

  void _startQuiz() {
    setState(() => _showQuiz = true);
  }

  @override
  void initState() {
    super.initState();
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
    
    // Initialize participants
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    
    _participants = [
      {
        'name': user?.name ?? 'You', 
        'isMuted': !_isMicOn, 
        'isVideoOff': !_isCamOn, 
        'isHost': true, 
        'isAI': false, 
        'isHandRaised': false,
        'avatarUrl': user?.avatarUrl,
      },
      {'name': 'AI Tutor', 'isMuted': false, 'isVideoOff': false, 'isHost': false, 'isAI': true, 'isHandRaised': false},
    ];

    _meetingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
    
    // Simulate captions
    _startCaptionSimulation();
  }

  void _startCaptionSimulation() {
    _captionTimer?.cancel();
    _captionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _showCaptions && !_isHandRaised && !_isAiAnswering) {
        setState(() {
          _captionText = 'AI Tutor: ${_getRandomCaption()}';
        });
      }
    });
  }
  
  void _stopCaptionSimulation() {
    _captionTimer?.cancel();
  }

  String _getRandomCaption() {
    final captions = [
      'Let\'s start with the basics of quantum mechanics.',
      'The wave function describes the probability amplitude.',
      'Does anyone have questions about superposition?',
      'Remember, observation collapses the wave function.',
    ];
    return captions[DateTime.now().millisecond % captions.length];
  }

  @override
  void dispose() {
    _meetingTimer.cancel();
    _captionTimer?.cancel();
    _chatController.dispose();
    super.dispose();
  }

  void _calculateGrid() {
    // If screen sharing, grid changes significantly
    if (_isScreenSharing) {
      _gridColumns = 1;
      _gridRows = 1; // Participants become a side strip
      return;
    }

    final count = _participants.length;
    if (count <= 1) {
      _gridColumns = 1;
      _gridRows = 1;
    } else if (count <= 2) {
      _gridColumns = 2;
      _gridRows = 1; // Side by side
    } else if (count <= 4) {
      _gridColumns = 2;
      _gridRows = 2;
    } else if (count <= 6) {
      _gridColumns = 3;
      _gridRows = 2;
    } else if (count <= 9) {
      _gridColumns = 3;
      _gridRows = 3;
    } else {
      _gridColumns = 4;
      _gridRows = 3;
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicOn = !_isMicOn;
      _participants[0]['isMuted'] = !_isMicOn;
    });
  }

  void _toggleCam() {
    setState(() {
      _isCamOn = !_isCamOn;
      _participants[0]['isVideoOff'] = !_isCamOn;
    });
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRecording ? 'Recording started' : 'Recording stopped'),
        backgroundColor: _isRecording ? Colors.redAccent : Colors.grey,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _toggleRaiseHand() {
    setState(() {
      _isHandRaised = !_isHandRaised;
      _participants[0]['isHandRaised'] = _isHandRaised;
    });

    if (_isHandRaised) {
      // 1. User raises hand -> AI stops and listens
      _stopCaptionSimulation();
      setState(() {
        _captionText = ''; 
        _isAiAnswering = false;
      });
      
      // Trigger listening mode
      context.read<AppState>().startListening();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.back_hand, color: Colors.white),
              SizedBox(width: 12),
              Text('Hand raised! AI is listening to your question...'),
            ],
          ),
          backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'DONE',
            textColor: Colors.black,
            onPressed: _finishQuestion,
          ),
        ),
      );
    } else {
      // User cancelled hand raise or finished speaking manually
      _finishQuestion();
    }
  }

  void _finishQuestion() {
    if (!_isHandRaised && !_participants[0]['isHandRaised']) return; // Already finished

    context.read<AppState>().stopListening();
    setState(() {
      _isHandRaised = false;
      _participants[0]['isHandRaised'] = false;
      _isAiAnswering = true; // AI starts answering
    });

    // 2. Simulate AI Thinking
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            ),
            SizedBox(width: 12),
            Text('AI Tutor is thinking...'),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 1),
      ),
    );

    // 3. AI Answers and Resumes
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      // Get response from AppState if available, otherwise use fallback
      final appState = context.read<AppState>();
      final aiResponse = appState.aiResponseText ?? "That's a great point! Let's explore that concept further to ensure we fully understand the underlying principles.";
      
      setState(() {
        _captionText = "AI Tutor: $aiResponse";
      });

      // 4. Resume normal session after answer
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        setState(() {
          _isAiAnswering = false;
        });
        _startCaptionSimulation();
      });
    });
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    setState(() {
      _chatMessages.add({
        'sender': 'You',
        'message': _chatController.text,
        'time': DateTime.now(),
        'isMe': true,
      });
      _chatController.clear();
      
      // Mock AI response
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _chatMessages.add({
              'sender': 'AI Tutor',
              'message': 'That is a great question! Let me explain...',
              'time': DateTime.now(),
              'isMe': false,
            });
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _calculateGrid();
    
    return Scaffold(
      backgroundColor: const Color(0xFF202124), // Google Meet Dark Grey
      body: Stack(
        children: [
          Row(
            children: [
              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Top Bar
                    _buildTopBar(),
                    
                    // Main Video Area
                    Expanded(
                      child: Stack(
                        children: [
                          _isScreenSharing ? _buildScreenShareView() : _buildVideoGrid(),
                          
                          // Captions Overlay
                          if (_showCaptions && _captionText.isNotEmpty)
                             Positioned(
                                bottom: 20,
                                left: 0,
                                right: 0,
                                child: Center(child: _buildCaptionsOverlay()),
                             ),

                          // AI Listening Overlay
                          if (_isHandRaised)
                             Positioned.fill(
                               child: Container(
                                 color: Colors.black.withValues(alpha: 0.6),
                                 child: Center(
                                   child: Column(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Container(
                                         padding: const EdgeInsets.all(20),
                                         decoration: BoxDecoration(
                                           color: Colors.black.withValues(alpha: 0.8),
                                           shape: BoxShape.circle,
                                           border: Border.all(color: AppTheme.neonCyan, width: 2),
                                           boxShadow: [
                                             BoxShadow(
                                               color: AppTheme.neonCyan.withValues(alpha: 0.5),
                                               blurRadius: 20,
                                               spreadRadius: 5,
                                             )
                                           ],
                                         ),
                                         child: const Icon(Icons.graphic_eq, size: 60, color: AppTheme.neonCyan),
                                       ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                                       const SizedBox(height: 30),
                                       Text(
                                         'Listening to you...',
                                         style: TextStyle(
                                           color: AppTheme.neonCyan,
                                           fontSize: 24,
                                           fontWeight: FontWeight.bold,
                                           letterSpacing: 1.2,
                                         ),
                                       ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white),
                                       const SizedBox(height: 10),
                                       const Text(
                                         'Go ahead, ask your question. AI is listening.',
                                         style: TextStyle(color: Colors.white70, fontSize: 16),
                                       ),
                                       const SizedBox(height: 40),
                                       ElevatedButton.icon(
                                          onPressed: _finishQuestion,
                                          icon: const Icon(Icons.check),
                                          label: const Text('I\'m Done Speaking'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.neonCyan,
                                            foregroundColor: Colors.black,
                                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                       ),
                                     ],
                                   ),
                                 ),
                               ).animate().fadeIn(),
                             ),
                        ],
                      ),
                    ),
                    
                    // Bottom Controls
                    MeetingControls(
                      onToggleChat: () => setState(() {
                        _showChat = !_showChat;
                        _showNotes = false;
                        _showParticipants = false;
                      }),
                      onToggleParticipants: () => setState(() {
                        _showParticipants = !_showParticipants;
                        _showChat = false;
                        _showNotes = false;
                      }),
                      onToggleNotes: () => setState(() {
                        _showNotes = !_showNotes;
                        _showChat = false;
                        _showParticipants = false;
                      }),
                      onToggleShare: _toggleScreenShare,
                      onToggleRaiseHand: _toggleRaiseHand,
                      onToggleVoice: () {
                         context.read<AppState>().toggleListening();
                      },
                      onStartQuiz: (_session.aiRole == 'classmate' || _session.aiRole == 'tutor') 
                          ? _startQuiz 
                          : null,
                    ),
                  ],
                ),
              ),

              // Side Panels
              if (_showNotes) 
                SizedBox(
                  width: 350,
                  child: AdvancedNotesPanel(
                    sessionId: _session.id,
                    onClose: () => setState(() => _showNotes = false),
                  ),
                ),
              if (_showChat)
                SizedBox(
                  width: 350,
                  child: _buildChatPanel(),
                ),
              if (_showParticipants)
                SizedBox(
                  width: 350,
                  child: _buildParticipantsPanel(),
                ),
            ],
          ),
          
          if (_showQuiz)
             Positioned.fill(
               child: QuizCompetitionOverlay(
                 onClose: () => setState(() => _showQuiz = false),
               ),
             ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (_isRecording) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .fade(duration: 1.seconds),
                    const SizedBox(width: 8),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
            ],
            Text(
              _session.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_elapsed.inMinutes.toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 16 / 9,
        ),
        itemCount: _participants.length,
        itemBuilder: (context, index) {
          final authProvider = context.watch<AuthProvider>();
          final user = authProvider.user;
          final participant = Map<String, dynamic>.from(_participants[index]);
          
          // Check local state for "You"
          if (index == 0) {
            participant['isVideoOff'] = !_isCamOn;
            participant['isMuted'] = !_isMicOn;
            participant['name'] = user?.name ?? 'You';
            participant['avatarUrl'] = user?.avatarUrl;
          }
          return _buildVideoTile(participant, index);
        },
      ),
    );
  }

  Widget _buildScreenShareView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF303134),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neonGreen, width: 2),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Mock Screen Content
          Column(
            children: [
              Container(
                height: 30,
                color: Colors.black45,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.red, size: 10),
                    const SizedBox(width: 6),
                    const Icon(Icons.circle, color: Colors.amber, size: 10),
                    const SizedBox(width: 6),
                    const Icon(Icons.circle, color: Colors.green, size: 10),
                    const SizedBox(width: 12),
                    Text('YallaStudy - Presentation.pdf', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.present_to_all, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 20),
                      Text(
                        'You are sharing your screen',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _toggleScreenShare,
                        icon: const Icon(Icons.stop_screen_share),
                        label: const Text('Stop Sharing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Floating overlay of participants
          Positioned(
            right: 16,
            top: 16,
            bottom: 16,
            width: 200,
            child: ListView.separated(
              itemCount: _participants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return const SizedBox.shrink(); // Don't show self in side strip usually
                return AspectRatio(
                  aspectRatio: 16/9,
                  child: _buildVideoTile(_participants[index], index, isSmall: true),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoTile(Map<String, dynamic> participant, int index, {bool isSmall = false}) {
    final isAI = participant['isAI'] as bool;
    final isVideoOff = participant['isVideoOff'] as bool;
    final isMuted = participant['isMuted'] as bool;
    final isHandRaised = participant['isHandRaised'] as bool? ?? false;
    final name = participant['name'] as String;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3C4043),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: participant['isHost'] as bool && !isSmall
              ? AppTheme.neonCyan.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Content
          if (isVideoOff)
            Center(
              child: CircleAvatar(
                radius: isSmall ? 20 : 40,
                backgroundColor: isAI ? AppTheme.neonCyan : Colors.orange,
                backgroundImage: (!isAI && participant['avatarUrl'] != null)
                    ? (participant['avatarUrl'].toString().startsWith('data:')
                        ? MemoryImage(base64Decode(participant['avatarUrl'].toString().split(',').last))
                        : NetworkImage(participant['avatarUrl'].toString())) as ImageProvider
                    : null,
                child: (!isAI && participant['avatarUrl'] != null)
                    ? null
                    : Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            )
          else if (isAI)
            Container(
              color: Colors.black,
              child: Center(child: AiAvatarWidget(aiRole: _session.aiRole)),
            )
          else
            // User video placeholder (animated)
            Stack(
              children: [
                Container(color: Colors.grey[800]),
                Center(
                  child: participant['avatarUrl'] != null
                      ? ClipOval(
                          child: participant['avatarUrl'].toString().startsWith('data:')
                              ? Image.memory(
                                  base64Decode(participant['avatarUrl'].toString().split(',').last),
                                  fit: BoxFit.cover,
                                  width: isSmall ? 80 : 160,
                                  height: isSmall ? 80 : 160,
                                  errorBuilder: (_, __, ___) => Icon(Icons.person, size: isSmall ? 40 : 100, color: Colors.white24),
                                )
                              : Image.network(
                                  participant['avatarUrl'].toString(),
                                  fit: BoxFit.cover,
                                  width: isSmall ? 80 : 160,
                                  height: isSmall ? 80 : 160,
                                  errorBuilder: (_, __, ___) => Icon(Icons.person, size: isSmall ? 40 : 100, color: Colors.white24),
                                ),
                        )
                      : Icon(Icons.person, size: isSmall ? 40 : 100, color: Colors.white24),
                ),
                // Camera active indicator
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),

          // Name Tag & Status
          Positioned(
            top: 12,
            left: 12,
            child: isHandRaised 
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.neonCyan,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.back_hand, color: Colors.black, size: 20),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
              : const SizedBox.shrink(),
          ),

          Positioned(
            bottom: 12,
            left: 12,
            right: 12, // Constrain width
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible( // usage of Flexible prevents overflow
                    child: Text(
                      name + (index == 0 ? ' (You)' : ''),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 10 : 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMuted) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.mic_off, color: Colors.red, size: isSmall ? 12 : 16),
                  ] else ...[
                     const SizedBox(width: 8),
                     SizedBox(
                       width: 12,
                       height: 12,
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                         children: List.generate(3, (i) => 
                           Container(
                             width: 2,
                             height: 8,
                             color: Colors.green,
                           ).animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleY(begin: 0.2, end: 1.0, duration: Duration(milliseconds: 200 + (i * 100)))
                         ),
                       ),
                     ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionsOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _captionText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildChatPanel() {
    return Container(
      color: const Color(0xFF202124),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('In-call messages', style: TextStyle(color: Colors.white, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showChat = false),
                ),
              ],
            ),
          ),
          
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final msg = _chatMessages[index];
                final isMe = msg['isMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? AppTheme.neonCyan.withValues(alpha: 0.2) : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                      border: isMe ? Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.5)) : null,
                    ),
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg['sender'] as String,
                          style: TextStyle(
                            color: isMe ? AppTheme.neonCyan : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['message'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Send a message...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.neonCyan),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParticipantsPanel() {
    return Container(
      color: const Color(0xFF202124),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Participants (${_participants.length})', style: const TextStyle(color: Colors.white, fontSize: 18)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showParticipants = false),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _participants.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                final p = _participants[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    child: Text((p['name'] as String)[0], style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(p['name'] as String, style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (p['isMuted'] as bool) ? Icons.mic_off : Icons.mic,
                        color: (p['isMuted'] as bool) ? Colors.red : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        (p['isVideoOff'] as bool) ? Icons.videocam_off : Icons.videocam,
                        color: (p['isVideoOff'] as bool) ? Colors.red : Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    // Legacy method, not used as we use MeetingControls widget now. 
    // Kept for structure if needed later.
    return const SizedBox.shrink();
  }
}
