import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import 'particle_orbit.dart';
import 'glassmorphism_card.dart';

class AiAvatarWidget extends StatelessWidget {
  final String? aiRole;
  
  const AiAvatarWidget({
    super.key,
    this.aiRole,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isSpeaking = appState.isAiSpeaking;
        final handRaised = appState.isHandRaised;
        final isThinking = !isSpeaking && !handRaised;
        
        final currentRole = aiRole ?? appState.currentSession?.aiRole ?? 'tutor';
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 180;
            
            return GlassmorphismCard(
              borderRadius: 20,
              borderColor: isSpeaking
                  ? AppTheme.neonCyan
                  : appState.isHandRaised
                      ? Colors.orange
                      : AppTheme.neonCyan.withValues(alpha: 0.3),
              padding: EdgeInsets.all(isSmall ? 8 : 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar with states
                  SizedBox(
                    width: isSmall ? 60 : 100,
                    height: isSmall ? 60 : 100,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!isSmall && isThinking && !appState.isHandRaised && !isSpeaking)
                          const ParticleOrbit(
                            size: 100,
                            particleColor: AppTheme.neonPurple,
                            particleCount: 6,
                          ),
                        
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isSmall ? 50 : 80,
                          height: isSmall ? 50 : 80,
                          decoration: BoxDecoration(
                            gradient: appState.isHandRaised
                                ? const LinearGradient(colors: [Colors.orange, Colors.deepOrange])
                                : isSpeaking
                                    ? const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF0057FF)])
                                    : AppTheme.getPrimaryGradient(AppThemeType.deepFocus),
                            shape: BoxShape.circle,
                            boxShadow: isSpeaking
                                ? [BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.6), blurRadius: 30)]
                                : handRaised
                                    ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.6), blurRadius: 25)]
                                    : [],
                          ),
                          child: Icon(
                            currentRole == 'tutor' ? Icons.school_rounded : Icons.people_rounded,
                            size: isSmall ? 24 : 40,
                            color: Colors.white,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          duration: isSpeaking ? 800.ms : 2000.ms,
                          begin: const Offset(1.0, 1.0),
                          end: isSpeaking ? const Offset(1.15, 1.15) : const Offset(1.05, 1.05),
                        ),
                      ],
                    ),
                  ),
                  
                  if (!isSmall) ...[
                    const SizedBox(width: 16),
                    // Status Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentRole == 'tutor' ? 'AI Tutor' : 'AI Classmate',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: handRaised ? Colors.orange : isSpeaking ? AppTheme.neonGreen : AppTheme.neonCyan,
                                  shape: BoxShape.circle,
                                ),
                              ).animate(onPlay: (c) => isSpeaking ? c.repeat(reverse: true) : null).scale(end: const Offset(1.3, 1.3)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  handRaised ? 'Paused' : isSpeaking ? 'Speaking...' : 'Ready',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAdvancedWaveform() {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: List.generate(
          25,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.neonCyan,
                    AppTheme.neonBlue,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scaleY(
                  duration: (400 + index * 40).ms,
                  begin: 0.2,
                  end: 1.0,
                  alignment: Alignment.bottomCenter,
                ),
          ),
        ),
      ),
    );
  }
}
