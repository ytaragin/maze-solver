# Maze

A pure Dart library for loading and managing tile-based mazes from CSV files.

## Features

- Load mazes from CSV files
- Tile-based maze representation
- Support for different spot types (path, wall, start, end, bridges, tunnels)
- Directional tile system

## Usage

```dart
import 'package:maze/maze.dart';

void main() async {
  // Load a maze from a CSV file
  final maze = await MazeArray.fromCsv('path/to/maze.csv');
  
  // Access maze properties
  print('Maze size: ${maze.rows} x ${maze.cols}');
  
  // Get a specific tile
  final tile = maze.getTile(0, 0);
  print('Tile at (0,0): $tile');
}
```

## CLI Tool

Run the included command-line tool:

```bash
dart run maze:maze_tool path/to/maze.csv
```
