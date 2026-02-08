import '../models/user_model.dart';

/// Repository interface for user data operations
abstract class UserRepository {
  /// Get user by ID
  Future<UserModel?> getUserById(String userId);
  
  /// Get user by email
  Future<UserModel?> getUserByEmail(String email);
  
  /// Create a new user
  Future<void> createUser(UserModel user);
  
  /// Update user profile
  Future<void> updateUser(UserModel user);
  
  /// Update user's preferred language
  Future<void> updateLanguage(String userId, String language);
  
  /// Update user's preferred theme
  Future<void> updateTheme(String userId, String theme);
  
  /// Update user's last login time
  Future<void> updateLastLogin(String userId);
  
  /// Delete user
  Future<void> deleteUser(String userId);
}
