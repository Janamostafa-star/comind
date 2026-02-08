import 'dart:async';
import '../../domain/models/extended_models.dart';
import '../../domain/repositories/chat_repository.dart';

class InMemoryChatRepository implements ChatRepository {
  final List<ChatConversation> _chats = [];
  // App starts fresh with no fake data

  @override
  Future<List<ChatConversation>> getChats() async {
    return List.from(_chats);
  }

  @override
  Future<void> createChat(ChatConversation chat) async {
    _chats.insert(0, chat); // Add to top
  }

  @override
  Future<void> deleteChat(String id) async {
    _chats.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> markAsRead(String id) async {
    final index = _chats.indexWhere((c) => c.id == id);
    if (index != -1) {
      final chat = _chats[index];
      _chats[index] = ChatConversation(
        id: chat.id,
        name: chat.name,
        lastMessage: chat.lastMessage,
        lastMessageTime: chat.lastMessageTime,
        unreadCount: 0,
        isOnline: chat.isOnline,
        avatarUrl: chat.avatarUrl,
        isAi: chat.isAi,
      );
    }
  }
}
