import 'dart:math';

import 'package:image/image.dart' as img;
import 'package:maze/maze.dart';

/// A tile location with row and column coordinates.
typedef TileLocation = ({int row, int col});
typedef Step = ({TileLocation startTile, TileLocation endTile, int stepIndex});

/// Draws a solution path on top of a maze image.
class SolutionPathDraw {
  final img.Image image;
  final int tileSize;
  final img.Color pathColor;
  final TileManager tileManager;
  final MazeArray mazeArray;

  /// Creates a solution path drawer.
  /// 
  /// [image] - The image to draw the path on
  /// [tileSize] - The size of each tile in pixels
  /// [pathColor] - The color to use for drawing the path
  /// [tileManager] - The tile manager for the maze
  /// [mazeArray] - The maze array structure
  SolutionPathDraw({
    required this.image,
    required this.tileSize,
    required this.pathColor,
    required this.tileManager,
    required this.mazeArray,
  });

  /// Draws a solution path on the image given a list of positions.
  /// 
  /// [path] - List of tile locations representing the solution path
  void drawPath(List<TileLocation> path) {
    if (path.isEmpty) return;

    // Convert path to list of steps using collection-if and pattern matching
    final steps = [
      for (var i = 0; i < path.length - 1; i++)
          (
            startTile: path[i],
            endTile: path[i + 1],
            stepIndex: i,
          )
    ];

    // Draw each step in the path, tracking the endpoint of each step
    (TileLocation, int)? previousEndpoint;
    for (var step in steps) {
      previousEndpoint = drawPathStep(step, previousEndpoint: previousEndpoint);
    }
  }

  /// Gets the exact pixel coordinates for a tile at the given location.
  /// 
  /// Returns a tuple of (x, y) representing the top-left corner of the tile,
  /// and (centerX, centerY) representing the center of the tile.
  /// 
  /// [location] - The tile location
  ({int x, int y, int centerX, int centerY}) getTileCoordinates(TileLocation location) {
    final x = location.col * tileSize;
    final y = location.row * tileSize;
    final centerX = x + tileSize ~/ 2;
    final centerY = y + tileSize ~/ 2;
    
    return (x: x, y: y, centerX: centerX, centerY: centerY);
  }

  /// Gets 9 equally spaced points within a tile arranged in a 3x3 grid.
  /// 
  /// Points are numbered 0-8 from left to right, top to bottom:
  /// ```
  /// 0  1  2
  /// 3  4  5
  /// 6  7  8
  /// ```
  /// 
  /// [location] - The tile location
  /// 
  /// Returns a map from point number (0-8) to (x, y) coordinates.
  Map<int, (int, int)> getTileGridPoints(TileLocation location) {
    final coords = getTileCoordinates(location);
    final points = <int, (int, int)>{};
    
    // Create a 3x3 grid with points closer to the center
    // Use a spacing factor to bring outer points closer to the middle
    final spacingX = tileSize ~/ 5;  // Smaller spacing brings points closer
    final spacingY = tileSize ~/ 5;
    
    var pointIndex = 0;
    for (var gridRow = 0; gridRow < 3; gridRow++) {
      for (var gridCol = 0; gridCol < 3; gridCol++) {
        final x = coords.centerX + ((gridCol - 1) * spacingX);
        final y = coords.centerY + ((gridRow - 1) * spacingY);
        points[pointIndex] = (x, y);
        pointIndex++;
      }
    }
    
    return points;
  }

  // /// Draws a line between two tile locations.
  // /// 
  // /// Connects the centers of the two tiles with a line.
  // /// 
  // /// [loc1] - The first tile location
  // /// [loc2] - The second tile location
  // void drawLineBetweenTiles(TileLocation loc1, TileLocation loc2) {
  //   final coords1 = getTileCoordinates(loc1);
  //   final coords2 = getTileCoordinates(loc2);
    
  //   img.drawLine(image, x1: coords1.centerX, y1: coords1.centerY, 
  //                x2: coords2.centerX, y2: coords2.centerY, color: pathColor, thickness: 3);
  // }

