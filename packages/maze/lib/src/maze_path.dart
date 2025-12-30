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
        final coinsSpent = path.contains(neighborNode)
            ? 0
            : -1;
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
        EdgeVisit(
          node.location,
          neighbor.location,
          coinsCollected,
        ),
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
