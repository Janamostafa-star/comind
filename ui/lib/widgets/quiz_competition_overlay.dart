import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';
import 'glassmorphism_card.dart';

class QuizCompetitionOverlay extends StatefulWidget {
  final VoidCallback onClose;
  
  const QuizCompetitionOverlay({super.key, required this.onClose});

  @override
  State<QuizCompetitionOverlay> createState() => _QuizCompetitionOverlayState();
}

class _QuizCompetitionOverlayState extends State<QuizCompetitionOverlay> {
  int _userScore = 0;
  int _aiScore = 0;
  int _currentQuestionIndex = 0;
  bool _isAiTurn = false;
  int? _selectedAnswer;
  bool _showResult = false;
  
  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Which of the following creates a new object in OOP?',
      'options': ['class', 'new', 'extends', 'static'],
      'correct': 1,
    },
    {
      'question': 'What is the Big O complexity of binary search?',
      'options': ['O(n)', 'O(n²)', 'O(log n)', 'O(1)'],
      'correct': 2,
    },
    {
      'question': 'Which keyword is used to handle exceptions?',
      'options': ['try', 'catch', 'throw', 'all of them'],
      'correct': 3,
    },
  ];

  void _submitAnswer(int index) {
    if (_selectedAnswer != null || _isAiTurn) return; // Block interaction

    setState(() {
      _selectedAnswer = index;
    });

    final correct = _questions[_currentQuestionIndex]['correct'] as int;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (index == correct) {
        setState(() => _userScore += 10);
      }
      
      // AI Turn Simulation
      setState(() => _isAiTurn = true);
      
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        // AI Logic: 80% chance to be correct
        final aiCorrect = (DateTime.now().millisecond % 10) < 8;
        if (aiCorrect) {
          setState(() => _aiScore += 10);
        }
        
        // Next Question
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          if (_currentQuestionIndex < _questions.length - 1) {
            setState(() {
              _currentQuestionIndex++;
              _selectedAnswer = null;
              _isAiTurn = false;
            });
          } else {
            setState(() => _showResult = true);
          }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark Overlay background
        Positioned.fill(
          child: Container(color: Colors.black54).animate().fadeIn(),
        ),
        
        // Main Card
        Center(
          child: Container(
            width: 500,
            height: 600,
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
            padding: const EdgeInsets.all(20),
            child: _showResult ? _buildResultView() : _buildQuizView(),
          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
        ),
      ],
    );
  }

  Widget _buildQuizView() {
    final q = _questions[_currentQuestionIndex];
    
    return GlassmorphismCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // Important for scroll view in center
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPlayerScore('You', _userScore, Icons.person, Colors.blue),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Q${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  _buildPlayerScore('AI Classmate', _aiScore, Icons.smart_toy, AppTheme.neonPurple),
                ],
              ),
              
              const SizedBox(height: 40), // Replaced Spacer with fixed space
              
              // Question
              Text(
                q['question'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ).animate(key: ValueKey(_currentQuestionIndex)).fadeIn().moveY(begin: 10),
              
              const SizedBox(height: 40),
              
              // Options
              ...List.generate(4, (index) {
                final option = q['options'][index];
                final isSelected = _selectedAnswer == index;
                final showCorrect = _selectedAnswer != null && index == q['correct'];
                final showWrong = isSelected && index != q['correct'];
                
                Color color = Colors.white10;
                if (showCorrect) color = Colors.green.withValues(alpha: 0.6);
                if (showWrong) color = Colors.red.withValues(alpha: 0.6);
                if (isSelected && !showWrong && !showCorrect) color = AppTheme.neonCyan.withValues(alpha: 0.3);

                return GestureDetector(
                  onTap: () => _submitAnswer(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent, 
                        width: 1
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54),
                            color: isSelected ? Colors.white : null,
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.black) : null,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          option,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              
              const SizedBox(height: 24), // Replaced Spacer with fixed space
              
              // Status bar
              if (_isAiTurn)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                     const SizedBox(width: 12),
                     Text('AI is answering...', style: TextStyle(color: Colors.white70)),
                  ],
                ).animate().fadeIn(),
                
              if (!_isAiTurn)
                Center(
                  child: TextButton(
                    onPressed: widget.onClose,
                    child: const Text('Exit Quiz', style: TextStyle(color: Colors.white54)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultView() {
    final won = _userScore > _aiScore;
    final tie = _userScore == _aiScore;
    
    return GlassmorphismCard(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              won ? Icons.emoji_events : (tie ? Icons.handshake : Icons.sentiment_dissatisfied),
              size: 80,
              color: won ? Colors.amber : (tie ? Colors.blue : Colors.grey),
            ).animate().scale().then().shimmer(),
            const SizedBox(height: 24),
            Text(
              won ? 'You Won!' : (tie ? 'It\'s a Tie!' : 'AI Won!'),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Final Score: $_userScore - $_aiScore',
              style: const TextStyle(color: Colors.white70, fontSize: 20),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Return to Meeting'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
        Text('$score', style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
