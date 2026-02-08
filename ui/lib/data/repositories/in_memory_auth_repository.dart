import 'dart:async';
import 'dart:convert';
import '../../domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/user_repository.dart';

class InMemoryAuthRepository implements AuthRepository, UserRepository {
  final _userController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;
  
  // Simulated "Database" of users with persistence
  List<UserModel> _users = [];
  bool _initialized = false;

  InMemoryAuthRepository() {
    _initPromise = _loadUsers();
  }
  
  late Future<void> _initPromise;

  Future<void> _loadUsers() async {
    if (_initialized) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Load users
    final usersJson = prefs.getStringList('users_db');
    if (usersJson != null) {
      _users = usersJson
          .map((str) => UserModel.fromJson(jsonDecode(str)))
          .toList();
    } else {
      // Add demo user if DB is empty
      _users = [
        UserModel(
          id: '1', 
          name: 'Demo Student', 
          email: 'student@demo.com', 
          role: 'student',
          passwordHash: 'password', // Simple hash simulation
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          lastLogin: DateTime.now(),
          avatarUrl: 'https://i.pravatar.cc/150?u=1',
          language: 'en',
          theme: 'dark',
        ),
      ];
      await _saveUsers();
    }
    
    // Restore session
    final userId = prefs.getString('user_id');
    if (userId != null) {
      try {
        final user = _users.firstWhere((u) => u.id == userId);
        _currentUser = user;
        _userController.add(_currentUser);
      } catch (e) {
        await prefs.remove('user_id');
        _userController.add(null);
      }
    } else {
      _userController.add(null);
    }
    
    _initialized = true;
  }
  
  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = _users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList('users_db', usersJson);
  }

  @override
  Stream<UserModel?> get user => _userController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> login(String email, String password) async {
    await _initPromise; // Ensure DB is loaded
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final user = _users.firstWhere(
        (u) => u.email == email && u.passwordHash == password, 
      );
      
      // Update last login
      _currentUser = user.copyWith(lastLogin: DateTime.now());
      _userController.add(_currentUser);
      
      // Persist Session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      
      // Update user in DB
      await updateUser(_currentUser!);
      
      return _currentUser!;
    } catch (e) {
      throw Exception('Invalid email or password');
    }
  }

  @override
  Future<UserModel> register(String name, String email, String password, String role) async {
    await _initPromise;
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Check if email exists
    if (_users.any((u) => u.email == email)) {
      throw Exception('Email already in use');
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
      passwordHash: password, // In real app, hash this!
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      avatarUrl: 'https://i.pravatar.cc/150?u=${email.length}',
    );
    
    _users.add(newUser);
    _currentUser = newUser;
    _userController.add(newUser);
    
    await _saveUsers();
    
    // Persist Session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', newUser.id);
    
    return newUser;
  }

  @override
  Future<void> logout() async {
    await _initPromise;
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _userController.add(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  // Auto-login check
  Future<UserModel?> autoLogin() async {
    await _initPromise; // Load users first
    if (_currentUser != null) return _currentUser;
    return null; // Already handled in _loadUsers
  }

  @override
  Stream<String?> authStateChanges() {
    return _userController.stream.map((user) => user?.id);
  }

  @override
  String? getCurrentUserId() => _currentUser?.id;

  @override
  bool isAuthenticated() => _currentUser != null;

  @override
  Future<String> signInWithEmail({required String email, required String password}) async {
    final user = await login(email, password);
    return user.id;
  }

  @override
  Future<String> signUpWithEmail({required String email, required String password, required String name}) async {
    final user = await register(name, email, password, 'student');
    return user.id;
  }

  @override
  Future<void> signOut() => logout();

  @override
  Future<void> sendEmailVerification() async {
    // Mock implementation
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<bool> isEmailVerified() async {
    return true; // Mock always verified
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (_currentUser == null) throw Exception('No user logged in');
    // For mock, we ignore the userId param in the internal method or update it to use currentUser
    if (_currentUser!.passwordHash != currentPassword) {
      throw Exception('Current password is incorrect');
    }
    
    _currentUser = _currentUser!.copyWith(passwordHash: newPassword);
    _userController.add(_currentUser);
    
    // Update in list
    final index = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (index != -1) {
      _users[index] = _currentUser!;
      await _saveUsers();
    }
    }

  // UserRepository Implementation

  @override
  Future<UserModel?> getUserById(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.email == email);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // If user already exists (created by signUpWithEmail), update them
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
    } else {
      _users.add(user);
    }
    _currentUser = user;
    _userController.add(user);
    await _saveUsers();
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user;
      if (_currentUser?.id == user.id) {
        _currentUser = user;
        _userController.add(user);
      }
      await _saveUsers();
    }
  }

  @override
  Future<void> updateLanguage(String userId, String language) async {
    final user = await getUserById(userId);
    if (user != null) {
      await updateUser(user.copyWith(language: language));
    }
  }

  @override
  Future<void> updateTheme(String userId, String theme) async {
    final user = await getUserById(userId);
    if (user != null) {
      await updateUser(user.copyWith(theme: theme));
    }
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    final user = await getUserById(userId);
    if (user != null) {
      // Don't trigger stream update for just last login to avoid UI flickers if not needed
      final index = _users.indexWhere((u) => u.id == userId);
      if (index != -1) {
        _users[index] = user.copyWith(lastLogin: DateTime.now());
        await _saveUsers();
      }
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    if (_currentUser?.id == userId) {
      await logout();
    }
    await _saveUsers();
  }

}
