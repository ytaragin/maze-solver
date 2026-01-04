import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:maze/maze.dart';
import '../models/maze.dart';
import '../utils/maze_coordinates.dart';

/// CSV-based Maze Widget that displays tiles
class CsvMaze extends StatefulWidget {
  final Maze maze;
  final MazeCoordinates coordinates;

  const CsvMaze({
    super.key, 
    required this.maze, 
    required this.coordinates,
  });

  @override
  State<CsvMaze> createState() => _CsvMazeState();
}

class _CsvMazeState extends State<CsvMaze> {
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
      size: widget.coordinates.getMazeSize(rows, cols),
      painter: CsvMazePainter(
        maze: widget.maze,
        tileImages: _tileImages,
        coordinates: widget.coordinates,
      ),
    );
  }
}

class CsvMazePainter extends CustomPainter {
  final Maze maze;
  final Map<int, ui.Image> tileImages;
  final MazeCoordinates coordinates;

  CsvMazePainter({
    required this.maze,
    required this.tileImages,
    required this.coordinates,
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
          final location = MazeLocation(row: row, col: col);
          final topLeft = coordinates.locationToTopLeft(location);
          final dstRect = Rect.fromLTWH(
            topLeft.dx,
            topLeft.dy,
            coordinates.tileSize,
            coordinates.tileSize,
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
        oldDelegate.coordinates != coordinates;
  }
}
