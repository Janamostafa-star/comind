import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../domain/models/session_model.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../widgets/glassmorphism_card.dart';
import 'note_detail_screen.dart';

class NotesSummaryScreen extends StatefulWidget {
  const NotesSummaryScreen({super.key});

  @override
  State<NotesSummaryScreen> createState() => _NotesSummaryScreenState();
}

class _NotesSummaryScreenState extends State<NotesSummaryScreen> {
  String _searchQuery = '';
  String _sortOption = 'Date'; // Date, Color
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  String _formatDate(DateTime dt) {
    return "${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  List<Map<String, dynamic>> _groupNotesByDate(List notes) {
    // 1. Filter
    final filteredNotes = notes.where((note) {
      if (_searchQuery.isEmpty) return true;
      return note.content.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // 2. Group
    final Map<String, List> grouped = {};
    for (var note in filteredNotes) {
      final date = DateFormat('yyyy-MM-dd').format(note.timestamp);
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(note);
    }

    // 3. Sort Groups
    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => (b.key).compareTo(a.key)); // Newest date first

    return sortedEntries.map((entry) {
      return {
        'date': entry.key,
        'notes': entry.value,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = context.watch<AppState>();
    final notes = appState.savedNotes;
    final activeNotes = appState.notes;
    
    // Deduplicate notes by ID
    final Set<String> seenIds = {};
    final allNotes = <NoteModel>[];
    for (var n in [...activeNotes, ...notes]) {
      if (n.id.isNotEmpty) {
        if (!seenIds.contains(n.id)) {
          seenIds.add(n.id);
          allNotes.add(n);
        }
      } else {
        allNotes.add(n);
      }
    }

    final groupedNotes = _groupNotesByDate(allNotes);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _showSearch 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('My Notebook'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
            tooltip: _showSearch ? 'Close Search' : 'Search notes',
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortDialog(context),
            tooltip: 'Sort notes',
          ),
          if (!_showSearch) ...[
             const SizedBox(width: 8),
             _buildAvatar(context),
             const SizedBox(width: 16),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Stats header
            if (!_showSearch) _buildStatsHeader(appState),
            
            // Notes List
            Expanded(
              child: allNotes.isEmpty
                  ? _buildEmptyState()
                  : groupedNotes.isEmpty && _searchQuery.isNotEmpty
                      ? const Center(child: Text('No notes found', style: TextStyle(color: Colors.white54)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: groupedNotes.length,
                          itemBuilder: (context, index) {
                            final dateGroup = groupedNotes[index];
                            return _buildDateGroup(dateGroup['date'] as String, dateGroup['notes'] as List, theme, context);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NoteDetailScreen(),
            ),
          );
        },
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'New Note',
      ),
    );
  }

  Widget _buildStatsHeader(AppState appState) {
    final totalNotes = appState.savedNotes.length + appState.notes.length;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.neonCyan.withValues(alpha: 0.2),
            AppTheme.neonPurple.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonCyan.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.note, '$totalNotes', 'Total Notes'),
          _buildStatItem(Icons.video_call, '${appState.meetings?.length ?? 0}', 'Sessions'),
          _buildStatItem(Icons.access_time, '${appState.totalStudyHours.toStringAsFixed(1)}h', 'Study Time'),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.neonCyan, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: AppTheme.neonCyan.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notes yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notes from your meetings will appear here',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildDateGroup(String date, List notes, ThemeData theme, BuildContext context) {
    // ... same as before but using local variables ...
    final dateTime = DateTime.parse(date);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == date;
    final isYesterday = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1))) == date;
    
    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('MMMM d, yyyy').format(dateTime);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            dateLabel,
            style: TextStyle(
              color: AppTheme.neonCyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...notes.map((note) => _buildNoteCard(note, theme, context)),
      ],
    );
  }

  Widget _buildNoteCard(note, ThemeData theme, BuildContext context) {
      // ... Same implementation as stateless widget ...
    final noteColor = Color(note.color);
    final preview = note.content.split('\n').first;
    //final previewText = preview.length > 50 ? '${preview.substring(0, 50)}...' : preview;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: GlassmorphismCard(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NoteDetailScreen(
                  existingTitle: preview.isEmpty ? 'Untitled Note' : preview,
                  initialContent: note.content,
                  existingNote: note,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isEmpty ? 'Untitled Note' : note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: noteColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                      color: AppTheme.darkCard,
                      onSelected: (value) {
                         // Actions for share/delete
                         if (value == 'share_text') {
                             Share.share(note.content, subject: preview);
                         } else if (value == 'delete') {
                             final appState = Provider.of<AppState>(context, listen: false);
                             appState.deleteNote(note.id);
                         }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'share_text', child: Text('Share Text', style: TextStyle(color: Colors.white))),
                        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                      ],
                    ),
                  ],
                ),
                  const SizedBox(height: 8),
                  Text(
                    note.content,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 12),
                 Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('hh:mm a').format(note.timestamp.toLocal()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  void _showSortDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        title: const Text('Sort Notes', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.white70),
              title: const Text('By Date', style: TextStyle(color: Colors.white)),
              onTap: () {
                 // Already sorted by date by default, but could toggle asc/desc
                 Navigator.pop(context);
              },
            ),
             // Placeholder for other sorts
             ListTile(
              leading: const Icon(Icons.sort_by_alpha, color: Colors.white70),
              title: const Text('Alphabetical', style: TextStyle(color: Colors.white)),
              onTap: () {
                 Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAvatar(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final name = user?.name ?? 'Student';
    
    return Center(
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: user?.avatarUrl != null
              ? (user!.avatarUrl!.startsWith('data:')
                  ? Image.memory(
                      base64Decode(user.avatarUrl!.split(',').last),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context, name),
                    )
                  : Image.network(
                      user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(context, name),
                    ))
              : _buildAvatarPlaceholder(context, name),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(BuildContext context, String name) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'G',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
