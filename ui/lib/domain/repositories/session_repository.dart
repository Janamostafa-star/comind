import '../models/scheduled_session_model.dart';

/// Repository interface for session management
abstract class SessionRepository {
  /// Get all sessions for a user
  Future<List<ScheduledSession>> getUserSessions(String userId);
  
  /// Get upcoming sessions for a user
  Future<List<ScheduledSession>> getUpcomingSessions(String userId);
  
  /// Get active (currently running) sessions for a user
  Future<List<ScheduledSession>> getActiveSessions(String userId);
  
  /// Get a specific session by ID
  Future<ScheduledSession?> getSessionById(String sessionId);
  
  /// Create a new session
  Future<String> createSession(ScheduledSession session);
  
  /// Update an existing session
  Future<void> updateSession(ScheduledSession session);
  
  /// Delete a session
  Future<void> deleteSession(String sessionId);
  
  /// Listen to user's sessions in real-time
  Stream<List<ScheduledSession>> watchUserSessions(String userId);
}
