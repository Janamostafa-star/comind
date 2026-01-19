import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/voice_service.dart';
import 'presentation/screens/voice_test_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoiceService(),
      child: MaterialApp(
        title: 'AI Tutor App - Voice Test',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const VoiceTestScreen(),
      ),
    );
  }
}