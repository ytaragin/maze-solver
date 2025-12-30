# Maze Tool Project

This project has been restructured into three main components:

## 1. Maze Library (`packages/maze/`)

A pure Dart library for loading and managing tile-based mazes from CSV files. This library has **no Flutter dependencies** and can be used in:
- Standalone Dart applications
- Command-line tools
- Flutter applications (with the Flutter extension)

### Using the Maze Library

#### In a Dart CLI Application:

```dart
import 'package:maze/maze.dart';
import 'package:maze/maze_io.dart';  // For file I/O

void main() async {
  final maze = await MazeArrayIO.fromCsv('path/to/maze.csv');
  print('Loaded maze: ${maze.rows}x${maze.cols}');
}
```

#### In a Flutter Application:

```dart
import 'package:maze/maze.dart';
import 'package:maze/maze_flutter.dart';  // For Flutter assets

Future<void> loadMaze() async {
  final maze = await MazeArrayFlutter.fromAsset('mazes/maze.csv');
  print('Loaded maze: ${maze.rows}x${maze.cols}');
}
```

### Library Features:
- Load mazes from CSV files (with platform-specific extensions)
- Tile-based maze representation with types and directions
- Support for various spot types: path, wall, start, end, bridges, tunnels
- Directional tile system (north, south, east, west)

## 2. Command-Line Tool (`packages/maze/bin/`)

A standalone Dart application for testing and developing the maze library.

### Running the CLI Tool:

```bash
# From the maze package directory
cd packages/maze
dart run maze:maze_tool ../../mazes/maze251103v2.csv

# Or from the project root
dart run --directory=packages/maze maze:maze_tool mazes/maze251103v2.csv
```

The CLI tool displays:
- Maze dimensions (rows x cols)
- Tile distribution statistics
- Preview of the maze structure

## 3. Flutter Visualization App (root directory)

The main Flutter application that uses the maze library for maze logic and provides visualization.

### Running the Flutter App:

```bash
# From the project root
flutter run
```

The Flutter app:
- Uses the local `maze` package for maze data management
- Provides visual rendering of mazes using tile images
- Supports interactive maze display

## Project Structure

```
maze_tool/
├── packages/
│   └── maze/                    # Pure Dart maze library
│       ├── lib/
│       │   ├── maze.dart        # Main library export
│       │   ├── maze_io.dart     # Dart I/O extension (for CLI)
│       │   ├── maze_flutter.dart # Flutter extension (for assets)
│       │   └── src/
│       │       ├── maze_array.dart
│       │       ├── tiles.dart
│       │       └── spot_type.dart
│       ├── bin/
│       │   └── maze_tool.dart   # CLI application
│       ├── test/
│       │   └── maze_test.dart
│       ├── pubspec.yaml
│       └── README.md
├── lib/                         # Flutter app source
│   ├── main.dart
│   └── maze_widget.dart
├── mazes/                       # Maze CSV files
├── tiles/                       # Tile image assets
├── pubspec.yaml                 # Flutter app dependencies
└── README.md                    # This file
```

## Development Workflow

### Working on the Maze Library:

1. Make changes to files in `packages/maze/lib/`
2. Run tests: `cd packages/maze && dart test`
3. Test with CLI: `dart run maze:maze_tool ../../mazes/maze251103v2.csv`
4. The Flutter app will automatically use the updated library (local path dependency)

### Working on the Flutter App:

1. Make changes to files in `lib/`
2. Run the app: `flutter run`
3. The app uses the local maze package, so library changes are immediately available

## Key Design Decisions

1. **Separation of Concerns**: The maze logic is completely independent of Flutter, making it reusable and testable.

2. **Platform Extensions**: Instead of having platform-specific code in the core library:
   - `maze_io.dart` provides `MazeArrayIO.fromCsv()` for file-based loading (Dart CLI)
   - `maze_flutter.dart` provides `MazeArrayFlutter.fromAsset()` for asset loading (Flutter)
   - Core `MazeArray.fromCsvString()` works everywhere

3. **Local Package**: The maze library is a local package (not published), making it easy to develop both the library and the Flutter app together.

## Optional: Old Maze Files

The old maze files in `lib/maze/` can now be safely deleted as they've been moved to `packages/maze/lib/src/`:
- `lib/maze/maze.dart` → `packages/maze/lib/maze.dart`
- `lib/maze/maze_array.dart` → `packages/maze/lib/src/maze_array.dart` (updated)
- `lib/maze/tiles.dart` → `packages/maze/lib/src/tiles.dart`
- `lib/maze/spot_type.dart` → `packages/maze/lib/src/spot_type.dart`

## Testing

### Test the Maze Library:
```bash
cd packages/maze
dart test
```

### Test the CLI Tool:
```bash
cd packages/maze
dart run maze:maze_tool ../../mazes/maze251103v2.csv
```

### Test the Flutter App:
```bash
flutter run
```
