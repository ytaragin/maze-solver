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
  /// Uses the maze's existing graph and initializes the path at the start node
  factory MazePath.fromMaze(Maze maze) {
    assert(maze.isValid, 'Cannot create MazePath from an invalid maze');
    final graph = maze.graph;
    
    // Create initial path state at the start node
    final pathState = PathState(
      node: graph.startNode!, 
      allowLoops: true,
    );
    
    return MazePath._(
      graph: graph,
      pathState: pathState,
      userPath: [graph.startNode!.location],
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
    final allowed = getAllowedLocations();
    return allowed.any((loc) => loc.row == location.row && loc.col == location.col);
  }

  /// Check if a location is part of any directly reachable path (no branching)
  bool isLocationReachable(MazeLocation location) {
    if (isLocationAllowed(location)) return true;
    
    final directPaths = pathState.getDirectReachableNeighbors();
    for (final path in directPaths) {
      if (path.any((node) => node.location.row == location.row && node.location.col == location.col)) {
        return true;
      }
    }
    return false;
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

  /// Try to move to a location by searching through directly reachable paths.
  /// If the location is found on a path, it moves the user to the end of that path.
  MazePath? moveByLocation(MazeLocation location) {
    // First check if it's an immediate neighbor (classic move)
    final immediate = moveToLocation(location);
    if (immediate != null) {
      // Even if it's immediate, we want to continue to the decision point
      // So we find which direction this was and use moveInDirection
      final rowDiff = location.row - currentLocation.row;
      final colDiff = location.col - currentLocation.col;
      
      Direction? dir;
      if (rowDiff == -1) {
        dir = Direction.north;
      } else if (rowDiff == 1) {
        dir = Direction.south;
      } else if (colDiff == -1) {
        dir = Direction.west;
      } else if (colDiff == 1) {
        dir = Direction.east;
      }
      
      if (dir != null) {
        return moveInDirection(dir);
      }
      return immediate;
    }

    // If not immediate, check if the clicked location is part of any direct path
    final directPaths = pathState.getDirectReachableNeighbors();
    for (final path in directPaths) {
      if (path.any((node) => node.location.row == location.row && node.location.col == location.col)) {
        // The location is on this path! Move to the end of this path.
        PathState newState = pathState;
        List<MazeLocation> newLocations = [...userPath];

        for (final node in path) {
          final allowed = newState.getAllowedNeighbors();
          final step = allowed.firstWhere((element) => element.$1 == node);
          
          newState = newState.next(
            coinsDelta: -step.$2,
            newNode: node,
          );
          newLocations.add(node.location);
        }

        return MazePath._(
          graph: graph,
          pathState: newState,
          userPath: newLocations,
        );
      }
    }

    return null;
  }

  /// Move in a specific direction until a decision point is reached.
  /// A decision point is an intersection, a dead end, or a point requiring a turn.
  MazePath? moveInDirection(Direction direction) {
    // 1. Find ANY neighbor in the requested direction (regardless of Z)
    final allowedNeighbors = pathState.getAllowedNeighbors();
    (MazeNode, int)? startStep;
    
    for (final neighborTuple in allowedNeighbors) {
      final loc = neighborTuple.$1.location;
      // Calculate movement vector
      final rowDiff = loc.row - currentLocation.row;
      final colDiff = loc.col - currentLocation.col;
      
      bool matches = false;
      if (direction == Direction.north && rowDiff < 0) matches = true;
      if (direction == Direction.south && rowDiff > 0) matches = true;
      if (direction == Direction.west && colDiff < 0) matches = true;
      if (direction == Direction.east && colDiff > 0) matches = true;
      
      if (matches) {
        startStep = neighborTuple;
        break;
      }
    }

    if (startStep == null) return null;

    // 2. Find a direct path that begins with this step
    final directPaths = pathState.getDirectReachableNeighbors();
    List<MazeNode>? chosenPath;

    for (final path in directPaths) {
      if (path.isNotEmpty && path.first == startStep.$1) {
        chosenPath = path;
        break;
      }
    }

    // 3. Fallback to just the single step if no path was calculated
    chosenPath ??= [startStep.$1];

    // 4. Step through the path to build the final state
    PathState newState = pathState;
    List<MazeLocation> newLocations = [...userPath];

    for (final node in chosenPath) {
      final allowed = newState.getAllowedNeighbors();
      
      // Find the specific neighbor to get the coin cost.
      final step = allowed.cast<(MazeNode, int)?>().firstWhere(
        (element) => element?.$1 == node,
        orElse: () => null,
      );
      
      if (step == null) break;

      newState = newState.next(
        // coinsSpent is negative for picking up coins, positive for spending.
        // next() adds coinsDelta to the total, so we negate coinsSpent.
        coinsDelta: -step.$2,
        newNode: node,
      );
      newLocations.add(node.location);
    }

    return MazePath._(
      graph: graph,
      pathState: newState,
      userPath: newLocations,
    );
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

  /// Creates a copy of this MazePath with a different user path list
  /// Used primarily for visual updates during undo animations
  MazePath cloneWithUserPath(List<MazeLocation> newUserPath) {
    return MazePath._(
      graph: graph,
      pathState: pathState,
      userPath: newUserPath,
    );
  }
}
