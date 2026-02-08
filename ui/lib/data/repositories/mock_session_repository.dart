import 'dart:async';
import '../../domain/models/session_model.dart';
import '../../domain/models/scheduled_session_model.dart';
import '../../domain/repositories/session_repository.dart';

class MockSessionRepository implements SessionRepository {
  final List<ScheduledSession> _sessions = []; // Updated to store ScheduledSession

  @override
  Future<String> createSession(ScheduledSession session) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    _sessions.add(session);
    return session.id;
  }

  @override
  Future<void> updateSession(ScheduledSession session) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _sessions[index] = session;
    }
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _sessions.removeWhere((s) => s.id == sessionId);
  }

  @override
  Future<ScheduledSession?> getSessionById(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ScheduledSession>> getUserSessions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _sessions.where((s) => s.userId == userId).toList();
  }

  @override
  Future<List<ScheduledSession>> getUpcomingSessions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return _sessions.where((s) => s.userId == userId && s.startTime.isAfter(now)).toList();
  }

  @override
  Future<List<ScheduledSession>> getActiveSessions(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return _sessions.where((s) => s.userId == userId && s.startTime.isBefore(now) && s.endTime.isAfter(now)).toList();
  }

  @override
  Stream<List<ScheduledSession>> watchUserSessions(String userId) {
    // Simple mock stream that just emits current list once
    return Stream.value(_sessions.where((s) => s.userId == userId).toList());
  }

  // Helper for SessionModel legacy support if needed (not strictly part of interface but good for compatibility)
  Future<SessionModel?> getSessionModelById(String sessionId) async {
      final scheduled = await getSessionById(sessionId);
      if (scheduled == null) return null;
      return SessionModel(
        id: scheduled.id,
        title: scheduled.sessionName,
        hostName: scheduled.userId,
        participants: [],
        startTime: scheduled.startTime,
        aiRole: scheduled.aiMode,
        slides: scheduled.materialUrls,
      );
  }
}
