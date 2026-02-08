import 'dart:async';
import '../../domain/models/extended_models.dart';
import '../../domain/repositories/meeting_repository.dart';

class InMemoryMeetingRepository implements MeetingRepository {
  final List<ScheduledMeeting> _meetings = [];
  // App starts fresh with no fake data

  @override
  Future<List<ScheduledMeeting>> getMeetings() async {
    return List.from(_meetings);
  }

  @override
  Future<void> createMeeting(ScheduledMeeting meeting) async {
    _meetings.add(meeting);
    _meetings.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  @override
  Future<void> deleteMeeting(String id) async {
    _meetings.removeWhere((m) => m.id == id);
  }
}
