import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../../providers/app_state.dart';
import '../../../domain/models/extended_models.dart';

class ChatTab extends StatefulWidget {
  const ChatTab({super.key});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  @override
  void initState() {
    super.initState();
    // Trigger data fetch if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      if (appState.chats == null) {
        appState.refreshData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppTheme.neonCyan), 
            onPressed: () => _showAddChatDialog(context),
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          if (appState.chats == null) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.neonCyan),
            );
          }

          if (appState.chats!.isEmpty) {
            return Center(
              child: Text(
                'No conversations yet',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: appState.refreshData,
            color: AppTheme.neonCyan,
            backgroundColor: AppTheme.darkCard,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: appState.chats!.length,
              itemBuilder: (context, index) {
                final chat = appState.chats![index];
                return _ChatTile(chat: chat, index: index);
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddChatDialog(BuildContext context) {
    final nameController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('New Chat', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Initial Message',
                labelStyle: TextStyle(color: AppTheme.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.textSecondary)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCyan),
            onPressed: () {
              if (nameController.text.isNotEmpty && messageController.text.isNotEmpty) {
                final newChat = ChatConversation(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  lastMessage: messageController.text,
                  lastMessageTime: DateTime.now(),
                  unreadCount: 0,
                  isOnline: false,
                  avatarUrl: 'default_avatar', // Placeholder
                );
                
                context.read<AppState>().addChat(newChat);
                Navigator.pop(context);
              }
            },
            child: const Text('Start Chat', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatConversation chat;
  final int index;

  const _ChatTile({required this.chat, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Stack(
          children: [
            Container(
              width: 50, 
              height: 50,
              decoration: BoxDecoration(
                color: chat.isAi ? AppTheme.neonCyan.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                chat.isAi ? Icons.smart_toy : Icons.person,
                color: chat.isAi ? AppTheme.neonCyan : Colors.white,
              ),
            ),
            if (chat.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.darkCard, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          chat.name,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: chat.unreadCount > 0 ? Colors.white : AppTheme.textSecondary,
            fontWeight: chat.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             Text(
              _formatTime(chat.lastMessageTime),
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            if (chat.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        onTap: () {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat with ${chat.name}')));
        },
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(begin: 0.1, end: 0);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[time.weekday - 1];
    } else {
      return '${time.day}/${time.month}';
    }
  }
}
