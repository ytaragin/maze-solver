# Maze Graph System

This document describes how a maze CSV file is parsed into a tile grid and then built into a traversable graph.

## Pipeline Overview

```
CSV file  →  MazeArray (2D tile grid)  →  MazeGraph (nodes + edges)
```

## MazeLocation

**File:** `packages/maze/lib/src/maze_array.dart` (line 4)

```dart
class MazeLocation {
  final int row;
  final int col;
  final int z;  // defaults to 0; z=1 for tunnel-level nodes
}
```

Equality is based on `row` and `col` only (ignores `z`). This means bridge surface nodes and tunnel nodes at the same grid cell share a hash, but are stored as separate entries in the graph's node list.

## MazeArray — CSV to Tile Grid

**File:** `packages/maze/lib/src/maze_array.dart` (line 25)

A 2D grid of `Tile` objects: `List<List<Tile>> tiles`, indexed as `tiles[row][col]`.

### Parsing (`fromCsvString`, line 35)

1. Parses CSV using `CsvToListConverter`
2. Maps each integer cell value to a `Tile` via `TileManager.withVariants()`
3. Returns `MazeArray(tiles: ...)`

### Key Methods

| Method | Description |
|--------|-------------|
| `getStartLocation()` | Finds first tile with `SpotType.start` |
| `getNodesByType(SpotType)` | Linear scan, returns first matching `MazeLocation` or null |
| `getTile(row, col)` | Bounds-checked tile access |
| `getLocationInDirection(location, direction)` | Shifts row/col by one in the given direction, returns null if out of bounds |

## MazeGraph — Graph Construction

**File:** `packages/maze/lib/src/maze_graph.dart` (line 21)

### Structure

```dart
class MazeGraph {
  final Map<MazeLocation, List<MazeNode>> nodes;  // multiple nodes per location (bridges)
  late final MazeNode startNode;
  final MazeArray underlyingMazeArray;
}
```

### Two-Pass Build (`_buildGraph`, line 31)

**Pass 1 — Node Creation (lines 34-54):**

For each grid cell, creates a `MazeNode(location, tile)`. For bridge tiles, creates a **second node** at z=1:

| Surface Tile | Surface Directions | Tunnel Node Created | Tunnel Directions |
|-------------|-------------------|--------------------|--------------------|
| `bridgeNS` (id 41) | N, S | `tunnelEW` (id -1) at z=1 | E, W |
| `bridgeEW` (id 42) | E, W | `tunnelNS` (id -2) at z=1 | N, S |

**Pass 2 — Neighbor Connection (lines 57-61):**

For each node, calls `_findNeighbors(node)`:
1. For each direction in `node.tile.directions`:
   - Gets the adjacent location via `getLocationInDirection`
   - Gets all nodes at that location (may be >1 for bridges)
   - For each candidate, checks `canConnectToOtherTileInDirection(dir, otherNode.tile)` — requires this tile to have `dir` AND the other tile to have the **opposite** direction
   - If compatible, adds as a neighbor

## MazeNode

**File:** `packages/maze/lib/src/maze_graph.dart` (line 4)

```dart
class MazeNode {
  final MazeLocation location;
  final Tile tile;
  final neighbors = <MazeNode>[];
}
```

A simple adjacency-list graph node.

## Multi-Level (Bridge/Tunnel) Example

Given tile 41 (`bridgeNS`) at position (3, 5):

```
Surface node: MazeNode(location=(3,5,z=0), tile=bridgeNS{N,S})
  → connects to tiles at (2,5) and (4,5) if they have S and N respectively

Tunnel node: MazeNode(location=(3,5,z=1), tile=tunnelEW{E,W})
  → connects to tiles at (3,4) and (3,6) if they have E and W respectively
```

This allows paths to cross without intersecting — the bridge carries N-S traffic on the surface while E-W traffic passes underneath.

## Direction & Connectivity

**File:** `packages/maze/lib/src/spot_type.dart` (line 46)

```dart
enum Direction { north, south, east, west }
```

Each direction has a `getOpposite()` method. Two tiles connect across a shared border only if tile A has the direction pointing toward tile B, AND tile B has the opposite direction pointing back toward tile A.
