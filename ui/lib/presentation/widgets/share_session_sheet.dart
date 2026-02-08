import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../domain/models/scheduled_session_model.dart';

class ShareSessionSheet extends StatelessWidget {
  final ScheduledSession session;

  const ShareSessionSheet({super.key, required this.session});

  String _generateShareMessage() {
    final dateStr = DateFormat('MMM dd, yyyy').format(session.startTime);
    final timeStr = DateFormat('hh:mm a').format(session.startTime);
    
    return '''
🎓 Join my study session on YallaStudy!

📚 ${session.sessionName}
🤖 AI Mode: ${session.aiMode.toUpperCase()}
⏰ ${session.durationMinutes} minutes
📅 $dateStr at $timeStr

🔗 Join here: ${session.shareableLink}
    '''.trim();
  }

  Future<void> _shareViaWhatsApp(BuildContext context) async {
    final message = _generateShareMessage();
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/?text=$encodedMessage';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareViaTelegram(BuildContext context) async {
    final message = _generateShareMessage();
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://t.me/share/url?url=${Uri.encodeComponent(session.shareableLink)}&text=$encodedMessage';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Telegram is not installed')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _shareViaEmail(BuildContext context) async {
    final message = _generateShareMessage();
    final subject = Uri.encodeComponent('Join my YallaStudy session: ${session.sessionName}');
    final body = Uri.encodeComponent(message);
    final url = 'mailto:?subject=$subject&body=$body';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No email app found')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: session.shareableLink));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _shareGeneric() async {
    final message = _generateShareMessage();
    await Share.share(
      message,
      subject: 'Join my YallaStudy session: ${session.sessionName}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Share Session',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            session.sessionName,
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Share options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareOption(
                context,
                'WhatsApp',
                Icons.chat,
                const Color(0xFF25D366),
                () => _shareViaWhatsApp(context),
              ),
              _buildShareOption(
                context,
                'Telegram',
                Icons.send,
                const Color(0xFF0088CC),
                () => _shareViaTelegram(context),
              ),
              _buildShareOption(
                context,
                'Email',
                Icons.email,
                Colors.redAccent,
                () => _shareViaEmail(context),
              ),
              _buildShareOption(
                context,
                'More',
                Icons.share,
                AppTheme.neonPurple,
                _shareGeneric,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Copy Meeting ID button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _copyMeetingId(context),
              icon: const Icon(Icons.numbers),
              label: const Text('Copy Meeting ID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                foregroundColor: AppTheme.neonCyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Copy link button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _copyLink(context),
              icon: const Icon(Icons.link),
              label: const Text('Copy Link'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _copyMeetingId(BuildContext context) async {
    // Extract meeting ID from shareable link (e.g., "https://yallastudy.app/join/123456")
    final meetingId = session.shareableLink.split('/').lastOrNull ?? session.id;
    await Clipboard.setData(ClipboardData(text: meetingId));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Meeting ID copied: $meetingId'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.9),
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildShareOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
