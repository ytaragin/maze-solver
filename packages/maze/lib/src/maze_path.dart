import 'package:maze/maze.dart';

class EdgeVisit {
  final MazeLocation start;
  final MazeLocation end;
  final int coinsCollected;

  EdgeVisit(this.start, this.end, this.coinsCollected);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgeVisit &&
          start == other.start &&
          end == other.end &&
          coinsCollected == other.coinsCollected;

  @override
  int get hashCode => Object.hash(start, end, coinsCollected);
}

class PathState {
  final MazeNode node;
  final int coinsCollected;
  final Set<EdgeVisit> visitedEdges;
  final List<MazeNode> path;

  PathState({
    required this.node,
    this.coinsCollected = 0,
    Set<MazeLocation>? visitedCoinLocations,
    Set<EdgeVisit>? visitedEdges,
    List<MazeNode>? path,
  }) : visitedEdges = visitedEdges ?? {},
       path = path ?? [node];

  /// Creates a new PathState by cloning the current state with modifications.
  ///
  /// [coinsDelta] - Amount to add to coinsCollected (can be negative)
  /// [newNode] - The new node to replace the current node
  PathState next({required int coinsDelta, required MazeNode newNode}) {
    return PathState(
      node: newNode,
      coinsCollected: coinsCollected + coinsDelta,
      visitedEdges: {
        ...visitedEdges,
        EdgeVisit(node.location, newNode.location, coinsCollected),
      },
      path: [...path, newNode],
    );
  }

  /// Verifies if a move from currentState to neighborNode is legal according to maze rules.
  ///
  /// Returns a tuple containing:
  /// - isLegal: whether the move is allowed
  /// - coinsSpent: how many coins this move costs
  (bool, int) _verifyMazeRules(MazeNode neighborNode) {
    final pathLength = path.length;
    if (pathLength > 1 && (path[pathLength - 2] == neighborNode)) {
      return (false, 0);
    }

    switch (neighborNode.tile.type) {
      case SpotType.cent:
        final coinsSpent = path.contains(neighborNode) ? 0 : -1;
        return (true, coinsSpent);
      case SpotType.wall:
        return (false, 0);
      case SpotType.bridgeNS:
      case SpotType.bridgeEW:
        if (coinsCollected < 1) {
          return (false, 0);
        } else {
          return (true, 1);
        }
      default:
        return (true, 0);
    }
  }

  /// Returns a list of allowed neighboring nodes and the coins needed to reach them.
  /// Each entry is a tuple of (neighbor node, coins spent).
  List<(MazeNode, int)> getAllowedNeighbors() {
    final allowedNeighbors = <(MazeNode, int)>[];

    for (final neighbor in node.neighbors) {
      if (!visitedEdges.contains(
        EdgeVisit(node.location, neighbor.location, coinsCollected),
      )) {
        // Verify if this move is legal according to maze rules
        final (isLegal, coinsSpent) = _verifyMazeRules(neighbor);

        if (isLegal) {
          allowedNeighbors.add((neighbor, coinsSpent));
        }
      }
    }

    return allowedNeighbors;
  }

  /// Returns a list of all nodes reachable from the current node without branching.
  ///
  /// Starting from the current node, this follows each path until it reaches:
  /// - A dead end (no further neighbors)
  /// - A branch point (multiple neighbors, excluding the path we came from)
  ///
  /// Returns a list where each element is a list of nodes representing one non-branching path.
  List<List<MazeNode>> getDirectReachableNeighbors() {
    final result = <List<MazeNode>>[];
    final initialNeighbors = getAllowedNeighbors();

    for (final (neighbor, coinsDelta) in initialNeighbors) {
      final path = <MazeNode>[neighbor];
      var currentState = next(coinsDelta: coinsDelta, newNode: neighbor);

      while (true) {
        // Get all allowed neighbors from the current state
        final allowedNeighbors = currentState.getAllowedNeighbors();

        // If there's exactly one neighbor, continue following the path
        if (allowedNeighbors.length == 1) {
          final (nextNode, nextCoinsDelta) = allowedNeighbors.first;
          currentState = currentState.next(
            coinsDelta: nextCoinsDelta,
            newNode: nextNode,
          );
          path.add(nextNode);
        } else {
          // Either a dead end (0 neighbors) or a branch (2+ neighbors) - stop here
          break;
        }
      }

      result.add(path);
    }

    return result;
  }

  @override
  String toString() {
    final buff = StringBuffer("");
    buff.writeln(
      'Tile($node c:$coinsCollected P:${path.length} V:${visitedEdges.length})',
    );
    buff.write(' >');
    for (var p in path) {
      buff.write('${p.location},');
    }
    buff.writeln();
    return buff.toString();
  }
}
