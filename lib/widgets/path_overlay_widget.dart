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
  final List<MazePath> _history = [];
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
        _history.add(_mazePath);
        _mazePath = newPath;
      });
      widget.onPathChanged?.call(_mazePath);
    }
  }

  void clearPath() {
    setState(() {
      _mazePath = MazePath.fromMaze(widget.maze);
      _history.clear();
    });
    widget.onPathChanged?.call(_mazePath);
  }

  void _undoLastMove() {
    if (_history.isEmpty) return;
    setState(() {
      _mazePath = _history.removeLast();
    });
    widget.onPathChanged?.call(_mazePath);
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Handle backspace for undo
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _undoLastMove();
      return;
    }

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
      final newPath = _mazePath.moveInDirection(direction);
      if (newPath != null) {
        setState(() {
          _history.add(_mazePath);
          _mazePath = newPath;
        });
        widget.onPathChanged?.call(_mazePath);
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
                path: _mazePath.userPath,
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
  final List<MazeLocation> path;
  final MazeCoordinates coordinates;
  final Color pathColor;
  final Color highlightColor;

  PathPainter({
    required this.path,
    required this.coordinates,
    this.pathColor = Colors.blue,
    this.highlightColor = Colors.yellow,
  });

  @override
  void paint(Canvas canvas, Size size) {
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

    // Paint for the directional arrowheads
    final arrowPaint = Paint()
      ..color = pathColor.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Compute off-center "two-lane" segments using the shared geometry so the
    // overlay matches the PNG solution renderer.
    final geometry = LanePathGeometry(tileSize: coordinates.tileSize);
    final segments = geometry.computeSegments(path);

    for (final segment in segments) {
      canvas.drawLine(
        Offset(segment.start.x, segment.start.y),
        Offset(segment.end.x, segment.end.y),
        linePaint,
      );

      final arrow = segment.arrow;
      if (arrow != null) {
        final arrowPath = Path()
          ..moveTo(arrow[0].x, arrow[0].y)
          ..lineTo(arrow[1].x, arrow[1].y)
          ..lineTo(arrow[2].x, arrow[2].y)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);
      }
    }

    // Draw dots at the lane points the path actually passes through. The
    // segments are contiguous, so the vertices are the first segment's start
    // followed by each segment's end.
    final pathPoints = <Offset>[
      if (segments.isNotEmpty)
        Offset(segments.first.start.x, segments.first.start.y),
      for (final segment in segments) Offset(segment.end.x, segment.end.y),
    ];

    // Fallback for a single-location path with no segments.
    if (pathPoints.isEmpty) {
      pathPoints.add(coordinates.locationToCenter(path.first));
    }

    for (final point in pathPoints) {
      canvas.drawCircle(point, 2.0, dotPaint);
    }

    // Highlight the latest point
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pathPoints.last, 8.0, highlightPaint);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.path != path || 
           oldDelegate.coordinates != coordinates ||
           oldDelegate.pathColor != pathColor ||
           oldDelegate.highlightColor != highlightColor;
  }
}
