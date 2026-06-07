# AGENTS.md - Development Guide for Coding Agents

This guide provides essential information for AI coding agents working in this Flutter-based maze solver application.

## Project Overview

**Type**: Flutter multi-platform application (Web, Desktop, Mobile)
**Language**: Dart 3.10.1+ with sound null safety
**Architecture**: Three-layer package structure with clean separation of concerns

### Package Structure
```
maze_tool/              # Main Flutter app (UI layer)
├── packages/maze/      # Pure Dart maze library (core logic)
└── packages/maze_image/ # Image rendering library (PNG generation)
```

## Build, Test, and Lint Commands

### Running the Application
```bash
# Flutter app
flutter run                    # Default device
flutter run -d chrome          # Web browser
flutter run -d linux           # Linux desktop
flutter run -d windows         # Windows desktop
flutter run -d web-server      # web server 

# CLI tool
dart run bin/maze_tool.dart <maze.csv>
dart run bin/maze_tool.dart --help
```

### Building for Production
```bash
flutter build web
flutter build web --base-href /maze/
flutter build linux
flutter build windows
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run single test by name
dart test --name "creates tile with variant factory"

# Run tests in a group
dart test --name "Tile"

# Test individual packages
cd packages/maze && dart test
cd packages/maze_image && dart test

# Run with coverage
flutter test --coverage
```

### Linting and Formatting
```bash
# Analyze entire project
flutter analyze

# Format all Dart files
dart format .

# Check formatting (CI-friendly)
dart format --set-exit-if-changed .
```

### Package Management
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Code Style Guidelines

See [docs/CODE_STYLE.md](docs/CODE_STYLE.md) for the full code style guide covering naming conventions, import organization, type system, formatting, error handling, immutability patterns, design patterns, and modern Dart features.

## Design Documentation

Detailed design docs live in `docs/`. Read these before modifying the relevant subsystems:

| Document | Covers |
|----------|--------|
| [docs/MAZE_GRAPH.md](docs/MAZE_GRAPH.md) | CSV parsing, MazeArray, MazeGraph construction, multi-level bridge/tunnel nodes |
| [docs/TILE_SYSTEM.md](docs/TILE_SYSTEM.md) | Tile variants, ID scheme, SpotType enum, adding new tile types |
| [docs/RENDERING_PIPELINE.md](docs/RENDERING_PIPELINE.md) | MazeCoordinates, Flutter widget stack, CLI PNG generation |
| [docs/BFS_SOLVER.md](docs/BFS_SOLVER.md) | BFS algorithm, constraint system (coins, bridges), SolutionLayer |
| [docs/PATH_AND_HISTORY.md](docs/PATH_AND_HISTORY.md) | User path tracking, undo/history stack, immutability contract |
| [docs/WIDGET_ARCHITECTURE.md](docs/WIDGET_ARCHITECTURE.md) | Widget tree, GlobalKey pattern, callbacks, state management |
| [docs/CODE_STYLE.md](docs/CODE_STYLE.md) | Naming, imports, formatting, error handling, design patterns |

## Project-Specific Conventions

### File Organization
- Implementation details go in `src/` directories
- Public API exposed through barrel files in `lib/`
- Tests mirror source structure in `test/` directories

### Widget State Management
- Use `StatefulWidget` for interactive UI
- Use `GlobalKey` for parent-child state access
- Prefer immutable data models with functional updates

### Graph Operations
- Mazes are represented as graphs with `MazeNode` and `MazeGraph`
- Pathfinding uses BFS in `packages/maze/src/maze_bfs.dart`
- Multi-level tiles (bridges/tunnels) create multiple nodes per location

### Asset Management
- Maze CSVs in `mazes/` directory
- Tile images in `tiles/` directory (Variant1.png, Variant2.png, etc.)
- Both registered in `pubspec.yaml` under `flutter.assets`

## Common Tasks

### Adding a New Tile Type
1. Add PNG to `tiles/` directory with next variant number
2. Register in `TileManager.withVariants()` factory
3. Update `SpotType` enum if new semantic type
4. Add direction logic if tile has special connectivity

### Modifying Pathfinding
1. Edit `packages/maze/src/maze_bfs.dart`
2. Run tests: `cd packages/maze && dart test`
3. Test with various maze CSVs in `mazes/` directory

### Adding Platform-Specific Features
1. Create extension in appropriate file (`maze_io.dart` vs `maze_flutter.dart`)
2. Import platform-specific library in extension file only
3. Keep core logic in base classes platform-agnostic

---

**Last Updated**: 2026-05-25
**Dart SDK**: ^3.10.1
**Flutter**: Latest stable
