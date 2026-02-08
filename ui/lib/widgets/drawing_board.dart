import 'package:flutter/material.dart';

class DrawingBoard extends StatefulWidget {
  final Color color;
  final double strokeWidth;
  final VoidCallback? onDraw;

  const DrawingBoard({
    super.key, 
    this.color = Colors.black, 
    this.strokeWidth = 3.0,
    this.onDraw,
  });

  @override
  State<DrawingBoard> createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  final List<List<Offset>> _strokes = [];
  final List<Color> _colors = [];
  final List<double> _widths = [];
  
  List<Offset> _currentStroke = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _currentStroke = [details.localPosition];
          _strokes.add(_currentStroke);
          _colors.add(widget.color);
          _widths.add(widget.strokeWidth);
        });
      },
      onPanUpdate: (details) {
        setState(() {
          _currentStroke.add(details.localPosition);
        });
      },
      onPanEnd: (_) {
        widget.onDraw?.call();
      },
      child: CustomPaint(
        painter: _DrawingPainter(_strokes, _colors, _widths),
        size: Size.infinite,
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Color> colors;
  final List<double> widths;

  _DrawingPainter(this.strokes, this.colors, this.widths);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      if (stroke.isEmpty) continue;

      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = widths[i]
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
      for (int j = 1; j < stroke.length; j++) {
        path.lineTo(stroke[j].dx, stroke[j].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
