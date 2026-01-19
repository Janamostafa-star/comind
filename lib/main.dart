import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/voice_service.dart';
import 'core/services/ai_service.dart';
import 'data/repositories/session_repository.dart';
import 'presentation/providers/session_provider.dart';
import 'presentation/screens/voice_test_screen.dart';
import 'presentation/screens/ai_chat_screen.dart';
import 'presentation/screens/session_history_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider(create: (_) => VoiceService()),
        ChangeNotifierProvider(create: (_) => AIService()),
        
        // Repository
        Provider(create: (_) => SessionRepository()),
        
        // Session Provider
        ChangeNotifierProxyProvider2<AIService, SessionRepository, SessionProvider>(
          create: (context) => SessionProvider(
            aiService: context.read<AIService>(),
            repository: context.read<SessionRepository>(),
          ),
          update: (_, aiService, repository, previous) =>
              previous ?? SessionProvider(
                aiService: aiService,
                repository: repository,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'AI Tutor App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tutor App'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoiceTestScreen()),
                );
              },
              icon: const Icon(Icons.mic),
              label: const Text('Voice Test (Branch 1)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIChatScreen()),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('AI Chat (Branch 2)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SessionHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Session History (Branch 3)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}