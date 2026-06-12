import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:maze/maze.dart';
import 'package:provider/provider.dart';
import '../models/maze.dart';
import '../services/tile_image_cache.dart';
import '../utils/maze_coordinates.dart';

/// CSV-based Maze Widget that displays tiles
class CsvMaze extends StatelessWidget {
  final Maze maze;
  final MazeCoordinates coordinates;

  const CsvMaze({
    super.key,
    required this.maze,
    required this.coordinates,
  });

  @override
  Widget build(BuildContext context) {
    final cache = context.watch<TileImageCache>();

    if (!cache.isReady) {
      return const Center(child: CircularProgressIndicator());
    }

    final rows = maze.rows;
    final cols = maze.cols;

    return CustomPaint(
      size: coordinates.getMazeSize(rows, cols),
      painter: CsvMazePainter(
        maze: maze,
        tileImageFor: cache.imageFor,
        coordinates: coordinates,
      ),
    );
  }
}

class CsvMazePainter extends CustomPainter {
  final Maze maze;
  final ui.Image? Function(int) tileImageFor;
  final MazeCoordinates coordinates;

  CsvMazePainter({
    required this.maze,
    required this.tileImageFor,
    required this.coordinates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int row = 0; row < maze.rows; row++) {
      for (int col = 0; col < maze.cols; col++) {
        final tile = maze.getTile(row, col);
        final image = tileImageFor(tile.id);

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
        oldDelegate.coordinates != coordinates ||
        oldDelegate.tileImageFor != tileImageFor;
  }
}
