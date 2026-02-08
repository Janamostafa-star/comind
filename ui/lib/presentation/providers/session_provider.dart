import 'package:flutter/foundation.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/scheduled_session_model.dart';
import '../../domain/repositories/session_repository.dart';

class SessionProvider extends ChangeNotifier {
  final SessionRepository _sessionRepository;
  
  SessionModel? _currentSession;
  bool _isLoading = false;
  String? _error;

  SessionProvider(this._sessionRepository);

  SessionModel? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createSession({
    required ScheduledSession session,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final sessionId = await _sessionRepository.createSession(session);
      
      // In a real app, we might fetch the full session using the ID
      // For now, we manually map ScheduledSession to SessionModel if possible, or just set it
      // Since _currentSession is SessionModel, we need a converter. 
      // For now, let's create a SessionModel from ScheduledSession
      _currentSession = SessionModel(
        id: sessionId,
        title: session.sessionName,
        hostName: session.userId, // User ID as host name for now
        participants: [],
        startTime: session.startTime,
        aiRole: session.aiMode,
        slides: session.materialUrls,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void endSession() {
    _currentSession = null;
    notifyListeners();
  }

  Future<List<ScheduledSession>> getUserSessions(String userId) async {
    return _sessionRepository.getUserSessions(userId);
  }

  Future<List<ScheduledSession>> getUpcomingSessions(String userId) async {
    return _sessionRepository.getUpcomingSessions(userId);
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionRepository.deleteSession(sessionId);
    notifyListeners();
  }
}
