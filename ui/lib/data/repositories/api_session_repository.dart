import 'package:flutter/foundation.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/models/scheduled_session_model.dart';
import '../../core/api_service.dart';

class ApiSessionRepository implements SessionRepository {
  final ApiService _api;
  
  ApiSessionRepository(this._api);

  @override
  Future<String> createSession(ScheduledSession session) async {
    final response = await _api.post('/student/sessions', {
      'userId': session.userId,
      'sessionName': session.sessionName,
      'aiMode': session.aiMode,
      'durationMinutes': session.durationMinutes,
      'startTime': session.startTime.toIso8601String(),
      'endTime': session.endTime.toIso8601String(),
      'materialUrls': session.materialUrls,
      'shareableLink': session.shareableLink,
      'createdAt': session.createdAt.toIso8601String(),
    });

    if (response['success'] == true) {
      return response['session']['id'];
    } else {
      throw Exception(response['error'] ?? 'Failed to create session');
    }
  }

  @override
  Future<List<ScheduledSession>> getUserSessions(String userId) async {
    final response = await _api.get('/student/sessions');

    if (response['success'] == true) {
      final List<dynamic> data = response['sessions'];
      return data.map((json) => ScheduledSession(
        id: json['id'],
        userId: json['userId'] ?? '',
        sessionName: json['sessionName'] ?? json['title'] ?? '',
        aiMode: json['aiMode'] ?? json['aiRole'] ?? 'tutor',
        durationMinutes: json['durationMinutes'] ?? 30,
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        shareableLink: json['shareableLink'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
        materialUrls: List<String>.from(json['materialUrls'] ?? []),
      )).toList();
    } else {
      throw Exception(response['error'] ?? 'Failed to load sessions');
    }
  }

  @override
  Future<List<ScheduledSession>> getUpcomingSessions(String userId) async {
    final sessions = await getUserSessions(userId);
    final now = DateTime.now();
    return sessions.where((s) => s.startTime.isAfter(now)).toList();
  }

  @override
  Future<List<ScheduledSession>> getActiveSessions(String userId) async {
    final sessions = await getUserSessions(userId);
    final now = DateTime.now();
    return sessions.where((s) {
      final endTime = s.startTime.add(Duration(minutes: s.durationMinutes));
      return s.startTime.isBefore(now) && endTime.isAfter(now);
    }).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    // Not implemented in backend yet
  }

  @override
  Future<ScheduledSession?> getSessionById(String sessionId) async {
    // Not implemented
    return null;
  }

  @override
  Future<void> updateSession(ScheduledSession session) async {
    // Not implemented
  }

  @override
  Stream<List<ScheduledSession>> watchUserSessions(String userId) {
    // Fallback: simply fetch once and emit
    return Stream.fromFuture(getUserSessions(userId));
  }
}
