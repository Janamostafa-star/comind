import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/api_service.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

/// Repository that connects to the Node.js backend for authentication.
class ApiAuthRepository implements AuthRepository, UserRepository {
  final ApiService _api;
  final _authStateController = StreamController<String?>.broadcast();
  
  UserModel? _currentUser;
  bool _initialized = false;

  ApiAuthRepository(this._api);

  /// Initialize the repository and restore session
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    
    await _api.init();
    
    if (_api.hasToken) {
      // Try to restore session
      try {
        final response = await _api.get('/session/me');
        if (response['success'] == true && response['user'] != null) {
          final userData = response['user'];
          _currentUser = UserModel(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            role: userData['role'] ?? 'student',
            bio: userData['bio'],
            avatarUrl: userData['profilePicture'],
            passwordHash: '',
            createdAt: userData['createdAt'] != null 
                ? DateTime.parse(userData['createdAt']) 
                : DateTime.now(),
            lastLogin: DateTime.now(),
          );
          _authStateController.add(_currentUser!.id);
        } else {
          await _api.clearToken();
          _authStateController.add(null);
        }
      } catch (e) {
        // Token invalid or server unreachable
        await _api.clearToken();
        _authStateController.add(null);
      }
    } else {
      _authStateController.add(null);
    }
  }

  @override
  Stream<String?> authStateChanges() => _authStateController.stream;

  @override
  String? getCurrentUserId() => _currentUser?.id;

  @override
  bool isAuthenticated() => _currentUser != null;

  @override
  Future<String> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _api.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      'role': 'student',
    });

    if (response['success'] == true) {
      final token = response['token'] as String;
      await _api.saveToken(token);

      final userData = response['user'];
      _currentUser = UserModel(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        role: userData['role'] ?? 'student',
        bio: userData['bio'],
        avatarUrl: userData['profilePicture'],
        passwordHash: '',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      _authStateController.add(_currentUser!.id);
      return _currentUser!.id;
    } else {
      throw Exception(response['error'] ?? 'Signup failed');
    }
  }

  @override
  Future<String> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _api.post('/auth/login', {
      'email': email,
      'password': password,
    });

    if (response['success'] == true) {
      final token = response['token'] as String;
      await _api.saveToken(token);

      final userData = response['user'];
      _currentUser = UserModel(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        role: userData['role'] ?? 'student',
        bio: userData['bio'],
        avatarUrl: userData['profilePicture'],
        passwordHash: '',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      _authStateController.add(_currentUser!.id);
      return _currentUser!.id;
    } else {
      throw Exception(response['error'] ?? 'Login failed');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // Ignore logout errors
    }
    await _api.clearToken();
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> sendEmailVerification() async {
    // Not implemented in backend yet
  }

  @override
  Future<bool> isEmailVerified() async {
    return true; // Always verified for now
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Not implemented in backend yet
    throw Exception('Password reset not available yet');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Not implemented in backend yet
    throw Exception('Password change not available yet');
  }

  // UserRepository implementation

  @override
  Future<UserModel?> getUserById(String userId) async {
    // LinkedIn Logic: Always try to refresh from backend to ensure data consistency
    if (_currentUser?.id == userId) {
      try {
        final response = await _api.get('/student/profile');
        if (response['success'] == true && response['profile'] != null) {
          final userData = response['profile'];
          _currentUser = UserModel(
            id: userData['id'],
            name: userData['name'],
            email: userData['email'],
            role: userData['role'] ?? 'student',
            bio: userData['bio'],
            avatarUrl: userData['profilePicture'],
            passwordHash: '',
            createdAt: userData['createdAt'] != null 
                ? DateTime.parse(userData['createdAt']) 
                : DateTime.now(),
            lastLogin: DateTime.now(),
          );
        }
      } catch (e) {
        debugPrint('Failed to refresh user data: $e');
        // Fallback to cached user if network fails
      }
      return _currentUser;
    }
    return null;
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    if (_currentUser?.email == email) {
      return _currentUser;
    }
    return null;
  }

  @override
  Future<void> createUser(UserModel user) async {
    // User is created via signup
    _currentUser = user;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _api.put('/student/profile', {
        'name': user.name,
        'bio': user.bio,
        'profilePicture': user.avatarUrl,
      });
      _currentUser = user;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  @override
  Future<void> updateLanguage(String userId, String language) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(language: language);
    }
  }

  @override
  Future<void> updateTheme(String userId, String theme) async {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(theme: theme);
    }
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    // Handled by backend
  }

  @override
  Future<void> deleteUser(String userId) async {
    // Not implemented
  }

  void dispose() {
    _authStateController.close();
  }
}
