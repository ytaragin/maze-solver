import 'package:maze/maze.dart';

import 'tiles.dart';
import 'maze_array.dart';
import 'spot_type.dart';

class MazeNode {
  final MazeLocation location;
  final Tile tile;
  final neighbors = <MazeNode>[];

  MazeNode({required this.location, required this.tile});

  void addNeighbor(MazeNode neighbor) {
    neighbors.add(neighbor);
  }

  @override
  String toString() {
    return 'Node(loc: $location, tile: ${tile.id}';
  }
}

class MazeGraph {
  final Map<MazeLocation, List<MazeNode>> nodes = {};
  final MazeArray underlyingMazeArray;
  late final MazeNode startNode;

  MazeGraph(this.underlyingMazeArray) {
    _buildGraph();
    startNode = getNode(underlyingMazeArray.getStartLocation())!;
  }

  void _buildGraph() {
    TileManager tileManager = TileManager.withVariants();
    // First pass: Create all nodes
    for (int row = 0; row < underlyingMazeArray.rows; row++) {
      for (int col = 0; col < underlyingMazeArray.cols; col++) {
        final location = MazeLocation(row: row, col: col);
        final tile = underlyingMazeArray.getTile(row, col);
        final node = MazeNode(location: location, tile: tile);
        nodes.putIfAbsent(location, () => []).add(node);

        if (tile.type == SpotType.bridgeNS || tile.type == SpotType.bridgeEW) {
          final tileID = tile.type == SpotType.bridgeNS
              ? TileManager.tunnelEWID
              : TileManager.tunnelNSID;

          final tunnelLocation = MazeLocation(row: row, col: col, z: 1);
          final tunnelNode = MazeNode(
            location: tunnelLocation,
            tile: tileManager.getTile(tileID),
          );
          nodes.putIfAbsent(tunnelLocation, () => []).add(tunnelNode);
        }
      }
    }

    // Second pass: Populate neighbors
    for (var nodeList in nodes.values) {
      for (var node in nodeList) {
        _findNeighbors(node);
      }
    }
  }

  void addNode(MazeNode node) {
    nodes.putIfAbsent(node.location, () => []).add(node);
  }

  /// Retrieves nodes at a location. Returns null if not found.
  List<MazeNode>? getNodes(MazeLocation? location) {
    if (location == null) {
      return [];
    }
    return nodes[location];
  }

  /// Retrieves the first node at a location. Returns null if not found.
  MazeNode? getNode(MazeLocation location) {
    final nodeList = nodes[location];
    return nodeList != null && nodeList.isNotEmpty ? nodeList.first : null;
  }

  void _findNeighbors(MazeNode node) {
    // Check all four directions based on tile's allowed directions
    for (var dir in node.tile.directions) {
      final loc = underlyingMazeArray.getLocationInDirection(
        node.location,
        dir,
      );
      final nodes = getNodes(loc) ?? <MazeNode>[];
      // print('Ce=hecking if $node can connect');
      for (var otherNode in nodes) {
        // print("\tChecking $otherNode");
        if (node.tile.canConnectToOtherTileInDirection(dir, otherNode.tile)) {
          // print("\tIt can");
          node.addNeighbor(otherNode);
        }
      }
    }
  }

  /// Prints a summary of the graph to the specified output stream.
  ///
  /// [sink] The output stream to write to (e.g., stdout, StringBuffer).
  void printGraph(StringSink sink) {
    // Calculate total number of edges and total nodes
    int totalEdges = 0;
    int totalNodes = 0;
    for (var nodeList in nodes.values) {
      totalNodes += nodeList.length;
      for (var node in nodeList) {
        totalEdges += node.neighbors.length;
      }
    }

    // Print summary
    sink.writeln('=== Graph Summary ===');
    sink.writeln('Number of locations: ${nodes.length}');
    sink.writeln('Number of nodes: $totalNodes');
    sink.writeln('Number of edges: $totalEdges');
    sink.writeln('\n=== Edges by Location ===');

    // Print edges for each location
    for (var entry in nodes.entries) {
      final location = entry.key;
      final nodeList = entry.value;

      for (var node in nodeList) {
        final locationStr = '$location[${node.tile.type}]';
        if (node.neighbors.isEmpty) {
          sink.writeln('$locationStr => {}');
        } else {
          final neighborLocations = node.neighbors
              .map((neighbor) => neighbor.location.toString())
              .join(', ');
          sink.writeln('$locationStr => {$neighborLocations}');
        }
      }
    }
  }
}
