# BFS Solver

This document describes the maze-solving algorithm and how the solution is presented in the UI.

## Algorithm

**File:** `packages/maze/lib/src/maze_bfs.dart`

### MazeShortestPath

Takes a `MazeGraph` and finds the shortest path from `startNode` to the first node with `SpotType.end`.

### `findPath()` (line 28)

Standard BFS using a `Queue<PathState>`:

1. Seed queue with `PathState(node: graph.startNode)`
2. Dequeue front state
3. If current node is `SpotType.end` → return `BfsResult.found(path)`
4. Expand via `current.getAllowedNeighbors()` — returns `List<(MazeNode, int coinCost)>`
5. For each valid neighbor, enqueue `current.next(coinsDelta: -coinCost, newNode: neighbor)`
6. If queue empties → return `BfsResult.notFound()`

### BfsResult (line 5)

```dart
class BfsResult {
  final bool pathFound;
  final List<MazeLocation> path;
}
```

## Constraint System (PathState rules)

**File:** `packages/maze/lib/src/maze_path.dart`

The BFS uses the same `PathState` class as the interactive player. Constraints enforced in `_verifyMazeRules()` (line 61):

| Tile Type | Rule | Cost |
|-----------|------|------|
| `path`, `start`, `end` | Always legal | Free |
| `cent` (coin) | Always legal | Grants +1 coin (only first visit) |
| `wall` | Never legal | — |
| `bridgeNS`, `bridgeEW` | Requires `coinsCollected >= 1` | Costs 1 coin |

Additional rules:
- **No immediate backtracking** (line 63): cannot return to the node you just came from (`path[length-2]`)
- **Edge-visit tracking**: `visitedEdges` stores `(startLocation, endLocation, coinCount)` tuples. The BFS won't re-traverse the same edge with the same coin balance (prevents infinite loops). This is the cycle-detection mechanism.

### `getAllowedNeighbors()` (line 87)

For each neighbor of the current node:
1. Skip if this edge was already visited with the same coin state (unless `allowLoops` is true)
2. Apply `_verifyMazeRules()` to check legality and get coin cost
3. Return list of `(MazeNode, coinCost)` pairs

## SolutionLayer Widget

**File:** `lib/widgets/solution_layer.dart`

Displays the BFS solution in the Flutter app with step-by-step reveal.

### State

- `_solutionPath: List<MazeLocation>` — full BFS result
- `_depth: int` — number of steps currently shown (starts at 1, showing only start)

### Public Methods (called via GlobalKey from parent)

| Method | Behavior |
|--------|----------|
| `generateSolution()` | Runs `MazeShortestPath(graph).findPath()`, stores result |
| `advanceStep()` | Increments `_depth` by 1, reveals next tile |
| `setFullPath()` | Sets `_depth = _solutionPath.length`, shows entire solution |
| `clearSolution()` | Resets `_depth = 1`, hides solution (keeps start dot) |
| `getSolutionPath()` | Returns `_solutionPath.sublist(0, _depth)` |

### Rendering

Uses `CustomPaint` with `PathPainter` (green color). Wrapped in `IgnorePointer` so it doesn't intercept user clicks meant for `PathOverlay`.

## Why BFS (not DFS/Dijkstra)

BFS guarantees the shortest path in an unweighted graph. Although bridges have a coin "cost", the graph is effectively unweighted for pathfinding purposes — the coin cost is a constraint (you must have coins to cross), not a distance metric. BFS explores all states at depth N before depth N+1, finding the minimum-step solution.

The coin-state tracking in `visitedEdges` effectively makes this a BFS over a state space of `(location, coinBalance)` pairs rather than just locations, which correctly handles cases where you need to collect coins before crossing bridges.
