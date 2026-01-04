import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maze/maze.dart';
import '../models/maze.dart';
import '../models/maze_path.dart';
import '../utils/maze_coordinates.dart';

/// Widget for displaying and managing the user's path overlay
class PathOverlay extends StatefulWidget {
  final Maze maze;
  final MazeCoordinates coordinates;
  final ValueChanged<MazePath>? onPathChanged;

  const PathOverlay({
    super.key,
    required this.maze,
    required this.coordinates,
    this.onPathChanged,
  });

  @override
  PathOverlayState createState() => PathOverlayState();
}

class PathOverlayState extends State<PathOverlay> {
  late MazePath _mazePath;
  MazeLocation? _hoveredLocation;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _mazePath = MazePath.fromMaze(widget.maze);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleHover(Offset localPosition) {
    final location = widget.coordinates.screenToLocation(localPosition);

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
    final location = widget.coordinates.screenToLocation(localPosition);

    // Try to move to the new location
    final newPath = _mazePath.moveToLocation(location);
    if (newPath != null) {
      setState(() {
        _mazePath = newPath;
      });
      widget.onPathChanged?.call(_mazePath);
    }
  }

  void clearPath() {
    setState(() {
      _mazePath = MazePath.fromMaze(widget.maze);
    });
    widget.onPathChanged?.call(_mazePath);
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
          widget.onPathChanged?.call(_mazePath);
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
        child: MouseRegion(
          onHover: (event) => _handleHover(event.localPosition),
          onExit: _handleExit,
          cursor: _hoveredLocation != null && 
                  _mazePath.isLocationAllowed(_hoveredLocation!)
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition),
            child: CustomPaint(
              size: widget.coordinates.getMazeSize(widget.maze.mazeArray.rows, widget.maze.mazeArray.cols),
              painter: PathPainter(
                mazePath: _mazePath,
                coordinates: widget.coordinates,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter for drawing the user's path
class PathPainter extends CustomPainter {
  final MazePath mazePath;
  final MazeCoordinates coordinates;
  final Color pathColor;
  final Color highlightColor;

  PathPainter({
    required this.mazePath,
    required this.coordinates,
    this.pathColor = Colors.blue,
    this.highlightColor = Colors.yellow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = mazePath.userPath;
    if (path.isEmpty) return;

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
        ..color = highlightColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastCenter, 8.0, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.mazePath != mazePath || 
           oldDelegate.coordinates != coordinates ||
           oldDelegate.pathColor != pathColor ||
           oldDelegate.highlightColor != highlightColor;
  }
}
