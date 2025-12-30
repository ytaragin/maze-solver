import 'package:maze/maze.dart';
import 'package:maze/maze_flutter.dart';

/// Model wrapping MazeArray with additional game logic and state
class Maze {
  final MazeArray mazeArray;
  final String csvPath;

  Maze({
    required this.mazeArray,
    required this.csvPath,
  });

  /// Load maze from asset path
  static Future<Maze> fromAsset(String csvPath) async {
    final mazeArray = await MazeArrayFlutter.fromAsset(csvPath);
    return Maze(
      mazeArray: mazeArray,
      csvPath: csvPath,
    );
  }

  /// Get maze dimensions
  int get rows => mazeArray.rows;
  int get cols => mazeArray.cols;

  /// Get tile at specific position
  Tile getTile(int row, int col) => mazeArray.getTile(row, col);
  Tile getTileAt(MazeLocation location) => mazeArray.getTile(location.row, location.col);

  /// Get all unique tiles in the maze
  Set<Tile> getUniqueTiles() => mazeArray.getUniqueTiles();

  /// Find start and end positions
  MazeLocation get startLocation => mazeArray.getStartLocation();
  MazeLocation? get endLocation => mazeArray.getNodesByType(SpotType.end);

  /// Check if a position is valid (within bounds)
  bool isValidLocation(MazeLocation location) {
    return location.row >= 0 &&
        location.row < rows &&
        location.col >= 0 &&
        location.col < cols;
  }

  /// Check if a tile is walkable (not a wall)
  bool isWalkable(MazeLocation location) {
    if (!isValidLocation(location)) return false;
    final tile = getTileAt(location);
    // TODO: Define walkable logic based on tile type
    // For now, assume all non-wall tiles are walkable
    return tile.type != SpotType.wall;
  }

  /// Get neighboring positions
  List<MazeLocation> getNeighbors(MazeLocation location) {
    final neighbors = <MazeLocation>[];
    final directions = [
      MazeLocation(row: location.row - 1, col: location.col), // North
      MazeLocation(row: location.row + 1, col: location.col), // South
      MazeLocation(row: location.row, col: location.col - 1), // West
      MazeLocation(row: location.row, col: location.col + 1), // East
    ];

    for (final neighbor in directions) {
      if (isValidLocation(neighbor)) {
        neighbors.add(neighbor);
      }
    }

    return neighbors;
  }

  /// Check if two locations are adjacent (including diagonals)
  bool areAdjacent(MazeLocation a, MazeLocation b) {
    final rowDiff = (a.row - b.row).abs();
    final colDiff = (a.col - b.col).abs();
    return (rowDiff <= 1 && colDiff <= 1) && (rowDiff + colDiff > 0);
  }

  /// Check if two locations are orthogonally adjacent (no diagonals)
  bool areOrthogonallyAdjacent(MazeLocation a, MazeLocation b) {
    final rowDiff = (a.row - b.row).abs();
    final colDiff = (a.col - b.col).abs();
    return (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);
  }

  /// Validate a path through the maze
  bool isValidPath(List<MazeLocation> path) {
    if (path.isEmpty) return false;

    // Check if path starts at start position
    final start = startLocation;
    if (path.first != start) {
      return false;
    }

    // Check each step is adjacent and walkable
    for (int i = 0; i < path.length; i++) {
      if (!isWalkable(path[i])) {
        return false;
      }

      if (i > 0 && !areOrthogonallyAdjacent(path[i - 1], path[i])) {
        return false;
      }
    }

    return true;
  }

  /// Check if path reaches the end
  bool isPathComplete(List<MazeLocation> path) {
    if (path.isEmpty) return false;
    final end = endLocation;
    return end != null && path.last == end;
  }

  @override
  String toString() => 'Maze($rows x $cols, path: $csvPath)';
}
