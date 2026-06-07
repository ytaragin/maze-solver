import 'package:flutter/material.dart';
import 'package:maze/maze.dart';

/// Editable grid canvas where the user places tiles to build a maze.
/// Left-click places the selected tile, right-click clears a cell.
class CreationGrid extends StatelessWidget {
  final MazeArray mazeArray;
  final int? selectedTileId;
  final ValueChanged<({int row, int col})> onCellTap;
  final ValueChanged<({int row, int col})> onCellClear;
  final double tileSize;

  const CreationGrid({
    super.key,
    required this.mazeArray,
    required this.selectedTileId,
    required this.onCellTap,
    required this.onCellClear,
    this.tileSize = 48.0,
  });

  int get rows => mazeArray.rows;
  int get cols => mazeArray.cols;

  @override
  Widget build(BuildContext context) {
    final gridWidth = cols * tileSize;
    final gridHeight = rows * tileSize;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: GestureDetector(
            onTapUp: (details) => _handleTap(details.localPosition),
            onSecondaryTapUp: (details) => _handleClear(details.localPosition),
            child: CustomPaint(
              size: Size(gridWidth, gridHeight),
              painter: _GridPainter(
                rows: rows,
                cols: cols,
                tileSize: tileSize,
                mazeArray: mazeArray,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(Offset position) {
    final cell = _hitTest(position);
    if (cell != null) {
      onCellTap(cell);
    }
  }

  void _handleClear(Offset position) {
    final cell = _hitTest(position);
    if (cell != null) {
      onCellClear(cell);
    }
  }

  ({int row, int col})? _hitTest(Offset position) {
    final row = (position.dy / tileSize).floor();
    final col = (position.dx / tileSize).floor();
    if (row >= 0 && row < rows && col >= 0 && col < cols) {
      print('Tapped cell: ($row, $col)');
      return (row: row, col: col);
    }
    return null;
  }
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final double tileSize;
  final MazeArray mazeArray;

  _GridPainter({
    required this.rows,
    required this.cols,
    required this.tileSize,
    required this.mazeArray,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = Colors.grey.shade100
      ..style = PaintingStyle.fill;

    final occupiedPaint = Paint()
      ..color = Colors.blue.shade50
      ..style = PaintingStyle.fill;

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final rect = Rect.fromLTWH(
          col * tileSize,
          row * tileSize,
          tileSize,
          tileSize,
        );

        final tile = mazeArray.getTile(row, col);
        final isEmpty = tile.id == 0;
        canvas.drawRect(rect, isEmpty ? fillPaint : occupiedPaint);
        canvas.drawRect(rect, borderPaint);

        // Show tile ID text if occupied
        if (!isEmpty) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: '${tile.id}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: tileSize * 0.3,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          textPainter.paint(
            canvas,
            Offset(
              col * tileSize + (tileSize - textPainter.width) / 2,
              row * tileSize + (tileSize - textPainter.height) / 2,
            ),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => true;
}
