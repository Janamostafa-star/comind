import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_model.dart';

/// Repository for managing session data
/// Uses SharedPreferences for local storage
class SessionRepository {
  static const String _sessionsKey = 'saved_sessions';

  // ========== Save Session ==========
  /// Save a session to local storage
  Future<void> saveSession(SessionModel session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing sessions
      final sessions = await getAllSessions();
      
      // Add new session
      sessions.add(session);
      
      // Convert to JSON
      final jsonList = sessions.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      // Save
      await prefs.setString(_sessionsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  // ========== Get All Sessions ==========
  /// Retrieve all saved sessions
  Future<List<SessionModel>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionsKey);
      
      if (jsonString == null) return [];
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => SessionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load sessions: $e');
    }
  }

  // ========== Get Session by ID ==========
  /// Get a specific session by ID
  Future<SessionModel?> getSessionById(String id) async {
    final sessions = await getAllSessions();
    try {
      return sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  // ========== Delete Session ==========
  /// Delete a session by ID
  Future<void> deleteSession(String id) async {
    try {
      final sessions = await getAllSessions();
      sessions.removeWhere((s) => s.id == id);

      final prefs = await SharedPreferences.getInstance();
      final jsonList = sessions.map((s) => s.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      
      await prefs.setString(_sessionsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // ========== Clear All Sessions ==========
  /// Delete all sessions
  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }
}