import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';

class MeetingControls extends StatefulWidget {
  final VoidCallback? onToggleChat;
  final VoidCallback? onToggleParticipants;
  final VoidCallback? onToggleShare;
  final VoidCallback? onToggleNotes;
  final VoidCallback? onToggleVoice;
  final VoidCallback? onToggleRaiseHand;
  final VoidCallback? onStartQuiz;

  const MeetingControls({
    super.key,
    this.onToggleChat,
    this.onToggleParticipants,
    this.onToggleShare,
    this.onToggleNotes,
    this.onToggleVoice,
    this.onToggleRaiseHand,
    this.onStartQuiz,
  });

  @override
  State<MeetingControls> createState() => _MeetingControlsState();
}

class _MeetingControlsState extends State<MeetingControls> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Container(
          color: Colors.transparent, 
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // LEFT GROUP: Audio & Video
                Row(
                  children: [
                    _ZoomButton(
                      icon: _isMuted ? Icons.mic_off_outlined : Icons.mic_none_outlined,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      isActive: !_isMuted,
                      activeColor: Colors.white,
                      inactiveColor: Colors.red, // Zoom style red slash usually
                      onPressed: () => setState(() => _isMuted = !_isMuted),
                    ),
                    const SizedBox(width: 24),
                    _ZoomButton(
                      icon: _isVideoOff ? Icons.videocam_off_outlined : Icons.videocam_outlined,
                      label: _isVideoOff ? 'Start Video' : 'Stop Video',
                      isActive: !_isVideoOff,
                      activeColor: Colors.white,
                      inactiveColor: Colors.red,
                      onPressed: () => setState(() => _isVideoOff = !_isVideoOff),
                    ),
                  ],
                ),

                // CENTER GROUP: Meeting Actions
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.onStartQuiz != null) ...[
                          _ZoomButton(
                            icon: Icons.quiz_outlined,
                            label: 'Quiz',
                            iconColor: AppTheme.neonPurple,
                            activeColor: AppTheme.neonPurple,
                            onPressed: widget.onStartQuiz!,
                          ),
                          const SizedBox(width: 20),
                        ],
                        _ZoomButton(
                          icon: Icons.security_outlined,
                          label: 'Security',
                          onPressed: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Security Settings - Coming Soon')),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _ZoomButton(
                          icon: Icons.people_outline,
                          label: 'Participants',
                          badgeCount: 2, // Mock count
                          onPressed: widget.onToggleParticipants ?? () {}, 
                        ),
                        const SizedBox(width: 20),
                        _ZoomButton(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onPressed: widget.onToggleChat ?? () {}, 
                        ),
                        const SizedBox(width: 20),
                        _ZoomButton(
                          icon: Icons.ios_share_outlined,
                          label: 'Share Screen',
                          iconColor: AppTheme.neonGreen, // Zoom green share
                          onPressed: widget.onToggleShare ?? () {},
                        ),
                        const SizedBox(width: 20),
                        // Removed Duplicate Raise Hand button
                        _ZoomButton(
                          icon: appState.isListening ? Icons.mic : Icons.mic_none,
                          label: appState.isListening ? 'Listening...' : 'Speak to AI',
                          isActive: true,
                          activeColor: appState.isListening ? AppTheme.neonCyan : Colors.white,
                          iconColor: appState.isListening ? AppTheme.neonCyan : null,
                          onPressed: widget.onToggleVoice ?? () {},
                        ),
                        const SizedBox(width: 20),
                        Consumer<AppState>(
                          builder: (context, appState, _) => _ZoomButton(
                            icon: appState.isHandRaised ? Icons.back_hand : Icons.pan_tool_outlined,
                            label: appState.isHandRaised ? 'Lower Hand' : 'Raise Hand',
                            isActive: appState.isHandRaised,
                            activeColor: Colors.orange,
                            iconColor: appState.isHandRaised ? Colors.orange : null,
                            onPressed: () {
                              appState.toggleHandRaised();
                              if (appState.isHandRaised) {
                                // AI stops speaking when hand is raised
                                appState.pauseAiSpeaking();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Removed Reactions placeholder
                        _ZoomButton(
                          icon: Icons.edit_note,
                          label: 'Notes',
                          onPressed: widget.onToggleNotes ?? () {},
                        ),
                         const SizedBox(width: 20),
                        Consumer<AppState>(
                          builder: (context, appState, _) {
                            // This will be passed from parent
                            final isRecording = false; // TODO: Get from parent state
                            return _ZoomButton(
                              icon: isRecording ? Icons.fiber_smart_record : Icons.fiber_manual_record,
                              label: isRecording ? 'Stop Record' : 'Record',
                              isActive: isRecording,
                              activeColor: Colors.red,
                              iconColor: isRecording ? Colors.red : null,
                              onPressed: () {
                                // TODO: Toggle recording via callback
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isRecording ? 'Recording stopped' : 'Recording started'),
                                    backgroundColor: isRecording ? Colors.grey : Colors.red,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _ZoomButton(
                          icon: Icons.apps,
                          label: 'Apps',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Apps Marketplace - Coming Soon')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT GROUP: End
                MaterialButton(
                  onPressed: () => _showEndDialog(context),
                  color: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Text('End', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEndDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: const Text('End Meeting for All?', style: TextStyle(color: Colors.white)),
        content: const Text('You are the host.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
               context.read<AppState>().endSession();
               Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('End Meeting'),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final Color? iconColor;
  final int badgeCount;

  const _ZoomButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = true,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white, // In Zoom, text stays white usually, icon might change
    this.iconColor,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: !isActive ? inactiveColor : (iconColor ?? activeColor),
                size: 26,
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -5,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFFB0B0B0),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
