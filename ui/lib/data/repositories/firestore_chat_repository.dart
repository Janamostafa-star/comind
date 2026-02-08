import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/extended_models.dart';
import '../../domain/repositories/chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<ChatConversation>> getChats() async {
    try {
      final snapshot = await _firestore.collection('chats')
          .orderBy('lastMessageTime', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatConversation(
          id: doc.id,
          name: data['contactName'] ?? 'Unknown',
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: (data['lastMessageTime'] as Timestamp).toDate(),
          unreadCount: data['unreadCount'] ?? 0,
          avatarColor: data['avatarColor'] ?? 0xFF0000FF,
          isOnline: data['isOnline'] ?? false,
          avatarUrl: data['avatarUrl'] ?? '', // Default empty if not present
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createChat(ChatConversation chat) async {
    await _firestore.collection('chats').add({
      'contactName': chat.name,
      'lastMessage': chat.lastMessage,
      'lastMessageTime': Timestamp.fromDate(chat.lastMessageTime),
      'unreadCount': chat.unreadCount,
      'avatarColor': chat.avatarColor,
      'isOnline': chat.isOnline,
    });
  }

  @override
  Future<void> deleteChat(String id) async {
    await _firestore.collection('chats').doc(id).delete();
  }

  @override
  Future<void> markAsRead(String id) async {
    await _firestore.collection('chats').doc(id).update({'unreadCount': 0});
  }
}
