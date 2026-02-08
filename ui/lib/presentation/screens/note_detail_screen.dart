import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/drawing_board.dart';
import '../../widgets/glassmorphism_card.dart';
import '../../domain/models/session_model.dart';
import 'package:share_plus/share_plus.dart';

class NoteDetailScreen extends StatefulWidget {
  final String? existingTitle;
  final String? initialContent;
  final NoteModel? existingNote;
  
  const NoteDetailScreen({
    super.key, 
    this.existingTitle, 
    this.initialContent,
    this.existingNote,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Formatting State
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  TextAlign _textAlign = TextAlign.left;
  Color _textColor = Colors.white;
  Color _highlightColor = Colors.transparent;
  double _fontSize = 16.0;
  String _fontFamily = 'Inter';
  
  // Drawing State
  bool _showDrawing = false;
  Color _drawingColor = Colors.white;
  double _strokeWidth = 3.0;
  
  // History
  final List<Map<String, dynamic>> _noteHistory = [];
  int _historyIndex = -1;

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title;
      _notesController.text = widget.existingNote!.content;
      _textColor = Color(widget.existingNote!.color);
    } else {
      if (widget.existingTitle != null) {
        _titleController.text = widget.existingTitle!;
      }
      if (widget.initialContent != null) {
        _notesController.text = widget.initialContent!;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveToHistory() {
    _noteHistory.add({
      'text': _notesController.text,
      'timestamp': DateTime.now(),
    });
    _historyIndex = _noteHistory.length - 1;
  }

  void _undo() {
    if (_historyIndex > 0) {
      setState(() {
        _historyIndex--;
        _notesController.text = _noteHistory[_historyIndex]['text'] as String;
      });
    }
  }

  void _redo() {
    if (_historyIndex < _noteHistory.length - 1) {
      setState(() {
        _historyIndex++;
        _notesController.text = _noteHistory[_historyIndex]['text'] as String;
      });
    }
  }

  void _formatText(String format) {
    final selection = _notesController.selection;
    if (!selection.isValid) return;

    final text = _notesController.text;
    final selectedText = text.substring(selection.start, selection.end);
    
    String formattedText = '';
    switch (format) {
      case 'bold':
        formattedText = '**$selectedText**';
        break;
      case 'italic':
        formattedText = '*$selectedText*';
        break;
      case 'underline':
        formattedText = '__${selectedText}__';
        break;
      case 'heading1':
        formattedText = '# $selectedText';
        break;
      case 'heading2':
        formattedText = '## $selectedText';
        break;
      case 'bullet':
        formattedText = '- $selectedText';
        break;
      case 'number':
        formattedText = '1. $selectedText';
        break;
    }

    final newText = text.replaceRange(selection.start, selection.end, formattedText);
    _notesController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + formattedText.length),
    );
    
    _saveToHistory();
  }

  void _insertTable() {
    final table = '''
| Header 1 | Header 2 | Header 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

''';
    final selection = _notesController.selection;
    final text = _notesController.text;
    final newText = text.replaceRange(selection.start, selection.end, table);
    _notesController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + table.length),
    );
    _saveToHistory();
  }

  void _saveNote() {
    final appState = context.read<AppState>();
    if (_notesController.text.isNotEmpty) {
      final title = _titleController.text.trim().isEmpty 
          ? 'Untitled Note' 
          : _titleController.text.trim();
          
      if (widget.existingNote != null) {
        // Update existing
        final updatedNote = NoteModel(
          id: widget.existingNote!.id,
          title: title,
          content: _notesController.text,
          slideNumber: widget.existingNote!.slideNumber,
          timestamp: DateTime.now(),
          color: _textColor.value,
        );
        appState.updateNote(updatedNote);
      } else {
        // Create new
        appState.addNote(_notesController.text, title: title, color: _textColor.value);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note saved successfully!'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _generateAiSummary() {
    setState(() {
      _notesController.text += '\n\n✨ AI SUMMARY:\n• Discussed key project milestones.\n• Action item: Review design mocks by Friday.\n• Next meeting scheduled for Monday.';
    });
    _saveToHistory();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Summary generated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Note Title',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showDrawing ? Icons.text_fields : Icons.brush,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _showDrawing = !_showDrawing),
            tooltip: _showDrawing ? 'Switch to Text' : 'Switch to Drawing',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting to PDF... (Simulation)')),
               );
            },
            tooltip: 'Export as PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              Share.share(_notesController.text, subject: _titleController.text);
            },
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(
            primaryColor: Color(0xFF101010),
            secondaryColor: Color(0xFF2C2C2C),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Formatting Toolbar - NOW ENABLED with better UI
                _buildFormattingToolbar(),
                
                // Editor Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GlassmorphismCard(
                      padding: EdgeInsets.zero,
                      child: _showDrawing 
                          ? _buildDrawingCanvas() 
                          : _buildTextEditor(),
                    ),
                  ),
                ),
                
                // Bottom Status Bar with enhanced character/word count
                _buildBottomStatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    if (_showDrawing) {
      // Drawing Mode Toolbar
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.darkCard.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: AppTheme.neonCyan.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Drawing Colors
            Text(
              'Color:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            ..._getDrawingColors().map((color) => GestureDetector(
              onTap: () => setState(() => _drawingColor = color),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _drawingColor == color ? AppTheme.neonCyan : Colors.white24,
                    width: _drawingColor == color ? 3 : 1,
                  ),
                  boxShadow: _drawingColor == color
                      ? [
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.3),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
              ),
            )),
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 32,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 16),
            // Brush Size
            Text(
              'Size:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_strokeWidth.toInt()}px',
                style: const TextStyle(
                  color: AppTheme.neonCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Slider(
                value: _strokeWidth,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: AppTheme.neonCyan,
                inactiveColor: AppTheme.neonCyan.withValues(alpha: 0.2),
                onChanged: (value) => setState(() => _strokeWidth = value),
              ),
            ),
            const SizedBox(width: 8),
            // Clear Canvas Button
            TextButton.icon(
              onPressed: () {
                // Reset drawing - would need drawing controller implementation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Canvas cleared')),
                );
              },
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      );
    }

    // Text Mode Toolbar
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.undo, color: Colors.white70, size: 20),
              onPressed: _undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: const Icon(Icons.redo, color: Colors.white70, size: 20),
              onPressed: _redo,
              tooltip: 'Redo',
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(
              icon: Icons.format_bold,
              isActive: _isBold,
              onPressed: () {
                setState(() => _isBold = !_isBold);
                _formatText('bold');
              },
            ),
            _buildToolbarButton(
              icon: Icons.format_italic,
              isActive: _isItalic,
              onPressed: () {
                setState(() => _isItalic = !_isItalic);
                _formatText('italic');
              },
            ),
            _buildToolbarButton(
              icon: Icons.format_underlined,
              isActive: _isUnderline,
              onPressed: () {
                setState(() => _isUnderline = !_isUnderline);
                _formatText('underline');
              },
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(icon: Icons.title, onPressed: () => _formatText('heading1')),
            _buildToolbarButton(icon: Icons.format_size, onPressed: () => _formatText('heading2')),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(icon: Icons.format_list_bulleted, onPressed: () => _formatText('bullet')),
            _buildToolbarButton(icon: Icons.format_list_numbered, onPressed: () => _formatText('number')),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            _buildToolbarButton(icon: Icons.table_chart, onPressed: _insertTable),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
             // Color picker
            PopupMenuButton<Color>(
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _textColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 2),
                ),
              ),
              color: AppTheme.darkCard,
              tooltip: 'Text Color',
              itemBuilder: (context) => _getTextColors().map((color) {
                return PopupMenuItem(
                  value: color,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                  ),
                );
              }).toList(),
              onSelected: (color) => setState(() => _textColor = color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return IconButton(
      icon: Icon(icon, color: isActive ? AppTheme.neonCyan : Colors.white70, size: 20),
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? AppTheme.neonCyan.withValues(alpha: 0.2) : null,
      ),
    );
  }

  Widget _buildTextEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _notesController,
        focusNode: _focusNode,
        maxLines: null,
        expands: true,
        style: TextStyle(
          color: _textColor,
          backgroundColor: _highlightColor,
          fontSize: _fontSize,
          fontFamily: _fontFamily,
          fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
        ),
        textAlign: _textAlign,
        decoration: InputDecoration(
          hintText: 'Start taking notes...',
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          border: InputBorder.none,
        ),
        onChanged: (_) => _saveToHistory(),
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return Container(
      color: Colors.white,
      child: DrawingBoard(
        color: _drawingColor,
        strokeWidth: _strokeWidth,
        onDraw: () {},
      ),
    );
  }

  Widget _buildBottomStatusBar() {
    final charCount = _notesController.text.length;
    final wordCount = _notesController.text.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Enhanced character and word count display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.neonCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$wordCount',
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  wordCount == 1 ? 'word' : 'words',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                const SizedBox(width: 12),
                Text(
                  '$charCount',
                  style: const TextStyle(
                    color: AppTheme.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  charCount == 1 ? 'char' : 'chars',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Auto-save indicator
          if (_notesController.text.isNotEmpty)
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.neonGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Auto-saved',
                  style: TextStyle(
                    color: AppTheme.neonGreen.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          // AI Summary button
          TextButton.icon(
            onPressed: _generateAiSummary,
            icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.neonCyan),
            label: const Text(
              'AI Summary',
              style: TextStyle(color: AppTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: AppTheme.neonCyan.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getTextColors() {
    return [Colors.white, Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple];
  }

  List<Color> _getDrawingColors() {
    return [Colors.black, Colors.red, Colors.blue, Colors.green, Colors.purple, Colors.orange];
  }
}
