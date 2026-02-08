import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:convert';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  emailNotVerified,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  
  UserModel? _user;
  AuthStatus _status = AuthStatus.initial;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authRepository, this._userRepository) {
    // Check initial state immediately
    final currentUserId = _authRepository.getCurrentUserId();
    if (currentUserId != null) {
      _loadUser(currentUserId);
    } else {
      _status = AuthStatus.unauthenticated;
    }

    // Listen to auth state changes
    _authRepository.authStateChanges().listen((userId) async {
      if (userId != null) {
        await _loadUser(userId);
      } else {
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  // Getters
  UserModel? get user => _user;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  
  Future<void> _loadUser(String userId) async {
    try {
      _user = await _userRepository.getUserById(userId);
      
      // Check email verification status
      final isVerified = await _authRepository.isEmailVerified();
      if (isVerified) {
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.emailNotVerified;
      }
      
      // Update last login
      if (_user != null) {
        await _userRepository.updateLastLogin(userId);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user data: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      
      // Create Firebase Auth account
      final userId = await _authRepository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      
      // Create user document in Firestore
      final newUser = UserModel(
        id: userId,
        name: name,
        email: email,
        role: 'student',
        passwordHash: '', // Managed by Firebase Auth
        language: 'en',
        theme: 'dark',
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );
      
      await _userRepository.createUser(newUser);
      _user = newUser;
      _status = AuthStatus.emailNotVerified;
      
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      
      final userId = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      
      await _loadUser(userId);
      
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
    } catch (e) {
      _error = 'Failed to send verification email: $e';
      notifyListeners();
    }
  }

  /// Check and update email verification status
  Future<void> checkEmailVerification() async {
    try {
      final isVerified = await _authRepository.isEmailVerified();
      if (isVerified && _status == AuthStatus.emailNotVerified) {
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      await _authRepository.sendPasswordResetEmail(email);
      return true;
    } catch(e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepository.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
  
  /// Update user profile (name, avatar color)
  Future<void> updateProfile({String? name, int? avatarColor}) async {
    if (_user == null) return;
    
    try {
      _setLoading(true);
      
      final updatedUser = _user!.copyWith(
        name: name,
        avatarColor: avatarColor,
      );
      
      await _userRepository.updateUser(updatedUser);
      _user = updatedUser;
      
    } catch (e) {
      _error = 'Failed to update profile: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Update profile image
  Future<void> updateProfileImage(File imageFile) async {
    if (_user == null) throw Exception('User not authenticated');

    try {
      _setLoading(true);
      
      // Convert image to Base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // LinkedIn Logic: Update local UI immediately for responsiveness
      final originalUser = _user;
      _user = _user!.copyWith(avatarUrl: base64Image);
      notifyListeners();

      try {
        // Save to backend
        await _userRepository.updateUser(_user!);
        
        // Final sync: Force re-load to ensure absolute sync with backend state
        await _loadUser(_user!.id);
      } catch (e) {
        // Rollback on failure
        _user = originalUser;
        notifyListeners();
        rethrow;
      }
      
    } catch (e) {
      _error = 'Failed to upload image: $e';
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Update preferred language
  Future<void> updateLanguage(String language) async {
    if (_user == null) return;
    
    try {
      await _userRepository.updateLanguage(_user!.id, language);
      _user = _user!.copyWith(language: language);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update language: $e';
      notifyListeners();
    }
  }
  
  /// Update preferred theme
  Future<void> updateTheme(String theme) async {
    if (_user == null) return;
    
    try {
      await _userRepository.updateTheme(_user!.id, theme);
      _user = _user!.copyWith(theme: theme);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update theme: $e';
      notifyListeners();
    }
  }

  /// Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }
}