  /// Draws a line between specific points in two tiles.
  /// 
  /// [tile1] - The first tile location
  /// [point1] - The point number (0-8) in the first tile's 3x3 grid
  /// [tile2] - The second tile location
  /// [point2] - The point number (0-8) in the second tile's 3x3 grid
  /// [drawArrow] - If true, draws an arrow shape in the middle of the line
  void drawLineBetweenPoints(TileLocation tile1, int point1, TileLocation tile2, int point2, {bool drawArrow = false}) {
    // Get the grid points for both tiles
    final points1 = getTileGridPoints(tile1);
    final points2 = getTileGridPoints(tile2);
    
    // Get coordinates of the specified points
    final (x1, y1) = points1[point1]!;
    final (x2, y2) = points2[point2]!;
    
    // Draw the line using the image package's built-in function
    img.drawLine(image, x1: x1, y1: y1, x2: x2, y2: y2, color: pathColor, thickness: 3);
    
    // Draw arrow if requested
    if (drawArrow) {
      // Calculate midpoint
      final midX = (x1 + x2) ~/ 2;
      final midY = (y1 + y2) ~/ 2;
      
      // Calculate direction vector
      final dx = x2 - x1;
      final dy = y2 - y1;
      final length = sqrt(dx * dx + dy * dy);
      
      if (length > 0) {
        // Normalized direction vector
        final ndx = dx / length;
        final ndy = dy / length;
        
        // Arrow dimensions
        final size = 5.0;
        
        // Triangle points relative to midpoint
        // Tip points forward in the direction of travel
        final tipX = (midX + ndx * size).round();
        final tipY = (midY + ndy * size).round();
        
        // Base points perpendicular to direction
        final base1X = (midX - ndx * size - ndy * size).round();
        final base1Y = (midY - ndy * size + ndx * size).round();
        final base2X = (midX - ndx * size + ndy * size).round();
        final base2Y = (midY - ndy * size - ndx * size).round();
        
        // Draw filled triangle
        img.fillPolygon(image, 
          vertices: [
            img.Point(tipX, tipY),
            img.Point(base1X, base1Y),
            img.Point(base2X, base2Y),
          ],
          color: pathColor);
      }
    }
  }

  /// Gets the direction from one tile location to another.
  /// 
  /// Returns null if the tiles are not adjacent (more than 1 tile apart
  /// or diagonal), or if they are the same tile.
  /// 
  /// [loc1] - The first tile location
  /// [loc2] - The second tile location
  Direction? getDirectionBetweenTiles(TileLocation loc1, TileLocation loc2) {
    final rowDiff = loc2.row - loc1.row;
    final colDiff = loc2.col - loc1.col;
    
    // Check if tiles are adjacent (not diagonal and only 1 step apart)
    if (rowDiff == 0 && colDiff == 1) {
      return Direction.east;
    } else if (rowDiff == 0 && colDiff == -1) {
      return Direction.west;
    } else if (rowDiff == 1 && colDiff == 0) {
      return Direction.south;
    } else if (rowDiff == -1 && colDiff == 0) {
      return Direction.north;
    }
    
    // Not adjacent or same tile
    return null;
  }

  /// Gets the start and end point numbers for a given direction.
  /// 
  /// Points are numbered 0-8 in a 3x3 grid:
  /// ```
  /// 0  1  2
  /// 3  4  5
  /// 6  7  8
  /// ```
  /// 
  /// Returns a tuple of (startPoint, endPoint) representing the entry
  /// and exit points for movement in the given direction.
  /// 
  /// [direction] - The direction of movement
  (int, int) getPointsForDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return (2, 8); 
      case Direction.south:
        return (6, 0); 
      case Direction.east:
        return (8, 6); 
      case Direction.west:
        return (0, 2); 
    }
  }

  /// Draws a path segment between two adjacent tiles.
  /// 
  /// Uses the direction from the step to determine appropriate entry/exit points
  /// in the 3x3 grid of each tile, then draws a line connecting them.
  /// 
  /// [step] - The step containing start tile, end tile, and direction
  /// [previousEndpoint] - The endpoint (tile and point) from the previous step, if any
  /// 
  /// Returns the exit tile location and point number as (tile, point), or null
  /// if the tiles are not adjacent.
  (TileLocation, int)? drawPathStep(Step step, {(TileLocation, int)? previousEndpoint}) {
    final direction = getDirectionBetweenTiles(step.startTile, step.endTile);
    if (direction == null) {
      // Tiles are not adjacent; cannot draw path step
      print(  'Warning: Cannot draw path step between non-adjacent tiles at '
          '(${step.startTile.row},${step.startTile.col}) and '
          '(${step.endTile.row},${step.endTile.col})');
      return null;
    }
    // Get the exit and entry points for this direction
    final (exitPoint, entryPoint) = getPointsForDirection(direction);

    if (previousEndpoint != null) {
      final (prevTile, prevPoint) = previousEndpoint;
      // Draw line from previous endpoint to current start tile's entry point
      drawLineBetweenPoints(prevTile, prevPoint, step.startTile, exitPoint);
    }
    
    // Draw the line between the appropriate points
    drawLineBetweenPoints(step.startTile, exitPoint, step.endTile, entryPoint, drawArrow: true);
    
    return (step.endTile, entryPoint);
  }
}
