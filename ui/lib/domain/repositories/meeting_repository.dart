import '../models/extended_models.dart';

abstract class MeetingRepository {
  Future<List<ScheduledMeeting>> getMeetings();
  Future<void> createMeeting(ScheduledMeeting meeting);
  Future<void> deleteMeeting(String id);
}
