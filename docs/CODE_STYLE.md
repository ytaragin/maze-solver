# Code Style Guidelines

This document contains the Dart/Flutter code style conventions for the maze_tool project.

## Naming Conventions

**Classes**: PascalCase
```dart
class MazeArray { }
class InteractiveMaze extends StatefulWidget { }
class TileRenderer { }
```

**Files**: snake_case matching primary class name
```dart
maze_array.dart    // Contains MazeArray class
tile_renderer.dart // Contains TileRenderer class
```

**Variables/Methods**: camelCase
```dart
final int tileSize = 64;
List<MazeNode> getAllowedNeighbors() { }
```

**Private members**: Prefix with underscore
```dart
final Map<int, Tile> _tiles = {};
void _buildGraph() { }
```

**Constants**: SCREAMING_SNAKE_CASE for static const
```dart
static const int TUNNEL_EW_ID = 42;
```

**Enums**: PascalCase type, camelCase values
```dart
enum SpotType { path, wall, start, end, coin }
enum Direction { north, south, east, west }
```

## Import Organization

Order imports as follows:
```dart
// 1. Dart core libraries
import 'dart:io';
import 'dart:ui' as ui;

// 2. Flutter libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Third-party packages
import 'package:csv/csv.dart';
import 'package:image/image.dart' as img;

// 4. Local package imports
import 'package:maze/maze.dart';
import 'package:maze_image/maze_image.dart';

// 5. Relative imports (within same package)
import '../models/maze.dart';
import 'src/maze_array.dart';
```

## Type System

**Null Safety**: Enabled and enforced
```dart
// Non-nullable by default
final int rows;
final List<Tile> tiles;

// Nullable when needed
MazeLocation? getNodesByType(SpotType type) { }
MazePath? moveToLocation(MazeLocation location) { }

// Late initialization for complex setup
late final MazeNode startNode;
late final MazeGraph graph;
```

**Type Inference**: Use when obvious
```dart
final tiles = csvData.map((row) => parseRow(row)).toList();  // Good
final List<List<Tile>> tiles = ...;  // Use when clarity needed
```

## Formatting Preferences

**Const**: Use const constructors wherever possible
```dart
const Tile(id: 1, type: SpotType.path, directions: {});
const SizedBox(height: 16);
```

**Final**: Prefer final for immutable variables
```dart
final String csvPath;
final int tileSize = 64;
```

**Quote Style**: No strict preference (mixed in codebase)
- Single quotes common in packages/maze_image
- Double quotes common in main app
- Be consistent within each file

## Error Handling Patterns

**Exception Wrapping**: Provide context
```dart
static MazeArray fromCsvString(String csvString) {
  try {
    // ... parsing logic
    return MazeArray(tiles: tiles);
  } catch (e) {
    throw Exception('Failed to load maze from CSV string: $e');
  }
}
```

**Nullable Returns**: For expected "not found" cases
```dart
MazeLocation? getNodesByType(SpotType type) {
  // ... search logic
  return null; // Not an error, just not found
}
```

**Range Checking**: Validate inputs early
```dart
Tile getTile(int row, int col) {
  if (row < 0 || row >= rows || col < 0 || col >= cols) {
    throw RangeError('Position ($row, $col) is out of bounds');
  }
  return tiles[row][col];
}
```

**Async Error Handling**: Use try-catch with setState
```dart
Future<void> _loadMaze() async {
  try {
    _maze = await Maze.fromAsset(widget.csvPath);
    setState(() {
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Error loading maze: $e';
    });
  }
}
```

## Immutability Patterns

**Data Classes**: Prefer immutable structures
```dart
class MazeArray {
  final List<List<Tile>> tiles;
  const MazeArray({required this.tiles});
}

class Tile {
  final int id;
  final SpotType type;
  final Set<Direction> directions;
  const Tile({required this.id, required this.type, required this.directions});
}
```

**State Updates**: Return new instances
```dart
PathState next({required int coinsDelta, required MazeNode newNode}) {
  return PathState(
    node: newNode,
    coinsCollected: coinsCollected + coinsDelta,
    visitedEdges: {...visitedEdges, newEdge},  // Spread operator
    path: [...path, newNode],                   // Spread operator
  );
}
```

## Common Design Patterns

**Factory Constructors**: For complex initialization
```dart
factory Tile.variant(int variantNumber, SpotType type, Set<Direction> directions) {
  return Tile(id: variantNumber, type: type, directions: directions);
}

factory MazePath.fromMaze(Maze maze) {
  final graph = maze.graph;
  final pathState = PathState(node: graph.startNode, allowLoops: true);
  return MazePath._(graph: graph, pathState: pathState);
}
```

**Barrel Files**: Export public API
```dart
// lib/maze.dart
library;

export 'src/maze_array.dart';
export 'src/tiles.dart';
export 'src/maze_graph.dart';
```

**Platform Extensions**: Separate platform-specific code
```dart
// maze_io.dart (for dart:io)
extension MazeArrayIO on MazeArray {
  static Future<MazeArray> fromCsv(String csvPath) async { }
}

// maze_flutter.dart (for Flutter assets)
extension MazeArrayFlutter on MazeArray {
  static Future<MazeArray> fromAsset(String assetPath) async { }
}
```

**Caching**: Use maps for expensive operations
```dart
class TileRenderer {
  final Map<int, img.Image> _imageCache = {};
  
  img.Image? getTileImage(int tileId) {
    if (_imageCache.containsKey(tileId)) {
      return _imageCache[tileId];
    }
    // Load and cache
  }
}
```

## Documentation

**Doc Comments**: Use /// for public APIs
```dart
/// Represents a 2D array of tiles loaded from a CSV file.
/// Each number in the array refers to a tile variant (e.g., 1 -> Variant1.png).
class MazeArray { }

/// Loads a maze from CSV string content.
/// This is the base method that works in both Flutter and standalone Dart.
static MazeArray fromCsvString(String csvString) { }
```

**Implementation Comments**: Use // for clarity
```dart
// First pass: Create all nodes
for (int row = 0; row < rows; row++) { }

// Check cache first
if (_imageCache.containsKey(tileId)) { }
```

## Modern Dart Features (3.x)

**Records**: Use for multiple return values
```dart
final (bool isLegal, int coinsSpent) = _verifyMazeRules(neighbor);
final ({int row, int col}) location = (row: 5, col: 3);
```

**Pattern Matching**: Destructure records
```dart
for (final (neighbor, coinsDelta) in initialNeighbors) {
  // Use both values
}
```

**Collection-if**: Conditional list elements
```dart
[
  for (var i in items)
    if (condition) i
]
```
