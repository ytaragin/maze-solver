import 'package:flutter/material.dart';
import 'package:maze/maze.dart';

/// Utility class for converting between screen coordinates and maze locations
class MazeCoordinates {
  final double tileSize;

  const MazeCoordinates({required this.tileSize});

  /// Convert screen position to maze location
  MazeLocation screenToLocation(Offset screenPosition) {
    final row = (screenPosition.dy / tileSize).floor();
    final col = (screenPosition.dx / tileSize).floor();
    return MazeLocation(row: row, col: col);
  }

  /// Convert maze location to the center point of the tile on screen
  Offset locationToCenter(MazeLocation location) {
    return Offset(
      location.col * tileSize + tileSize / 2,
      location.row * tileSize + tileSize / 2,
    );
  }

  /// Convert maze location to the top-left corner of the tile on screen
  Offset locationToTopLeft(MazeLocation location) {
    return Offset(
      location.col * tileSize,
      location.row * tileSize,
    );
  }

  /// Get the size of the entire maze in pixels
  Size getMazeSize(int rows, int cols) {
    return Size(cols * tileSize, rows * tileSize);
  }

  /// Check if a screen position is within the maze bounds
  bool isPositionInBounds(Offset position, int rows, int cols) {
    final location = screenToLocation(position);
    return location.row >= 0 &&
        location.row < rows &&
        location.col >= 0 &&
        location.col < cols;
  }
}
