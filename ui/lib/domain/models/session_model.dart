class SessionModel {
  final String id;
  final String title;
  final String hostName;
  final List<String> participants;
  final DateTime startTime;
  final String aiRole; // 'tutor' or 'classmate'
  final List<String>? slides; // List of URLs or paths

  SessionModel({
    required this.id,
    required this.title,
    required this.hostName,
    required this.participants,
    required this.startTime,
    required this.aiRole,
    this.slides,
  });

  String get name => title; // Alias for title if needed by older code
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final int slideNumber;
  final DateTime timestamp;
  final int color; // Hex color value

  NoteModel({
    required this.id,
    this.title = 'Untitled Note',
    required this.content,
    required this.slideNumber,
    required this.timestamp,
    this.color = 0xFFFFFFFF,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'slideNumber': slideNumber,
    'timestamp': timestamp.toIso8601String(),
    'color': color,
  };

  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
    id: json['id'],
    title: json['title'] ?? 'Untitled Note',
    content: json['content'],
    slideNumber: json['slideNumber'] ?? 0,
    timestamp: DateTime.parse(json['timestamp']),
    color: json['color'] ?? 0xFFFFFFFF,
  );
}
