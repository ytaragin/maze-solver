import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maze/maze.dart';
import '../models/maze.dart';
import '../models/maze_path.dart';
import '../utils/maze_coordinates.dart';
import 'csv_maze_widget.dart';

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
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mazePath = MazePath.fromMaze(widget.maze);
    _coordinates = MazeCoordinates(tileSize: widget.tileSize);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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

  bool get _isSuccess => _mazePath.hasReachedEnd();

  void _clearPath() {
    setState(() {
      _mazePath = MazePath.fromMaze(widget.maze);
    });
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    Direction? direction;
    
    // Map arrow keys to directions
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      direction = Direction.north;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      direction = Direction.south;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      direction = Direction.west;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      direction = Direction.east;
    }

    // Get target location using maze logic
    if (direction != null) {
      final targetLocation = widget.maze.mazeArray.getLocationInDirection(
        _mazePath.currentLocation,
        direction,
      );
      
      // Try to move if we have a valid target location
      if (targetLocation != null) {
        final newPath = _mazePath.moveToLocation(targetLocation);
        if (newPath != null) {
          setState(() {
            _mazePath = newPath;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyPress(event);
        return KeyEventResult.handled;
      },
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Column(
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
                          isSuccess: _isSuccess,
                        ),
                      ),
                    ),
                    
                    // Success overlay
                    if (_isSuccess)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.3),
                          child: const Center(
                            child: Text(
                              'SUCCESS!',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.white,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter for drawing the user's path
class PathPainter extends CustomPainter {
  final MazePath mazePath;
  final MazeCoordinates coordinates;
  final bool isSuccess;

  PathPainter({
    required this.mazePath,
    required this.coordinates,
    this.isSuccess = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = mazePath.userPath;
    if (path.isEmpty) return;

    // Choose colors based on success state
    final pathColor = isSuccess ? Colors.green : Colors.blue;

    // Paint for the path line
    final linePaint = Paint()
      ..color = pathColor.withOpacity(0.6)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Paint for the dots at each point
    final dotPaint = Paint()
      ..color = pathColor
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
    return oldDelegate.mazePath != mazePath || 
           oldDelegate.coordinates != coordinates ||
           oldDelegate.isSuccess != isSuccess;
  }
}
