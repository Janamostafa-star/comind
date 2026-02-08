class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'host'
  final String? bio; // Added bio field
  final String? avatarUrl;
  final int? avatarColor;
  final String passwordHash;
  final String language;
  final String theme;
  final DateTime createdAt;
  final DateTime lastLogin;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.bio,
    this.avatarUrl,
    this.avatarColor,
    required this.passwordHash,
    this.language = 'en',
    this.theme = 'dark',
    required this.createdAt,
    required this.lastLogin,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? bio,
    String? avatarUrl,
    int? avatarColor,
    String? passwordHash,
    String? language,
    String? theme,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      passwordHash: passwordHash ?? this.passwordHash,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  // Basic JSON serialization for mock persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'avatarColor': avatarColor,
      'passwordHash': passwordHash,
      'language': language,
      'theme': theme,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      bio: map['bio'],
      avatarUrl: map['avatarUrl'],
      avatarColor: map['avatarColor'],
      passwordHash: map['passwordHash'] ?? '',
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'dark',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      lastLogin: DateTime.tryParse(map['lastLogin'] ?? '') ?? DateTime.now(),
    );
  }
  
  /// Firestore serialization (excludes password hash for security)
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'avatarColor': avatarColor,
      'language': language,
      'theme': theme,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
    };
  }
  
  /// Create UserModel from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> doc) {
    return UserModel(
      id: doc['id'] ?? '',
      name: doc['name'] ?? '',
      email: doc['email'] ?? '',
      role: doc['role'] ?? 'student',
      bio: doc['bio'],
      avatarUrl: doc['avatarUrl'],
      avatarColor: doc['avatarColor'],
      passwordHash: '', // Password hash is managed by Firebase Auth
      language: doc['language'] ?? 'en',
      theme: doc['theme'] ?? 'dark',
      createdAt: DateTime.tryParse(doc['createdAt'] ?? '') ?? DateTime.now(),
      lastLogin: DateTime.tryParse(doc['lastLogin'] ?? '') ?? DateTime.now(),
    );
  }
}
