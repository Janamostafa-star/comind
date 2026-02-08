import '../models/extended_models.dart';

abstract class ChatRepository {
  Future<List<ChatConversation>> getChats();
  Future<void> createChat(ChatConversation chat);
  Future<void> deleteChat(String id);
  Future<void> markAsRead(String id);
}
