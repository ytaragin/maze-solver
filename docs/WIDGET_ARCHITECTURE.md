# Widget Architecture

This document describes the Flutter widget tree, state management patterns, and parent-child communication.

## App Entry Point

**File:** `lib/main.dart`

```
main() → MyApp → MaterialApp → MyHomePage → Scaffold
  body: Center > SingleChildScrollView(h) > SingleChildScrollView(v) > Padding
    > InteractiveMaze(csvPath: 'mazes/maze251103v2.csv', tileSize: 40.0)
```

## InteractiveMaze — The Orchestrator

**File:** `lib/widgets/interactive_maze_widget.dart`

### Widget Tree

```
Stack
├── Column
│   ├── Row (control buttons)
│   │   ├── "Clear Path"
│   │   ├── "Advance Solution"
│   │   ├── "Full Solution"
│   │   ├── "Clear Solution"
│   │   └── Text "Steps: X, Coins: Y"
│   └── Stack (maze layers)
│       ├── CsvMaze                         ← tile images
│       ├── SolutionLayer (key: _solutionLayerKey)  ← BFS solution (green)
│       └── PathOverlay (key: _pathOverlayKey)      ← user path (blue)
└── Positioned (version label)
```

### State

| Field | Type | Description |
|-------|------|-------------|
| `_maze` | `Maze?` | Loaded maze model |
| `_isLoading` | `bool` | Loading indicator |
| `_errorMessage` | `String?` | Error display |
| `_pathLength` | `int` | Synced from PathOverlay via callback |
| `_coinsCollected` | `int` | Synced from PathOverlay via callback |

## Parent-Child Communication

### Pattern: GlobalKey for Imperative Control

The parent holds `GlobalKey<ChildState>` references to call methods on child widgets directly:

```dart
final _pathOverlayKey = GlobalKey<PathOverlayState>();
final _solutionLayerKey = GlobalKey<SolutionLayerState>();
```

| Button | Calls |
|--------|-------|
| Clear Path | `_pathOverlayKey.currentState?.clearPath()` |
| Advance Solution | `_solutionLayerKey.currentState?.advanceStep()` |
| Full Solution | `_solutionLayerKey.currentState?.setFullPath()` |
| Clear Solution | `_solutionLayerKey.currentState?.clearSolution()` |

This is Flutter's imperative child-control pattern — the parent doesn't rebuild children via new props; it directly invokes state mutations on the child.

### Pattern: Callback for Child-to-Parent

`PathOverlay` accepts `onPathChanged: ValueChanged<MazePath>` which fires on every state change (move, undo, clear). The parent uses this to sync displayed stats:

```dart
PathOverlay(
  onPathChanged: (mazePath) {
    setState(() {
      _pathLength = mazePath.pathLength;
      _coinsCollected = mazePath.coinsCollected;
    });
  },
)
```

## Widget Responsibilities

### CsvMaze

**File:** `lib/widgets/csv_maze_widget.dart`

- Stateful only for async image loading
- Loads unique tile PNGs from assets into `Map<int, ui.Image>`
- Renders via `CustomPaint` / `CsvMazePainter` — draws each tile image at the correct grid position
- No interactivity

### SolutionLayer

**File:** `lib/widgets/solution_layer.dart`

- Computes BFS solution on init via `MazeShortestPath`
- Renders partial/full solution path in green via `PathPainter`
- Wrapped in `IgnorePointer` — clicks pass through
- Controlled imperatively by parent via GlobalKey

### PathOverlay

**File:** `lib/widgets/path_overlay_widget.dart`

- Owns all user interaction: tap, hover, keyboard (arrows + backspace)
- Manages `MazePath` state and undo history stack
- Renders user path in blue via `PathPainter`
- Exposes `clearPath()` for parent to call
- Fires `onPathChanged` on every state change

### PathPainter

**File:** `lib/widgets/path_overlay_widget.dart` (line 168)

- Shared `CustomPainter` used by both `SolutionLayer` and `PathOverlay`
- Draws lines between consecutive path points, dots at each point, yellow highlight on last point
- Configurable colors (blue for user path, green for solution)

## Design Rationale

**Why GlobalKey instead of lifting state?**
The path and solution states are complex (immutable snapshots, history stack, BFS results). Lifting all of this into `InteractiveMaze` would bloat the orchestrator. Instead, each child owns its domain state and exposes a minimal imperative API. The parent only tracks derived values (`pathLength`, `coinsCollected`) via callbacks.

**Why Stack layering?**
The three layers (tiles, solution, user path) have independent rendering lifecycles. The tile layer only repaints when images load. The solution layer repaints on step advance. The path layer repaints on every user interaction. Separating them avoids unnecessary repaints.

**Why IgnorePointer on SolutionLayer?**
The solution layer sits between the tile layer and the path overlay. Without `IgnorePointer`, it would intercept tap/hover events meant for the path overlay above it. (In practice, since it's below `PathOverlay` in the stack, this is defensive — but it also prevents any future `GestureDetector` on that widget from stealing events.)
