import 'package:maze/maze.dart';
import 'maze.dart';

/// Model for tracking and managing the user's path through the maze
class MazePath {
  final MazeGraph graph;
  final PathState pathState;
  final List<MazeLocation> userPath;

  MazePath._({
    required this.graph,
    required this.pathState,
    List<MazeLocation>? userPath,
  }) : userPath = userPath ?? [];

  /// Create a new MazePath from a Maze model
  /// Builds the graph and initializes the path at the start node
  factory MazePath.fromMaze(Maze maze) {
    // Build the immutable graph from the maze array
    final graph = MazeGraph(maze.mazeArray);
    
    // Create initial path state at the start node
    final pathState = PathState(node: graph.startNode);
    
    return MazePath._(
      graph: graph,
      pathState: pathState,
      userPath: [graph.startNode.location],
    );
  }

  /// Get the current location
  MazeLocation get currentLocation => pathState.node.location;

  /// Get all path locations
  List<MazeLocation> get pathLocations {
    return pathState.path.map((node) => node.location).toList();
  }

  /// Get the number of coins collected so far
  int get coinsCollected => pathState.coinsCollected;

  /// Get the path length
  int get pathLength => pathState.path.length;

  /// Get all allowed next locations with their coin costs
  /// Returns a list of (MazeLocation, coinsSpent)
  List<(MazeLocation, int)> getAllowedNextLocations() {
    final allowedNeighbors = pathState.getAllowedNeighbors();
    return allowedNeighbors.map((tuple) {
      final (node, coinsSpent) = tuple;
      return (node.location, coinsSpent);
    }).toList();
  }

  /// Get just the allowed next locations (without coin info)
  Set<MazeLocation> getAllowedLocations() {
    return getAllowedNextLocations()
        .map((tuple) => tuple.$1)
        .toSet();
  }

  /// Check if a location is an allowed next move
  bool isLocationAllowed(MazeLocation location) {
    return getAllowedLocations().contains(location);
  }

  /// Get the coin cost for moving to a specific location
  /// Returns null if the move is not allowed
  int? getCoinCostForLocation(MazeLocation location) {
    final allowedMoves = getAllowedNextLocations();
    for (final (allowedLocation, cost) in allowedMoves) {
      if (allowedLocation == location) {
        return cost;
      }
    }
    return null;
  }

  /// Try to move to a new location
  /// Returns a new MazePath if successful, null if the move is not allowed
  MazePath? moveToLocation(MazeLocation location) {
    // Find the neighbor node and coin cost
    final allowedNeighbors = pathState.getAllowedNeighbors();
    
    for (final (neighborNode, coinsSpent) in allowedNeighbors) {
      if (neighborNode.location == location) {
        // Valid move - create new state
        final newPathState = pathState.next(
          coinsDelta: -coinsSpent,
          newNode: neighborNode,
        );
        
        return MazePath._(
          graph: graph, // Reuse the same immutable graph
          pathState: newPathState,
          userPath: [...userPath, location],
        );
      }
    }
    
    return null; // Invalid move
  }

  /// Check if the path has reached the end
  bool hasReachedEnd() {
    final endLocation = graph.underlyingMazeArray.getNodesByType(SpotType.end);
    if (endLocation == null) return false;
    return pathState.node.location == endLocation;
  }

  /// Get the end node from the graph
  MazeNode? getEndNode() {
    final endLocation = graph.underlyingMazeArray.getNodesByType(SpotType.end);
    return endLocation != null ? graph.getNode(endLocation) : null;
  }

  /// Get a summary of the current state
  String getSummary() {
    return 'MazePath(length: $pathLength, coins: $coinsCollected, '
           'current: $currentLocation, allowed moves: ${getAllowedLocations().length})';
  }

  @override
  String toString() => pathState.toString();
}
