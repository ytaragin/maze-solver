# Tile System

This document describes how tiles are defined, how CSV numbers map to tile properties and images, and how to add new tile types.

## Tile Class

**File:** `packages/maze/lib/src/tiles.dart` (line 4)

```dart
class Tile {
  final int id;              // variant number from CSV
  final SpotType type;       // semantic meaning (path, wall, start, end, coin, bridge, tunnel)
  final Set<Direction> directions;  // which edges are open for graph connections
}
```

Key method: `canConnectToOtherTileInDirection(dir, other)` — returns true if this tile has `dir` AND `other` has the opposite direction.

## SpotType Enum

**File:** `packages/maze/lib/src/spot_type.dart` (line 2)

| Value | Meaning | Debug Char |
|-------|---------|-----------|
| `path` | Walkable tile | `O` |
| `wall` | Impassable | `.` |
| `start` | Maze entry point | `S` |
| `end` | Maze exit/goal | `E` |
| `cent` | Coin collectible | `C` |
| `bridgeNS` | Bridge surface (N-S) | `"` |
| `bridgeEW` | Bridge surface (E-W) | `=` |
| `tunnelNS` | Tunnel under bridge (N-S) | `T"` |
| `tunnelEW` | Tunnel under bridge (E-W) | `T=` |

## TileManager — Variant Registry

**File:** `packages/maze/lib/src/tiles.dart` (line 94)

`TileManager.withVariants()` registers all known tile variants. Uses a helper that creates 4 variants per base shape:

| Offset | SpotType |
|--------|----------|
| base ID | `path` |
| +10 | `cent` (coin) |
| +20 | `start` |
| +30 | `end` |

### Base Tile Directions

| Base ID | Directions |
|---------|-----------|
| 1 | N, S |
| 2 | E, W |
| 3 | E, S |
| 4 | S, W |
| 5 | N, E |
| 6 | N, W |
| 7 | N, E, S |
| 8 | N, W, S |
| 9 | W, E, S |
| 10 | N, E, W |

### Special Tiles

| ID | Type | Directions |
|----|------|-----------|
| 41 | `bridgeNS` | N, S |
| 42 | `bridgeEW` | E, W |
| 43 | `path` (4-way) | N, S, E, W |
| -1 | `tunnelEW` | E, W (synthetic, not in CSV) |
| -2 | `tunnelNS` | N, S (synthetic, not in CSV) |

Tunnel tiles are never in the CSV — they are created programmatically by the graph builder when it encounters bridge tiles.

## Tile Images

**Directory:** `tiles/`

Images are named `Variant{id}.png` (e.g., `Variant1.png`, `Variant11.png`, `Variant41.png`).

The `TileRenderer` in `packages/maze_image/` loads these by scanning the folder with regex `Variant(\d+)\.png` and caching decoded images.

In the Flutter app, `CsvMaze` loads them from `rootBundle` as Flutter assets.

## How to Add a New Tile Type

1. **Create the PNG** — Add `tiles/Variant{N}.png` with the next available ID

2. **Register in `SpotType`** (`packages/maze/lib/src/spot_type.dart`) — Add a new enum value if the tile has new semantic behavior. Update `toString()`.

3. **Register in `TileManager.withVariants()`** (`packages/maze/lib/src/tiles.dart`) — Add:
   ```dart
   manager.addTile(Tile.variant(id, SpotType.newType, {Direction.north, ...}));
   ```
   Or use `addSetOfTiles(baseId, directions)` if you want the automatic path/coin/start/end family.

4. **Add graph logic** (if needed) (`packages/maze/lib/src/maze_graph.dart`) — If the tile creates multiple nodes (like bridges), add handling in `_buildGraph()`.

5. **Add pathfinding rules** (if needed) (`packages/maze/lib/src/maze_path.dart`) — If the tile has special traversal costs or constraints, add a case in `_verifyMazeRules()`.

6. **Register as asset** — Ensure the PNG is covered by the glob pattern in `pubspec.yaml` under `flutter.assets`.
