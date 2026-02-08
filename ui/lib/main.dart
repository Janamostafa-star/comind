import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/api_service.dart';
import 'providers/app_state.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/session_provider.dart';
import 'data/repositories/mock_session_repository.dart';
import 'screens/splash_screen.dart';

import 'data/repositories/api_auth_repository.dart';
import 'data/repositories/api_session_repository.dart';
import 'data/repositories/api_forest_repository.dart';
import 'data/repositories/api_meeting_repository.dart';
import 'data/repositories/api_chat_repository.dart';
import 'data/repositories/api_note_repository.dart';
import 'domain/repositories/chat_repository.dart';
import 'domain/repositories/meeting_repository.dart';
import 'domain/repositories/forest_repository.dart';
import 'domain/repositories/note_repository.dart';
import 'providers/visual_state_provider.dart';

// Global instances for async initialization
late ApiService _apiService;
late ApiAuthRepository _authRepository;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize API service and auth repository
  print('🚀 INITIALIZING API SERVICE...');
  _apiService = ApiService();
  _authRepository = ApiAuthRepository(_apiService);
  await _authRepository.init();
  print('✅ API AUTH REPOSITORY INITIALIZED');
  
  runApp(const YallaStudyApp());
}

class YallaStudyApp extends StatelessWidget {
  const YallaStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VisualStateProvider()),
        // 1. Auth Provider (handles User identity) - using API repository
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(_authRepository, _authRepository),
        ),
        
        // 2. Data Repositories (Singleton instances)
        Provider<ChatRepository>(
          create: (_) => ApiChatRepository(_apiService),
        ),
        Provider<MeetingRepository>(
          create: (_) => ApiMeetingRepository(_apiService),
        ),
        Provider<NoteRepository>(
          create: (_) => ApiNoteRepository(_apiService),
        ),
        Provider<ForestRepository>(
          create: (_) => ApiForestRepository(_apiService),
        ),

        // 3. App State (Injecting Repositories + Auth Dependency)
        ChangeNotifierProxyProvider5<ChatRepository, MeetingRepository, ForestRepository, NoteRepository, AuthProvider, AppState>(
          create: (context) => AppState(
            chatRepository: context.read<ChatRepository>(),
            meetingRepository: context.read<MeetingRepository>(),
            forestRepository: context.read<ForestRepository>(),
            noteRepository: context.read<NoteRepository>(),
            userId: context.read<AuthProvider>().user?.id,
          ),
          update: (context, chat, meeting, forest, note, auth, previous) {
            final appState = previous ?? AppState(
              chatRepository: chat,
              meetingRepository: meeting,
              forestRepository: forest,
              noteRepository: note,
              userId: auth.user?.id,
            );
            appState.updateDependencies(userId: auth.user?.id);
            return appState;
          },
        ),
        
        // 4. Session Provider (Connected to Backend)
        ChangeNotifierProvider(
          create: (_) => SessionProvider(ApiSessionRepository(_apiService)),
        ),
      ],
      child: Consumer2<AppState, VisualStateProvider>(
        builder: (context, appState, visualState, _) {
          return MaterialApp(
            title: 'YallaStudy',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.getTheme(visualState.theme),
            themeMode: ThemeMode.light,
            locale: Locale(appState.languageCode),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}


