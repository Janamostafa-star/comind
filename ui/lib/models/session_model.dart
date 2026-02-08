class SessionModel {
  final String id;
  final String name;
  final String aiRole; // 'tutor' or 'classmate'
  final DateTime createdAt;
  final List<String>? slides;
  final int participantCount;
  
  SessionModel({
    required this.id,
    required this.name,
    required this.aiRole,
    required this.createdAt,
    this.slides,
    this.participantCount = 1,
  });
  
  factory SessionModel.mock(String name, String role) {
    return SessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      aiRole: role,
      createdAt: DateTime.now(),
      participantCount: 1,
    );
  }
}

class NoteModel {
  final String id;
  final String content;
  final int slideNumber;
  final DateTime timestamp;
  
  NoteModel({
    required this.id,
    required this.content,
    required this.slideNumber,
    required this.timestamp,
  });
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
