
/// Model for a scheduled study session
class ScheduledSession {
  final String id;
  final String userId; // Who created the session
  final String sessionName;
  final String aiMode; // 'tutor' or 'classmate'
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  
  // Optional settings
  final bool showSlides;
  final bool enableCamera;
  final bool enableMic;
  
  // Materials
  final List<String> materialUrls; // URLs to uploaded PDFs/PPTs in Firebase Storage
  
  // Sharing
  final String shareableLink;
  final DateTime createdAt;
  
  const ScheduledSession({
    required this.id,
    required this.userId,
    required this.sessionName,
    required this.aiMode,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    this.showSlides = true,
    this.enableCamera = true,
    this.enableMic = true,
    this.materialUrls = const [],
    required this.shareableLink,
    required this.createdAt,
  });
  
  DateTime get endTimeCalculated => startTime.add(Duration(minutes: durationMinutes));
  
  Duration get remainingTime {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return Duration.zero;
    return endTime.difference(now);
  }
  
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
  
  bool get isUpcoming {
    final now = DateTime.now();
    return now.isBefore(startTime);
  }
  
  bool get hasEnded {
    final now = DateTime.now();
    return now.isAfter(endTime);
  }
  
  ScheduledSession copyWith({
    String? id,
    String? userId,
    String? sessionName,
    String? aiMode,
    int? durationMinutes,
    DateTime? startTime,
    DateTime? endTime,
    bool? showSlides,
    bool? enableCamera,
    bool? enableMic,
    List<String>? materialUrls,
    String? shareableLink,
    DateTime? createdAt,
  }) {
    return ScheduledSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionName: sessionName ?? this.sessionName,
      aiMode: aiMode ?? this.aiMode,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      showSlides: showSlides ?? this.showSlides,
      enableCamera: enableCamera ?? this.enableCamera,
      enableMic: enableMic ?? this.enableMic,
      materialUrls: materialUrls ?? this.materialUrls,
      shareableLink: shareableLink ?? this.shareableLink,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'sessionName': sessionName,
      'aiMode': aiMode,
      'durationMinutes': durationMinutes,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'showSlides': showSlides,
      'enableCamera': enableCamera,
      'enableMic': enableMic,
      'materialUrls': materialUrls,
      'shareableLink': shareableLink,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Create from Firestore document
  factory ScheduledSession.fromFirestore(Map<String, dynamic> doc) {
    return ScheduledSession(
      id: doc['id'] ?? '',
      userId: doc['userId'] ?? '',
      sessionName: doc['sessionName'] ?? '',
      aiMode: doc['aiMode'] ?? 'tutor',
      durationMinutes: doc['durationMinutes'] ?? 30,
      startTime: DateTime.tryParse(doc['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(doc['endTime'] ?? '') ?? DateTime.now().add(const Duration(minutes: 30)),
      showSlides: doc['showSlides'] ?? true,
      enableCamera: doc['enableCamera'] ?? true,
      enableMic: doc['enableMic'] ?? true,
      materialUrls: List<String>.from(doc['materialUrls'] ?? []),
      shareableLink: doc['shareableLink'] ?? '',
      createdAt: DateTime.tryParse(doc['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
