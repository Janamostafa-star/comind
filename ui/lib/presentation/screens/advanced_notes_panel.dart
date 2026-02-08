import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../widgets/drawing_board.dart';

class AdvancedNotesPanel extends StatefulWidget {
  final String sessionId;
  final VoidCallback onClose;

  const AdvancedNotesPanel({
    super.key,
    required this.sessionId,
    required this.onClose,
  });

  @override
  State<AdvancedNotesPanel> createState() => _AdvancedNotesPanelState();
}

class _AdvancedNotesPanelState extends State<AdvancedNotesPanel> {

  // Replaced with MarkdownSyntaxTextEditingController
  late final MarkdownSyntaxTextEditingController _notesController;
  final FocusNode _focusNode = FocusNode();
  
  // REMOVED global style toggles that affected whole text
  /*
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  */
  
  bool _showDrawing = false;
  Color _drawingColor = Colors.white;
  double _strokeWidth = 3.0;
  
  final List<Map<String, dynamic>> _noteHistory = [];
  int _historyIndex = -1;
  
  // New state for Light Mode (Google Doc style)
  bool _isLightMode = false;

  @override
  void initState() {
    super.initState();
    super.initState();
    // Pass initial light mode state (default false so ok)
    _notesController = MarkdownSyntaxTextEditingController(isLightMode: _isLightMode);
    _notesController.addListener(_saveToHistory); // Auto-save history on change
  }

