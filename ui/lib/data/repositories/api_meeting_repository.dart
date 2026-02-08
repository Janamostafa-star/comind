import '../../domain/repositories/meeting_repository.dart';
import '../../domain/models/extended_models.dart';
import '../../core/api_service.dart';

class ApiMeetingRepository implements MeetingRepository {
  final ApiService _api;
  
  ApiMeetingRepository(this._api);

  @override
  Future<List<ScheduledMeeting>> getMeetings() async {
    final response = await _api.get('/student/meetings');
    if (response['success'] == true) {
      final List<dynamic> data = response['meetings'];
      return data.map((json) => ScheduledMeeting(
        id: json['id'],
        title: json['title'],
        hostName: json['hostName'],
        meetingId: json['meetingId'],
        startTime: DateTime.parse(json['startTime']),
        endTime: DateTime.parse(json['endTime']),
        participants: List<String>.from(json['participants'] ?? []),
        aiRole: json['aiRole'],
        durationMinutes: json['durationMinutes'],
      )).toList();
    }
    return [];
  }

  @override
  Future<void> createMeeting(ScheduledMeeting meeting) async {
    await _api.post('/student/meetings', {
      'title': meeting.title,
      'hostName': meeting.hostName,
      'meetingId': meeting.meetingId,
      'startTime': meeting.startTime.toIso8601String(),
      'endTime': meeting.endTime.toIso8601String(),
      'participants': meeting.participants,
      'aiRole': meeting.aiRole,
      'durationMinutes': meeting.durationMinutes,
    });
  }

  @override
  Future<void> deleteMeeting(String id) async {
    await _api.delete('/student/meetings/$id');
  }
}
