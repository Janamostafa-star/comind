import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../core/theme.dart';
import '../widgets/gradient_button.dart';

class NotesSummaryScreen extends StatelessWidget {
  const NotesSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final notes = appState.notes;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notes & Summary'),
            actions: [
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {},
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Session Info
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonCyan.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.school, color: Colors.white, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                appState.currentSession?.name ?? 'Study Session',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoChip(Icons.access_time, '45 min'),
                            const SizedBox(width: 12),
                            _InfoChip(Icons.slideshow, '12 slides'),
                            const SizedBox(width: 12),
                            _InfoChip(Icons.note, '${notes.length} notes'),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
                  
                  const SizedBox(height: 32),
                  
                  // AI Summary
                  Text(
                    'AI-Generated Summary',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 16),
                  
                  _SummaryCard(
                    title: 'Key Concepts',
                    content: '''
• (Auto-generated from session content)
• Focus was maintained for 85% of time
                    ''',
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  const SizedBox(height: 32),
                  
                  // Your Notes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Notes',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.add, color: AppTheme.neonCyan),
                        label: Text('Add Note', style: TextStyle(color: AppTheme.neonCyan)),
                      ),
                    ],
                  ).animate().fadeIn(delay: 500.ms),
                  
                  const SizedBox(height: 16),
                  
                  if (notes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No notes taken during this session.',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  else
                    ...notes
                      .asMap()
                      .entries
                      .map((e) => _NoteCard(
                            slideNumber: e.key + 1, // Mock slide number
                            content: e.value.content,
                            timestamp: '${e.value.timestamp.hour}:${e.value.timestamp.minute.toString().padLeft(2, '0')}',
                          ).animate(delay: (600 + e.key * 100).ms).fadeIn().slideY(begin: 0.2, end: 0))
                      .toList(),

              
              const SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: 'Download PDF',
                      icon: Icons.picture_as_pdf,
                      onPressed: () {},
                      gradient: AppTheme.primaryGradient,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.quiz, color: AppTheme.neonPurple),
                      label: const Text('Take Quiz'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.neonPurple,
                        side: BorderSide(color: AppTheme.neonPurple, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String content;

  const _SummaryCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.neonCyan,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final int slideNumber;
  final String content;
  final String timestamp;

  const _NoteCard({
    required this.slideNumber,
    required this.content,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonPurple.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.neonPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.slideshow, size: 12, color: AppTheme.neonPurple),
                    const SizedBox(width: 4),
                    Text(
                      'Slide $slideNumber',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.neonPurple,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.access_time, size: 12, color: AppTheme.textTertiary),
              const SizedBox(width: 4),
              Text(
                timestamp,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
