/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Sign up with email and password
  /// Returns user ID on success, throws exception on error
  Future<String> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });
  
  /// Send email verification
  Future<void> sendEmailVerification();
  
  /// Check if email is verified
  Future<bool> isEmailVerified();
  
  /// Sign in with email and password
  /// Returns user ID on success, throws exception on error
  Future<String> signInWithEmail({
    required String email,
    required String password,
  });
  
  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);
  
  /// Change password (requires current password)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Sign out
  Future<void> signOut();
  
  /// Get current user ID (null if not authenticated)
  String? getCurrentUserId();
  
  /// Check if user is authenticated
  bool isAuthenticated();
  
  /// Listen to authentication state changes
  Stream<String?> authStateChanges();
}
