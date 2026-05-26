# Rendering Pipeline

This document describes how the maze is rendered both in the Flutter app (interactive) and via the CLI tool (static PNG).

## Coordinate System

**File:** `lib/utils/maze_coordinates.dart`

`MazeCoordinates` is a stateless utility that converts between screen pixels and maze grid positions. Takes a `tileSize` (double) in its constructor.

| Method | Returns | Description |
|--------|---------|-------------|
| `screenToLocation(Offset)` | `MazeLocation` | Floors `x/tileSize` and `y/tileSize` to get col and row |
| `locationToCenter(MazeLocation)` | `Offset` | `(col*tileSize + tileSize/2, row*tileSize + tileSize/2)` |
| `locationToTopLeft(MazeLocation)` | `Offset` | `(col*tileSize, row*tileSize)` |
| `getMazeSize(rows, cols)` | `Size` | `(cols*tileSize, rows*tileSize)` |
| `isPositionInBounds(Offset, rows, cols)` | `bool` | Bounds check |

## Flutter App — Widget Stack

**Orchestrator:** `lib/widgets/interactive_maze_widget.dart`

Creates a `MazeCoordinates` instance (default `tileSize: 32.0`) and layers three widgets in a `Stack`:

```
Stack
├── CsvMaze           (bottom — tile images)
├── SolutionLayer     (middle — BFS solution in green, IgnorePointer)
└── PathOverlay       (top — user path in blue, handles input)
```

### Layer 1: CsvMaze (tile images)

**File:** `lib/widgets/csv_maze_widget.dart`

1. On init, loads unique tile PNGs from `tiles/Variant{id}.png` via `rootBundle` into `Map<int, ui.Image>`
2. Renders via `CustomPaint` with `CsvMazePainter`
3. `CsvMazePainter.paint()`: iterates every `(row, col)`, gets tile image by ID, draws with `canvas.drawImageRect()` scaling to `tileSize x tileSize` at `locationToTopLeft()`

### Layer 2: SolutionLayer (BFS solution)

**File:** `lib/widgets/solution_layer.dart`

- Computes BFS shortest path via `MazeShortestPath`
- Renders partial path up to `_depth` steps using `PathPainter` in green
- Wrapped in `IgnorePointer` so clicks pass through to `PathOverlay`

### Layer 3: PathOverlay (user interaction)

**File:** `lib/widgets/path_overlay_widget.dart`

- Handles tap, hover, arrow keys, backspace
- Converts screen positions to maze locations via `coordinates.screenToLocation()`
- Renders user path via `PathPainter` in blue

### PathPainter (shared)

**File:** `lib/widgets/path_overlay_widget.dart` (line 168)

A `CustomPainter` that draws:
- Lines connecting consecutive path points (using `locationToCenter`)
- Dots at each path point
- Yellow highlight circle on the current (last) point

## CLI Tool — Static PNG Generation

**File:** `bin/maze_tool.dart`

Usage: `dart run bin/maze_tool.dart -s -r mazes/maze1.csv`

### Process

1. Parses args (`--render`, `--tiles`, `--tile-size`, `--solution`, `--solve`, `--output`)
2. Creates `TileRenderer(tilesFolder, tileSize)` and calls `preloadAllTiles()`
3. Creates `MazeRenderer(maze, tileManager, tileRenderer, solutionFile: ...)`
4. Calls `mazeRenderer.renderToPng()` → writes bytes to output file

### packages/maze_image

**Barrel:** `packages/maze_image/lib/maze_image.dart`

#### TileRenderer (`packages/maze_image/lib/src/tile_renderer.dart`)

- Uses `dart:io` + `package:image` for headless image processing
- `getTileImage(tileId)`: loads `<tilesFolder>/Variant{id}.png`, decodes with `img.decodePng`, caches
- `renderTile(target, tileId, x, y)`: composites tile image onto target canvas
- `preloadAllTiles()`: scans folder with regex `Variant(\d+)\.png`, loads all matches

#### MazeRenderer (`packages/maze_image/lib/src/maze_renderer.dart`)

- `renderToPng()`: creates `img.Image(width, height)`, fills white background, iterates all tiles calling `tileRenderer.renderTile()`, optionally overlays solution path, encodes to PNG bytes

#### SolutionPathDraw (`packages/maze_image/lib/src/solution_path_draw.dart`)

- `drawPath(List<TileLocation>)`: draws directional arrows between consecutive path tiles
- Uses a 3x3 grid within each tile to determine entry/exit points based on direction
- Draws lines and arrowhead polygons via `img.drawLine` and `img.fillPolygon`

## Key Differences: Flutter vs CLI Rendering

| Aspect | Flutter (CsvMaze) | CLI (maze_image) |
|--------|-------------------|------------------|
| Image library | `dart:ui` (GPU) | `package:image` (software) |
| Tile loading | `rootBundle` assets | `dart:io` file reads |
| Output | Screen canvas | PNG bytes on disk |
| Solution overlay | `PathPainter` (lines + dots) | `SolutionPathDraw` (lines + arrows) |
| Interactivity | Yes (tap, keyboard) | No |
