import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';

class AiService {
  final FlutterTts _flutterTts = FlutterTts();
  
  // Stream to notify when AI starts/stops speaking
  final _speakingController = StreamController<bool>.broadcast();
  Stream<bool> get speakingStream => _speakingController.stream;
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Normal speed
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _speakingController.add(true);
    });

    _flutterTts.setCompletionHandler(() {
      _speakingController.add(false);
    });

    _flutterTts.setCancelHandler(() {
      _speakingController.add(false);
    });
    
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
  
  // Script Generation Logic
  String getWelcomeMessage(String role, String topic) {
    if (role == 'tutor') {
      return "Welcome to our session on $topic. I am your AI Tutor. I'm here to guide you through the materials. Let's get started!";
    } else {
      // Classmate
      return "Hey! Ready to crush this $topic session? I'm your study buddy. Let's do this!";
    }
  }
  
  String getThinkingMessage() {
    return "Hmm, let me think about that for a second...";
  }
  
  void dispose() {
    _flutterTts.stop();
    _speakingController.close();
  }
}
