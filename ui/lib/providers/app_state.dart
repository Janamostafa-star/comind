import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../core/theme.dart';
import '../domain/models/session_model.dart';
import '../domain/models/extended_models.dart';
import '../domain/repositories/chat_repository.dart';
import '../domain/repositories/meeting_repository.dart';
import '../domain/repositories/forest_repository.dart';
import '../domain/repositories/note_repository.dart';
import '../data/repositories/in_memory_chat_repository.dart';
import '../data/repositories/in_memory_meeting_repository.dart';
import '../data/repositories/in_memory_forest_repository.dart';
import '../data/repositories/api_note_repository.dart';
import '../core/api_service.dart';

import '../domain/services/ai_service.dart';

class AppState extends ChangeNotifier {
  // Repositories (Injected or Default)
  final ChatRepository _chatRepository;
  final MeetingRepository _meetingRepository;
  final ForestRepository _forestRepository;
  final NoteRepository _noteRepository;
  final AiService _aiService = AiService();
  String? _currentUserId;
  
  // Public repository getters for main.dart sync
  ChatRepository get chatRepository => _chatRepository;
  MeetingRepository get meetingRepository => _meetingRepository;
  ForestRepository get forestRepository => _forestRepository;
  NoteRepository get noteRepository => _noteRepository;

  AppState({
    ChatRepository? chatRepository,
    MeetingRepository? meetingRepository,
    ForestRepository? forestRepository,
    NoteRepository? noteRepository,
    String? userId,
  })  : _chatRepository = chatRepository ?? InMemoryChatRepository(),
        _meetingRepository = meetingRepository ?? InMemoryMeetingRepository(),
        _forestRepository = forestRepository ?? InMemoryForestRepository(),
        _noteRepository = noteRepository ?? ApiNoteRepository(ApiService()), // Fallback to basic ApiService if null
        _currentUserId = userId {
      // Listen to AI voice state
      _aiService.speakingStream.listen((speaking) {
        _isAiSpeaking = speaking;
        notifyListeners();
      });
      _loadPersistentNotes();
  }

  // Persistence methods
  Future<void> _loadPersistentNotes() async {
    try {
      _savedNotes = await _noteRepository.getNotes();
      notifyListeners();
      refreshData(); // Sync with repository
    } catch (e) {
      debugPrint('Error loading notes: $e');
    }
  }

  // Local persistence removed in favor of Backend Repository
  Future<void> _persistNotes() async {}

