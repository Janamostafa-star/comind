import '../../domain/repositories/chat_repository.dart';
import '../../domain/models/extended_models.dart';
import '../../core/api_service.dart';

class ApiChatRepository implements ChatRepository {
  final ApiService _api;
  
  ApiChatRepository(this._api);

  @override
  Future<List<ChatConversation>> getChats() async {
    final response = await _api.get('/student/chats');
    if (response['success'] == true) {
      final List<dynamic> data = response['chats'];
      return data.map((json) => ChatConversation(
        id: json['id'],
        name: json['name'],
        lastMessage: json['lastMessage'],
        lastMessageTime: DateTime.parse(json['lastMessageTime']),
        unreadCount: json['unreadCount'],
        isOnline: json['isOnline'],
        avatarUrl: json['avatarUrl'],
        isAi: json['isAi'],
      )).toList();
    }
    return [];
  }

  @override
  Future<void> createChat(ChatConversation chat) async {
    await _api.post('/student/chats', {
      'name': chat.name,
      'lastMessage': chat.lastMessage,
      'unreadCount': chat.unreadCount,
      'isOnline': chat.isOnline,
      'avatarUrl': chat.avatarUrl,
      'isAi': chat.isAi,
    });
  }

  @override
  Future<void> deleteChat(String id) async {
    await _api.delete('/student/chats/$id');
  }

  @override
  Future<void> markAsRead(String id) async {
    // Backend doesn't have explicit markAsRead logic yet in Chat model, 
    // but we can just post an update if needed.
    // For now, minimal implementation.
  }
}
