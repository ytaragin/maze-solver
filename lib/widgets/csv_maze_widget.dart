import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:maze/maze.dart';
import '../models/maze.dart';

/// CSV-based Maze Widget that displays tiles
class CsvMazeWidget extends StatefulWidget {
  final Maze maze;
  final double tileSize;

  const CsvMazeWidget({super.key, required this.maze, this.tileSize = 32.0});

  @override
  State<CsvMazeWidget> createState() => _CsvMazeWidgetState();
}

class _CsvMazeWidgetState extends State<CsvMazeWidget> {
  Map<int, ui.Image> _tileImages = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTileImages();
  }

  Future<void> _loadTileImages() async {
    try {
      // Find all unique tile IDs
      final uniqueTiles = widget.maze.getUniqueTiles();

      // Load all required tile images
      for (Tile tile in uniqueTiles) {
        final image = await _loadImage('tiles/Variant${tile.id}.png');
        _tileImages[tile.id] = image;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading tile images: $e';
      });
    }
  }

  Future<ui.Image> _loadImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    final rows = widget.maze.rows;
    final cols = widget.maze.cols;

    return CustomPaint(
      size: Size(cols * widget.tileSize, rows * widget.tileSize),
      painter: CsvMazePainter(
        maze: widget.maze,
        tileImages: _tileImages,
        tileSize: widget.tileSize,
      ),
    );
  }
}

class CsvMazePainter extends CustomPainter {
  final Maze maze;
  final Map<int, ui.Image> tileImages;
  final double tileSize;

  CsvMazePainter({
    required this.maze,
    required this.tileImages,
    required this.tileSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int row = 0; row < maze.rows; row++) {
      for (int col = 0; col < maze.cols; col++) {
        final tile = maze.getTile(row, col);
        final image = tileImages[tile.id];

        if (image != null) {
          final srcRect = Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          );
          final dstRect = Rect.fromLTWH(
            col * tileSize,
            row * tileSize,
            tileSize,
            tileSize,
          );
          canvas.drawImageRect(image, srcRect, dstRect, Paint());
        }
      }
    }
  }

  @override
  bool shouldRepaint(CsvMazePainter oldDelegate) {
    return oldDelegate.maze != maze ||
        oldDelegate.tileImages != tileImages ||
        oldDelegate.tileSize != tileSize;
  }
}