  Future<void> deleteNote(String id) async {
    _savedNotes.removeWhere((n) => n.id == id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    await _noteRepository.deleteNote(id);
  }
  
  // Data Caches
  List<ChatConversation>? _chats;
  List<ScheduledMeeting>? _meetings;
  ForestStats? _forestStats;
  
  List<ChatConversation>? get chats => _chats;
  List<ScheduledMeeting>? get meetings => _meetings;
  ForestStats? get forestStats => _forestStats;

  Map<String, double> _dailyHistory = {};
  Map<String, double> get dailyHistory => _dailyHistory;

  int _sessionsCompleted = 0;
  int get sessionsCompleted => _sessionsCompleted;

  int _streakDays = 0;
  int get streakDays => _streakDays;

  double _focusScore = 0;
  double get focusScore => _focusScore;

  Map<String, double> _subjectBreakdown = {};
  Map<String, double> get subjectBreakdown => _subjectBreakdown;

  double _totalStudyHours = 0;
  double get totalStudyHours => _totalStudyHours;

  Future<void> refreshData() async {
    if (_currentUserId == null) {
      _clearData();
      return;
    }
    _chats = await _chatRepository.getChats();
    _meetings = await _meetingRepository.getMeetings();
    _forestStats = await _forestRepository.getStats();
    await fetchAnalytics();
    notifyListeners();
  }

  void _clearData() {
    _chats = null;
    _meetings = null;
    _forestStats = null;
    _savedNotes = [];
    _notes = [];
    _currentSession = null;
    _remainingTime = Duration.zero;
    _timer?.cancel();
    _dailyHistory = {};
    _sessionsCompleted = 0;
    _streakDays = 0;
    _focusScore = 0;
    _subjectBreakdown = {};
    _totalStudyHours = 0;
    notifyListeners();
  }

  void updateDependencies({
    required String? userId,
  }) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null) {
        _loadPersistentNotes();
        refreshData();
      } else {
        _clearData();
      }
    }
  }

  Future<void> fetchAnalytics() async {
    try {
      final apiResponse = await ( ( _noteRepository as ApiNoteRepository ).api ).get('/student/analytics');
      if (apiResponse['success'] == true) {
        final Map<String, dynamic> history = apiResponse['dailyHistory'] ?? {};
        _dailyHistory = history.map((key, value) => MapEntry(key, (value as num).toDouble()));
        
        _totalStudyHours = (apiResponse['totalHours'] ?? 0).toDouble();
        _sessionsCompleted = apiResponse['sessionsCompleted'] ?? 0;
        _streakDays = apiResponse['streakDays'] ?? 0;
        _focusScore = (apiResponse['focusScore'] ?? 0).toDouble();
        
        final Map<String, dynamic> breakdown = apiResponse['subjectBreakdown'] ?? {};
        _subjectBreakdown = breakdown.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
    } catch (e) {
      debugPrint('Error fetching analytics: $e');
    }
  }

  Future<void> addChat(ChatConversation chat) async {
    await _chatRepository.createChat(chat);
    await refreshData();
  }

  Future<void> addMeeting(ScheduledMeeting meeting) async {
    // Optimistic update
    if (_meetings != null) {
      _meetings!.add(meeting);
      _meetings!.sort((a, b) => a.startTime.compareTo(b.startTime));
      notifyListeners();
    }
    
    await _meetingRepository.createMeeting(meeting);
    // Refresh to ensure sync, but user sees it instantly
    await refreshData();
  }

  Future<void> deleteMeeting(String id) async {
    await _meetingRepository.deleteMeeting(id);
    await refreshData();
  }

  Future<void> recordSession(int minutes) async {
    // "oak" is default tree for now. logic can be expanded
    await _forestRepository.addFocusSession(minutes, 'oak');
    await refreshData();
  }

  // Theme Management
  AppThemeType _currentTheme = AppThemeType.nightFocus;
  
  AppThemeType get currentTheme => _currentTheme;
  
  // Backwards compatibility for MaterialApp logic (though we'll update main.dart too)
  ThemeMode get themeMode => AppTheme.getConfig(_currentTheme).isDark ? ThemeMode.dark : ThemeMode.light;
  
  void setTheme(AppThemeType type) {
    _currentTheme = type;
    notifyListeners();
  }
  
  // Legacy toggle (cycles through themes now or just toggles dark/light equivalent?)
  // Let's make it cycle for fun, or just keep it simple.
  // Better to deprecate toggle and use explicit set in Settings.
  void toggleTheme() {
    // Simple cycle for debug purposes
    final nextIndex = (_currentTheme.index + 1) % AppThemeType.values.length;
    _currentTheme = AppThemeType.values[nextIndex];
    notifyListeners();
  }
  
  // Language Management
  String _languageCode = 'en';
  String get languageCode => _languageCode;
  
  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }

  // Session Management
  Timer? _timer;
  Duration _sessionDuration = const Duration(minutes: 30); // Default 30 mins
  Duration _remainingTime = Duration.zero;
  
  // Active Session State
  SessionModel? _currentSession;
  int _currentSlideIndex = 0;
  List<NoteModel> _notes = [];
  List<NoteModel> _savedNotes = [];
  bool _handRaised = false;
  bool _isAiSpeaking = false;
  String? _aiResponseText;

  // Getters
  Duration get sessionDuration => _sessionDuration;
  Duration get remainingTime => _remainingTime;
  
  SessionModel? get currentSession => _currentSession;
  bool get isSessionActive => _currentSession != null;
  int get currentSlideIndex => _currentSlideIndex;
  List<NoteModel> get notes => _notes;
  List<NoteModel> get savedNotes => _savedNotes;
  bool get isHandRaised => _handRaised;

  // ... (startSession methods)

  bool _isListening = false;
  bool get isListening => _isListening;

  Future<void> startListening() async {
    _isListening = true;
    notifyListeners();
    // STT service removed - placeholder for future implementation
  }

  Future<void> stopListening() async {
    _isListening = false;
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await stopListening();
    } else {
      await startListening();
    }
  }

  Future<void> _handleAiResponseToVoice(String userText) async {
    // 1. Speak response (Echoing or answering)
    // Simulate smart AI response
    final responses = [
      "That's an excellent question. Let's break it down together.",
      "I see what you mean. Here is a different perspective on that.",
      "Great observation! This connects back to our earlier topic.",
      "Let me clarify that point for you.",
      "I heard you say: $userText. That's interesting!",
    ];
    final randomResponse = responses[DateTime.now().millisecondsSinceEpoch % responses.length];
    
    _aiResponseText = randomResponse;
    notifyListeners();
    await _aiService.speak(_aiResponseText!);
  }

  void saveSessionNotes() {
    if (_notes.isEmpty) return;
    
    _savedNotes.addAll(_notes);
    _notes.clear();
    _persistNotes();
    notifyListeners();
  }
  bool get isAiSpeaking => _isAiSpeaking;
  String? get aiResponseText => _aiResponseText;
  
  // Calculated Getters useful for UI
  int get userLevel => ((totalStudyHours / 10) + 1).floor();
  ForestStats? get forest => _forestStats;

  void setSessionDuration(int minutes) {
    _sessionDuration = Duration(minutes: minutes);
    notifyListeners();
  }

  void startSession(SessionModel session) {
    _currentSession = session;
    _currentSlideIndex = 0;
    _notes = [];
    _handRaised = false;
    _isAiSpeaking = false;
    
    // Start Timer
    _remainingTime = _sessionDuration;
    _startTimer();
    
    // Trigger AI Welcome
    _triggerAiWelcome();
    
    notifyListeners();
  }
  
  Future<void> _triggerAiWelcome() async {
    await _aiService.initialize();
    if (_currentSession != null) {
      final script = _aiService.getWelcomeMessage(_currentSession!.aiRole, _currentSession!.title);
      await _aiService.speak(script);
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        _remainingTime -= const Duration(seconds: 1);
        notifyListeners();
      } else {
        _timer?.cancel();
        // Option: Auto-end session or just stay at 00:00
      }
    });
  }
  
  void endSession() {
    _timer?.cancel();
    _aiService.stop(); // Stop speaking
    _currentSession = null;
    _isAiSpeaking = false;
    _handRaised = false;
    _currentSlideIndex = 0;
    notifyListeners();
  }
  
  // AI State
  void toggleAiSpeaking() {
     // In real app, this might pause TTS?
    _isAiSpeaking = !_isAiSpeaking;
    if (_isAiSpeaking) {
       // Mock resume
       if (_handRaised) _handRaised = false;
    } else {
       _aiService.stop();
    }
    notifyListeners();
  }
  
  void raiseHand() {
    _handRaised = !_handRaised;
    if (_handRaised && _isAiSpeaking) {
       _aiService.stop(); // Silence AI when interrupting
      _isAiSpeaking = false; 
    }
    notifyListeners();
  }
  
  void toggleHandRaised() {
    raiseHand();
  }
  
  void pauseAiSpeaking() {
    if (_isAiSpeaking) {
      _aiService.stop();
      _isAiSpeaking = false;
      notifyListeners();
    }
  }
  
  // Slide Navigation
  void nextSlide() {
    if (_currentSession?.slides != null) {
      if (_currentSlideIndex < (_currentSession!.slides!.length - 1)) {
        _currentSlideIndex++;
        notifyListeners();
      }
    }
  }
  
  void previousSlide() {
    if (_currentSlideIndex > 0) {
      _currentSlideIndex--;
      notifyListeners();
    }
  }
  
  // Notes
  Future<void> addNote(String content, {String? title, int color = 0xFFFFFFFF}) async {
    final note = NoteModel(
      id: '', // Will be assigned by backend
      title: title ?? 'Untitled Note',
      content: content,
      slideNumber: _currentSlideIndex,
      timestamp: DateTime.now(),
      color: color,
    );
    
    // In session mode, we might want to keep it in _notes until session end
    // But for the detail screen/advanced panel, we might want to save it immediately.
    // Let's avoid local duplicate by not adding to _notes if we are about to save it to backend which refreshes _savedNotes.
    
    final savedNote = await _noteRepository.createNote(note);
    _savedNotes.add(savedNote);
    notifyListeners();
  }

  Future<void> updateNote(NoteModel updatedNote) async {
    final index = _savedNotes.indexWhere((n) => n.id == updatedNote.id);
    if (index != -1) {
      _savedNotes[index] = updatedNote;
      notifyListeners();
      await _noteRepository.updateNote(updatedNote);
    }
  }

  Future<void> saveNewNote(NoteModel note) async {
    final savedNote = await _noteRepository.createNote(note);
    _savedNotes.add(savedNote);
    notifyListeners();
  }
  
  // STT
  // Methods moved to top
  
  @override
  void dispose() {
    _timer?.cancel();
    _aiService.dispose();
    super.dispose();
  }
}
