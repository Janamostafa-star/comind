import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/scheduled_session_model.dart';
import '../../domain/repositories/session_repository.dart';

/// Firestore implementation of SessionRepository
class FirestoreSessionRepository implements SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'sessions';
  
  @override
  Future<List<ScheduledSession>> getUserSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ScheduledSession.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user sessions: $e');
    }
  }
  
  @override
  Future<List<ScheduledSession>> getUpcomingSessions(String userId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: userId)
          .where('startTime', isGreaterThan: now.toIso8601String())
          .orderBy('startTime', descending: false)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ScheduledSession.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get upcoming sessions: $e');
    }
  }
  
  @override
  Future<List<ScheduledSession>> getActiveSessions(String userId) async {
    try {
      final now = DateTime.now();
      final sessions = await getUserSessions(userId);
      
      // Filter active sessions (started but not ended)
      return sessions.where((session) => session.isActive).toList();
    } catch (e) {
      throw Exception('Failed to get active sessions: $e');
    }
  }
  
  @override
  Future<ScheduledSession?> getSessionById(String sessionId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(sessionId)
          .get();
      
      if (!doc.exists) return null;
      
      return ScheduledSession.fromFirestore(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }
  
  @override
  Future<String> createSession(ScheduledSession session) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      final sessionWithId = session.copyWith(id: docRef.id);
      
      await docRef.set(sessionWithId.toFirestore());
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create session: $e');
    }
  }
  
  @override
  Future<void> updateSession(ScheduledSession session) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(session.id)
          .update(session.toFirestore());
    } catch (e) {
      throw Exception('Failed to update session: $e');
    }
  }
  
  @override
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(sessionId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }
  
  @override
  Stream<List<ScheduledSession>> watchUserSessions(String userId) {
    return _firestore
        .collection(_collectionName)
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ScheduledSession.fromFirestore(doc.data()))
              .toList();
        });
  }
}
