import 'dart:collection';
import 'package:maze/maze.dart';
import 'maze_path.dart';

/// Result of a BFS traversal from start to end node.
class BfsResult {
  /// Whether a path was found from start to end.
  final bool pathFound;

  /// The path from start to end as a list of locations.
  /// Empty if no path was found.
  final List<MazeLocation> path;

  BfsResult({required this.pathFound, required this.path});

  BfsResult.notFound() : pathFound = false, path = [];

  BfsResult.found(this.path) : pathFound = true;
}

/// Performs Breadth-First Search (BFS) traversal over a MazeGraph.
class MazeShortestPath {
  final MazeGraph graph;

  MazeShortestPath(this.graph);

  /// Runs BFS from the start node to find the end node.
  /// Returns a BfsResult containing the path, distance, and visited nodes.
  BfsResult findPath() {
    final Queue<PathState> queue = Queue();

    queue.add(PathState(node: graph.startNode));
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      print('Q: ${queue.length} State is $current');

      // Found the end node
      if (current.node.tile.type == SpotType.end) {
        return BfsResult.found(_reconstructPath(current));
      }

      // Explore neighbors
      for (final (neighbor, coinsSpent) in current.getAllowedNeighbors()) {
        queue.add(current.next(coinsDelta: -coinsSpent, newNode: neighbor));
      }
    }

    // No path found
    return BfsResult.notFound();
  }

  /// Reconstructs the path from start to end using the parent map.
  List<MazeLocation> _reconstructPath(PathState state) {
    // return the visited locations as the path with end at the end of the list
    return [...state.path.map((node) => node.location), state.node.location];
  }
}
