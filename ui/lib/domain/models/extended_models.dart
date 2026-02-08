
// Chat Model
class ChatConversation {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isOnline;
  final String avatarUrl; // Mock URL or asset path
  final int avatarColor;
  final bool isAi;

  ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.isOnline,
    required this.avatarUrl,
    this.avatarColor = 0xFF2196F3, // Default blue
    this.isAi = false,
  });
}

// Scheduled Meeting Model (Extends concept of Session)
class ScheduledMeeting {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String meetingId;
  final String hostName;
  final List<String> participants;
  final String aiRole;
  final int durationMinutes;

  ScheduledMeeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.meetingId,
    required this.hostName,
    required this.participants,
    required this.aiRole,
    required this.durationMinutes,
  });
}

// Gamification Model
class ForestStats {
  final int totalFocusMinutes;
  final int currentStreakDays;
  final int treesPlanted;
  final int seeds;
  final List<TreeGrowth> recentGrowth;

  ForestStats({
    required this.totalFocusMinutes,
    required this.currentStreakDays,
    required this.treesPlanted,
    required this.seeds,
    required this.recentGrowth,
  });

  Map<String, dynamic> toJson() => {
    'totalFocusMinutes': totalFocusMinutes,
    'currentStreakDays': currentStreakDays,
    'treesPlanted': treesPlanted,
    'seeds': seeds,
    'recentGrowth': recentGrowth.map((t) => t.toJson()).toList(),
  };

  factory ForestStats.fromJson(Map<String, dynamic> json) => ForestStats(
    totalFocusMinutes: json['totalFocusMinutes'] ?? 0,
    currentStreakDays: json['currentStreakDays'] ?? 0,
    treesPlanted: json['treesPlanted'] ?? 0,
    seeds: json['seeds'] ?? 0,
    recentGrowth: (json['recentGrowth'] as List?)?.map((t) => TreeGrowth.fromJson(t)).toList() ?? [],
  );
}

class TreeGrowth {
  final String id;
  final DateTime plantedDate;
  final String type; // 'oak', 'pine', etc.
  final int focusMinutes;

  TreeGrowth({
    required this.id,
    required this.plantedDate,
    required this.type,
    required this.focusMinutes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'plantedDate': plantedDate.toIso8601String(),
    'type': type,
    'focusMinutes': focusMinutes,
  };

  factory TreeGrowth.fromJson(Map<String, dynamic> json) => TreeGrowth(
    id: json['id'],
    plantedDate: DateTime.parse(json['plantedDate']),
    type: json['type'],
    focusMinutes: json['focusMinutes'] ?? 0,
  );
}
