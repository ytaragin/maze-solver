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
  final Set<MazeNode> visitedNodes;
  final List<MazeNode> path;
  final bool allowLoops;
  final bool stopAtBridgesAlways;

  PathState({
    required this.node,
    this.coinsCollected = 0,
    Set<EdgeVisit>? visitedEdges,
    Set<MazeNode>? visitedNodes,
    List<MazeNode>? path,
    this.allowLoops = false,
    this.stopAtBridgesAlways = false,
  })  : visitedEdges = visitedEdges ?? {},
        visitedNodes = visitedNodes ?? {node},
        path = path ?? [node];

  /// Creates a new PathState by cloning the current state with modifications.
  PathState next({required int coinsDelta, required MazeNode newNode}) {
    return PathState(
      node: newNode,
      coinsCollected: coinsCollected + coinsDelta,
      visitedEdges: {
        ...visitedEdges,
        EdgeVisit(node.location, newNode.location, coinsCollected),
      },
      visitedNodes: {
        ...visitedNodes,
        newNode,
      },
      path: [...path, newNode],
      allowLoops: allowLoops,
      stopAtBridgesAlways: stopAtBridgesAlways,
    );
  }

  /// Verifies if a move from currentState to neighborNode is legal according to maze rules.
  ///
  /// Returns a tuple containing:
  /// - isLegal: whether the move is allowed
  /// - coinsSpent: how many coins this move costs
  (bool, int) _verifyMazeRules(MazeNode neighborNode) {
    // Prevent immediate back-tracking within the current path
    if (path.length > 1 && (path[path.length - 2] == neighborNode)) {
      return (false, 0);
    }

    switch (neighborNode.tile.type) {
      case SpotType.cent:
        // A coin only gives a value if we haven't visited this specific node before
        // in our entire history.
        final hasVisited = visitedNodes.contains(neighborNode);
        final coinsSpent = hasVisited ? 0 : -1;
        return (true, coinsSpent);
      case SpotType.wall:
        return (false, 0);
      case SpotType.bridgeNS:
      case SpotType.bridgeEW:
        // Crossing a bridge costs 1 coin.
        if (coinsCollected < 1) {
          return (false, 0);
        } else {
          return (true, 1);
        }
      case SpotType.tunnelNS:
      case SpotType.tunnelEW:
        // Passing under is free.
        return (true, 0);
      default:
        return (true, 0);
    }
  }

  /// Returns a list of allowed neighboring nodes and the coins needed to reach them.
  /// Each entry is a tuple of (neighbor node, coins spent).
  List<(MazeNode, int)> getAllowedNeighbors() {
    final allowedNeighbors = <(MazeNode, int)>[];

    for (final neighbor in node.neighbors) {
      // Skip visitedEdges check if allowLoops is true
      final isEdgeVisited = !allowLoops && visitedEdges.contains(
        EdgeVisit(node.location, neighbor.location, coinsCollected),
      );
      
      if (!isEdgeVisited) {
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
  List<List<MazeNode>> getDirectReachableNeighbors() {
    final result = <List<MazeNode>>[];
    final initialNeighbors = getAllowedNeighbors();

    for (final (neighbor, coinsSpent) in initialNeighbors) {
      final path = <MazeNode>[neighbor];
      // We negate coinsSpent because next() adds coinsDelta to the total
      var currentState = next(coinsDelta: -coinsSpent, newNode: neighbor);

      while (true) {
        final allowedNeighbors = currentState.getAllowedNeighbors();

        // Check for distinct physical locations (Row/Col) to ignore Z-axis branching
        final distinctLocations = allowedNeighbors
            .map((tuple) => '${tuple.$1.location.row},${tuple.$1.location.col}')
            .toSet();

        // If preference is ON, check if ANY neighbor (even un-affordable) is a bridge
        // but NOT a tunnel (crossing over only).
        bool hasPotentialBridge = false;
        if (stopAtBridgesAlways) {
          hasPotentialBridge = currentState.node.neighbors.any((n) => 
            n.tile.type == SpotType.bridgeNS || n.tile.type == SpotType.bridgeEW);
        }

        if (distinctLocations.length == 1 && !hasPotentialBridge) {
          final (nextNode, nextCoinsSpent) = allowedNeighbors.first;
          currentState = currentState.next(
            coinsDelta: -nextCoinsSpent,
            newNode: nextNode,
          );
          path.add(nextNode);
        } else {
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
