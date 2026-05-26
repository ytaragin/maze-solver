# Path and History Mechanism

This document describes how the user's path through the maze is tracked, updated, and undone. It is intended for agents and developers modifying path-related behavior.

## Architecture Overview

The path system spans two layers:

```
UI Layer (lib/)
  PathOverlayState          – holds current MazePath + history stack
  MazePath (lib/models/)    – immutable snapshot of path state + user locations

Core Layer (packages/maze/)
  PathState                 – immutable node-level state (path list, visited edges, coins)
```

## Key Classes

### `PathState` (`packages/maze/lib/src/maze_path.dart`)

The lowest-level path representation. Immutable. Contains:

| Field | Type | Description |
|-------|------|-------------|
| `node` | `MazeNode` | Current position in the graph |
| `path` | `List<MazeNode>` | Ordered history of every node visited |
| `visitedEdges` | `Set<EdgeVisit>` | Every directed edge traversed |
| `coinsCollected` | `int` | Running coin total (can go negative from bridge costs) |
| `allowLoops` | `bool` | When true, revisiting edges is permitted |

Movement is done via `next(coinsDelta, newNode)` which returns a **new** `PathState` with the node appended.

Rules enforced in `_verifyMazeRules()`:
- Cannot immediately backtrack to the previous node
- Walls block movement
- Bridges cost 1 coin

### `MazePath` (`lib/models/maze_path.dart`)

App-layer wrapper around `PathState`. Also immutable. Contains:

| Field | Type | Description |
|-------|------|-------------|
| `graph` | `MazeGraph` | Shared reference to the maze graph (never copied) |
| `pathState` | `PathState` | Current core state |
| `userPath` | `List<MazeLocation>` | Ordered list of `(row, col)` locations for rendering |

Key methods:
- `moveToLocation(location)` — returns a new `MazePath` on success, `null` on illegal move
- `isLocationAllowed(location)` — checks if a location is a valid next step
- `getAllowedNextLocations()` — returns all legal moves with coin costs

### `PathOverlayState` (`lib/widgets/path_overlay_widget.dart`)

The stateful widget that owns the path. Manages:

| Field | Type | Description |
|-------|------|-------------|
| `_mazePath` | `MazePath` | The current path state |
| `_history` | `List<MazePath>` | Stack of previous states for undo |

## Movement Flow

```
User input (tap / arrow key)
  -> resolve target MazeLocation
  -> _mazePath.moveToLocation(target)
  -> if success:
       _history.add(_mazePath)      // save current state for undo
       _mazePath = newPath           // adopt new state
       onPathChanged(newPath)        // notify parent
```

## Undo Flow (Backspace)

```
User presses Backspace
  -> _undoLastMove()
  -> if _history.isNotEmpty:
       _mazePath = _history.removeLast()   // restore previous state
       onPathChanged(_mazePath)             // notify parent
```

This is O(1) and correct by construction — the popped `MazePath` is the exact state that existed before the last move, including coins, visited edges, and path list.

## Clear Path Flow

```
clearPath()
  -> _mazePath = MazePath.fromMaze(maze)   // reset to start
  -> _history.clear()                       // discard all history
  -> onPathChanged(_mazePath)
```

## Immutability Contract

All path objects (`PathState`, `MazePath`) are immutable value objects. Movement always produces a **new** instance; old instances remain valid indefinitely. This is what makes the history stack work — stored snapshots are never mutated.

Memory cost is low because:
- All `MazePath` instances share the same `MazeGraph` reference
- `MazeNode` and `MazeLocation` objects are shared across instances
- Only the `List` and `Set` containers are new per snapshot (containing shared element references)

## Parent Notification

`PathOverlay` accepts an `onPathChanged` callback. It fires on every state change (move, undo, clear). The parent `InteractiveMaze` uses this to update displayed path length and coin count.

## Design Decisions

1. **History lives at the UI layer only** — the core `packages/maze` library has no undo concept. This keeps the core simple and the undo mechanism easy to replace.
2. **Unbounded history** — maze paths are short enough (typically <200 steps) that memory is not a concern.
3. **No replay approach** — we store full snapshots rather than replaying moves, because reversing coin costs and edge sets would be fragile and require core library changes.
