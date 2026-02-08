import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/extended_models.dart';
import '../../domain/repositories/meeting_repository.dart';

class FirestoreMeetingRepository implements MeetingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ScheduledMeeting>> getMeetings() async {
    // In a real app, strict rules would filter by userId, but for now we fetch all or filter client side if needed
    // Assuming 'meetings' collection
    try {
      final snapshot = await _firestore.collection('meetings')
          .orderBy('startTime', descending: false)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Need to parse DateTimes carefully or create a fromMap in Model
        // For simplicity here, manual mapping or assuming Model has it. 
        // We will assume data is compatible with Model constructors or we map it.
        // Since ScheduledMeeting doesn't have fromMap in the snippet I saw, I'll map manually.
        
        return ScheduledMeeting(
          id: doc.id,
          title: data['title'] ?? 'Untitled',
          hostName: data['hostName'] ?? 'Unknown',
          meetingId: data['meetingId'] ?? '',
          startTime: (data['startTime'] as Timestamp).toDate(),
          endTime: (data['endTime'] as Timestamp).toDate(),
          participants: List<String>.from(data['participants'] ?? []),
          aiRole: data['aiRole'] ?? 'tutor',
          durationMinutes: data['durationMinutes'] ?? 60,
        );
      }).toList();
    } catch (e) {
      // Fallback or empty if offline/fail
      return [];
    }
  }

  @override
  Future<void> createMeeting(ScheduledMeeting meeting) async {
    await _firestore.collection('meetings').add({
      'title': meeting.title,
      'hostName': meeting.hostName,
      'meetingId': meeting.meetingId,
      'startTime': Timestamp.fromDate(meeting.startTime),
      'endTime': Timestamp.fromDate(meeting.endTime),
      'participants': meeting.participants,
      'aiRole': meeting.aiRole,
      'durationMinutes': meeting.durationMinutes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteMeeting(String id) async {
    await _firestore.collection('meetings').doc(id).delete();
  }
}
