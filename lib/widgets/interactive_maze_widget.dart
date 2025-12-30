import 'package:flutter/material.dart';
import 'package:maze/maze.dart';
import '../models/maze.dart';
import '../models/maze_path.dart';
import '../utils/maze_coordinates.dart';
import 'csv_maze_widget.dart';

/// Interactive Maze Widget with path building
class InteractiveMazeWidget extends StatefulWidget {
  final String csvPath;
  final double tileSize;

  const InteractiveMazeWidget({
    super.key,
    required this.csvPath,
    this.tileSize = 32.0,
  });

  @override
  State<InteractiveMazeWidget> createState() => _InteractiveMazeWidgetState();
}

class _InteractiveMazeWidgetState extends State<InteractiveMazeWidget> {
  Maze? _maze;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMaze();
  }

  Future<void> _loadMaze() async {
    try {
      _maze = await Maze.fromAsset(widget.csvPath);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading maze: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_maze == null) {
      return const Center(child: Text('No maze data loaded'));
    }

    return Column(
      children: [
        // Maze with path overlay
        PathOverlayWidget(
          maze: _maze!,
          tileSize: widget.tileSize,
        ),
      ],
    );
  }
}

/// Widget for displaying and managing the user's path overlay
class PathOverlayWidget extends StatefulWidget {
  final Maze maze;
  final double tileSize;

  const PathOverlayWidget({
    super.key,
    required this.maze,
    required this.tileSize,
  });

  @override
  State<PathOverlayWidget> createState() => _PathOverlayWidgetState();
}

class _PathOverlayWidgetState extends State<PathOverlayWidget> {
  late MazePath _mazePath;
  late MazeCoordinates _coordinates;
  MazeLocation? _hoveredLocation;

  @override
  void initState() {
    super.initState();
    _mazePath = MazePath.fromMaze(widget.maze);
    _coordinates = MazeCoordinates(tileSize: widget.tileSize);
  }

  void _handleHover(Offset localPosition) {
    final location = _coordinates.screenToLocation(localPosition);

    if (_hoveredLocation != location) {
      setState(() {
        _hoveredLocation = location;
      });
    }
  }

  void _handleExit(PointerEvent event) {
    setState(() {
      _hoveredLocation = null;
    });
  }

  void _handleTap(Offset localPosition) {
    // Convert screen position to maze coordinates
    final location = _coordinates.screenToLocation(localPosition);

    // Try to move to the new location
    final newPath = _mazePath.moveToLocation(location);
    if (newPath != null) {
      setState(() {
        _mazePath = newPath;
      });
    }
  }

  void _clearPath() {
    setState(() {
      _mazePath = MazePath.fromMaze(widget.maze);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls
        Row(
          children: [
            ElevatedButton(
              onPressed: _clearPath,
              child: const Text('Clear Path'),
            ),
            const SizedBox(width: 8),
            Text('Steps: ${_mazePath.pathLength}, Coins: ${_mazePath.coinsCollected}'),
          ],
        ),
        const SizedBox(height: 8),
        
        // Maze with path overlay - both use the same coordinate system
        MouseRegion(
          onHover: (event) => _handleHover(event.localPosition),
          onExit: _handleExit,
          cursor: _hoveredLocation != null && 
                  _mazePath.isLocationAllowed(_hoveredLocation!)
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition),
            child: Stack(
              children: [
                // Background maze tiles - defines the coordinate system
                CsvMazeWidget(
                  maze: widget.maze,
                  coordinates: _coordinates,
                ),
                
                // Path rendering - uses the same coordinate system
                Positioned.fill(
                  child: CustomPaint(
                    painter: PathPainter(
                      mazePath: _mazePath,
                      coordinates: _coordinates,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter for drawing the user's path
class PathPainter extends CustomPainter {
  final MazePath mazePath;
  final MazeCoordinates coordinates;

  PathPainter({
    required this.mazePath,
    required this.coordinates,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = mazePath.userPath;
    if (path.isEmpty) return;

    // Paint for the path line
    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Paint for the dots at each point
    final dotPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    // Draw lines connecting path points
    for (int i = 0; i < path.length - 1; i++) {
      final start = coordinates.locationToCenter(path[i]);
      final end = coordinates.locationToCenter(path[i + 1]);
      canvas.drawLine(start, end, linePaint);
    }

    // Draw dots at each point
    for (final location in path) {
      final center = coordinates.locationToCenter(location);
      canvas.drawCircle(center, 6.0, dotPaint);
    }

    // Highlight the latest point
    if (path.isNotEmpty) {
      final lastCenter = coordinates.locationToCenter(path.last);
      final highlightPaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastCenter, 8.0, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.mazePath != mazePath || oldDelegate.coordinates != coordinates;
  }
}