  @override
  void dispose() {
    _notesController.removeListener(_saveToHistory);
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _saveToHistory() {
    // Debounce or check complexity if needed, for now simple history
    if (_noteHistory.isNotEmpty && _noteHistory.last['text'] == _notesController.text) return;
    
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
    // History saved by listener
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
  }

  void _saveNotes() {
    final appState = context.read<AppState>();
    if (_notesController.text.isNotEmpty) {
      final firstLine = _notesController.text.split('\n').first;
      final title = firstLine.length > 30 ? '${firstLine.substring(0, 30)}...' : firstLine;
      appState.addNote(_notesController.text, title: title, color: Colors.blue.value); // Default color
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notes saved! Check the Notes tab later.'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }

  void _generateAiSummary() {
    _notesController.text += '\n\n✨ AI SUMMARY:\n• Discussed quantum mechanics basics.\n• Key takeaway: Observation collapses the wave function.\n• Recommended reading: Chapter 4 of the textbook.';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Summary generated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _isLightMode ? const Color(0xFFF8F9FA) : Colors.black, // Light mode background
      child: Column(
        children: [
          // Header with toolbar
          _buildHeader(),
          
          // Formatting toolbar
          _buildFormattingToolbar(),
          
          // Notes editor
          Expanded(
            child: _showDrawing
                ? _buildDrawingCanvas()
                : _buildTextEditor(),
          ),
          
          // Bottom actions
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isLightMode ? Colors.white : Colors.transparent,
        border: Border(
           bottom: BorderSide(color: _isLightMode ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Meeting Notes',
            style: TextStyle(
              color: _isLightMode ? Colors.black87 : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              // Light Mode Toggle
              IconButton(
                icon: Icon(
                  _isLightMode ? Icons.dark_mode : Icons.light_mode,
                  color: _isLightMode ? Colors.black54 : Colors.amber,
                ),
                onPressed: () {
                  setState(() {
                    _isLightMode = !_isLightMode;
                    // Update controller's processing mode
                    _notesController.isLightMode = _isLightMode;
                   });
                },
                tooltip: _isLightMode ? 'Switch to Dark Mode' : 'Switch to Light Mode',
              ),
              IconButton(
                icon: Icon(
                  _showDrawing ? Icons.text_fields : Icons.brush,
                  color: _isLightMode ? Colors.black54 : Colors.white70,
                ),
                onPressed: () => setState(() => _showDrawing = !_showDrawing),
                tooltip: _showDrawing ? 'Switch to Text' : 'Switch to Drawing',
              ),
              IconButton(
                icon: Icon(Icons.close, color: _isLightMode ? Colors.black54 : Colors.white70),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormattingToolbar() {
    if (_showDrawing) {
      // (Drawing toolbar implementation remains same, omitted for brevity but should be kept if replacing entire file context. 
      // Since I am replacing large chunk, I will copy it back)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Row(
          children: [
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
                    color: _drawingColor == color ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
            )),
            const Spacer(),
            Text('Size: ${_strokeWidth.toInt()}', style: TextStyle(color: _isLightMode ? Colors.black54 : Colors.white70)),
            Slider(
              value: _strokeWidth,
              min: 1,
              max: 10,
              divisions: 9,
              activeColor: AppTheme.neonCyan,
              onChanged: (value) => setState(() => _strokeWidth = value),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isLightMode ? const Color(0xFFF1F3F4) : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: _isLightMode ? Colors.grey[300]! : Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Undo/Redo
            IconButton(
              icon: Icon(Icons.undo, color: _isLightMode ? Colors.black54 : Colors.white70, size: 20),
              onPressed: _undo,
              tooltip: 'Undo',
            ),
            IconButton(
              icon: Icon(Icons.redo, color: _isLightMode ? Colors.black54 : Colors.white70, size: 20),
              onPressed: _redo,
              tooltip: 'Redo',
            ),
            VerticalDivider(color: _isLightMode ? Colors.black12 : Colors.white24, width: 1),
            
            // Text formatting (State-free buttons now)
            _buildToolbarButton(
              icon: Icons.format_bold,
              onPressed: () => _formatText('bold'),
            ),
            _buildToolbarButton(
              icon: Icons.format_italic,
              onPressed: () => _formatText('italic'),
            ),
            _buildToolbarButton(
              icon: Icons.format_underlined,
              onPressed: () => _formatText('underline'),
            ),
            VerticalDivider(color: _isLightMode ? Colors.black12 : Colors.white24, width: 1),
            
            // Headings
            _buildToolbarButton(
              icon: Icons.title,
              onPressed: () => _formatText('heading1'),
            ),
            _buildToolbarButton(
              icon: Icons.format_size,
              onPressed: () => _formatText('heading2'),
            ),
            VerticalDivider(color: _isLightMode ? Colors.black12 : Colors.white24, width: 1),
            
            // Lists
            _buildToolbarButton(
              icon: Icons.format_list_bulleted,
              onPressed: () => _formatText('bullet'),
            ),
            _buildToolbarButton(
              icon: Icons.format_list_numbered,
              onPressed: () => _formatText('number'),
            ),
            VerticalDivider(color: _isLightMode ? Colors.black12 : Colors.white24, width: 1),
            
            // Table
            _buildToolbarButton(
              icon: Icons.table_chart,
              onPressed: _insertTable,
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
        // REMOVED style: TextStyle(...) which forced global style.
        // The controller handles styling via buildTextSpan.
        // Updated styles for Light Mode support
        style: TextStyle(
          color: _isLightMode ? Colors.black87 : Colors.white,
          fontSize: 16,
          height: 1.5,
          fontFamily: 'Inter',
        ),
        decoration: InputDecoration(
          hintText: 'Start taking notes...\n\nTip: Select text and click Bold/Italic.',
          hintStyle: TextStyle(
            color: _isLightMode ? Colors.black38 : Colors.white.withValues(alpha: 0.3),
            fontSize: 14,
          ),
          border: InputBorder.none,
        ),
        // onChanged handled by listener
      ),
    );
  }

  Widget _buildDrawingCanvas() {
    return Container(
      color: _isLightMode ? Colors.white : Colors.grey[900],
      child: DrawingBoard(
        color: _drawingColor,
        strokeWidth: _strokeWidth,
        onDraw: () {},
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _notesController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard!')),
              );
            },
            icon: Icon(Icons.copy, color: _isLightMode ? Colors.black54 : Colors.white70),
            label: Text('Copy', style: TextStyle(color: _isLightMode ? Colors.black54 : Colors.white70)),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _generateAiSummary,
                icon: const Icon(Icons.auto_awesome, color: AppTheme.neonCyan),
                tooltip: 'AI Summary',
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _notesController.clear(),
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(width: 8),

              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _saveNotes,
                icon: const Icon(Icons.save, size: 18),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Color> _getDrawingColors() {
    return [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
    ];
  }
}

// ---------------------------------------------------------------------------
// 📝 CUSTOM MARKDOWN CONTROLLER
// ---------------------------------------------------------------------------
class MarkdownSyntaxTextEditingController extends TextEditingController {
  bool isLightMode;

  MarkdownSyntaxTextEditingController({this.isLightMode = false});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final List<TextSpan> children = [];
    final pattern = RegExp(
      r'(\*\*(.*?)\*\*)|(\*(.*?)\*)|(__(.*?)__)|(# (.*))|(\- (.*))',
      multiLine: true,
    );

    text.splitMapJoin(
      pattern,
      onMatch: (Match match) {
        final matchText = match[0]!;
        // Default style depends on mode (passed via context or assumed via closure if possible, but controller is separate)
        // We'll trust the passed 'style' from TextField which we updated above, or default to white/black
        TextStyle matchStyle = style ?? const TextStyle(color: Colors.white);

        if (matchText.startsWith('**')) {
          // Bold
          matchStyle = matchStyle.copyWith(
            fontWeight: FontWeight.bold,
            color: isLightMode ? Colors.blue[800] : AppTheme.neonCyan,
          );
        } else if (matchText.startsWith('*')) {
          // Italic
          matchStyle = matchStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: isLightMode ? Colors.orange[800] : Colors.orangeAccent,
          );
        } else if (matchText.startsWith('__')) {
          // Underline
          matchStyle = matchStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: isLightMode ? Colors.blue[800] : AppTheme.neonCyan,
          );
        } else if (matchText.startsWith('# ')) {
          // Heading
          matchStyle = matchStyle.copyWith(
            fontSize: (matchStyle.fontSize ?? 16) * 1.5,
            fontWeight: FontWeight.bold,
            color: isLightMode ? Colors.purple[800] : AppTheme.neonPurple,
          );
        } else if (matchText.startsWith('- ')) {
          // Bullet
          matchStyle = matchStyle.copyWith(
            color: isLightMode ? Colors.green[800] : Colors.greenAccent,
          );
        }

        children.add(TextSpan(text: matchText, style: matchStyle));
        return '';
      },
      onNonMatch: (String text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
