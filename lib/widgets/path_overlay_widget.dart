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

class PathOverlayState extends State<PathOverlay> with SingleTickerProviderStateMixin {
  late MazePath _mazePath;
  final List<MazePath> _history = [];
  MazeLocation? _hoveredLocation;
  final FocusNode _focusNode = FocusNode();
  
  /// Animation state
  bool _isAnimating = false;
  late AnimationController _controller;
  Offset? _animatedPlayerPosition;
  
  /// Speed of auto-movement (milliseconds per tile)
  static const int _moveSpeedMs = 150;

  @override
  void initState() {
    super.initState();
    _mazePath = MazePath.fromMaze(widget.maze);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _moveSpeedMs),
    );
  }

  @override
  void didUpdateWidget(PathOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.maze != widget.maze) {
      setState(() {
        _mazePath = MazePath.fromMaze(widget.maze);
        _history.clear();
        _isAnimating = false;
        _animatedPlayerPosition = null;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Animates the movement from the current path to the target path tile-by-tile
  Future<void> _animateToPath(MazePath? targetPath) async {
    if (targetPath == null || _isAnimating) return;
    
    // Save current state to history before moving
    _history.add(_mazePath);
    
    _isAnimating = true;
    
    final fullNewPath = targetPath.userPath;
    final int startIdx = _mazePath.userPath.length;
    
    for (int i = startIdx; i < fullNewPath.length; i++) {
      if (!mounted) break;

      final prevLocation = _mazePath.userPath.last;
      final nextLocation = fullNewPath[i];
      
      final startOffset = widget.coordinates.locationToCenter(prevLocation);
      final endOffset = widget.coordinates.locationToCenter(nextLocation);

      // Create animation for this segment
      final animation = Tween<Offset>(
        begin: startOffset, 
        end: endOffset
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ));
      
      // Listener to update the UI
      void listener() {
        setState(() {
          _animatedPlayerPosition = animation.value;
        });
      }
      _controller.addListener(listener);
      
      await _controller.forward(from: 0);
      
      _controller.removeListener(listener);

      // Update the actual path state once the step is complete
      final stepPath = _mazePath.moveToLocation(nextLocation);
      if (stepPath != null) {
        setState(() {
          _mazePath = stepPath;
          _animatedPlayerPosition = null;
        });
        widget.onPathChanged?.call(_mazePath);
      }
    }
    
    _isAnimating = false;
  }

  /// Animates the undo process back to a previous state
  Future<void> undo() async {
    if (_isAnimating || _history.isEmpty) return;

    _isAnimating = true;
    final targetPath = _history.removeLast();
    
    // We animate backwards through the current path segments until we reach the target path length
    final currentFullDisplayPath = List<MazeLocation>.from(_mazePath.userPath);
    final int targetLength = targetPath.userPath.length;

    for (int i = currentFullDisplayPath.length - 1; i >= targetLength; i--) {
      if (!mounted) break;

      final currentLocation = currentFullDisplayPath[i];
      final prevLocation = currentFullDisplayPath[i - 1];
      
      final startOffset = widget.coordinates.locationToCenter(currentLocation);
      final endOffset = widget.coordinates.locationToCenter(prevLocation);

      // Update the path to remove the segment being undone before starting the animation.
      // This ensures the PathPainter sees the segment as part of the "forward" 
      // progression (A -> player) rather than a new "backwards" step (B -> player),
      // keeping the player on the same lane.
      setState(() {
        _mazePath = _mazePath.cloneWithUserPath(currentFullDisplayPath.sublist(0, i));
      });

      final animation = Tween<Offset>(
        begin: startOffset, 
        end: endOffset
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ));

      void listener() {
        setState(() {
          _animatedPlayerPosition = animation.value;
        });
      }
      _controller.addListener(listener);
      
      await _controller.forward(from: 0);
      
      _controller.removeListener(listener);
      
      // Update our local tracking list for the next segment
      currentFullDisplayPath.removeAt(i);
      
      setState(() {
        _animatedPlayerPosition = null;
      });
    }

    // Finally, restore the exact previous state (reverting coins, etc.)
    setState(() {
      _mazePath = targetPath;
      _animatedPlayerPosition = null;
    });
    widget.onPathChanged?.call(_mazePath);
    
    _isAnimating = false;
  }

  /// Checks if the given direction moves the player back into their existing path.
  bool _isMovingBackwards(Direction direction) {
    if (_mazePath.userPath.length < 2) return false;
    
    final current = _mazePath.currentLocation;
    final previous = _mazePath.userPath[_mazePath.userPath.length - 2];
    
    final target = widget.maze.mazeArray.getLocationInDirection(current, direction);
    // We only care about row/col for the "backwards" check
    return target != null && target.row == previous.row && target.col == previous.col;
  }

  void _handleHover(Offset localPosition) {
    if (_isAnimating) return; // Disable hover effects during movement
    
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
    if (_isAnimating) return;

    // Convert screen position to maze coordinates
    final location = widget.coordinates.screenToLocation(localPosition);

    // If the user taps a previous tile in their current path, treat it as an undo
    if (_history.isNotEmpty && _mazePath.userPath.length > 1) {
      final lastState = _history.last;
      // If the location is part of the segment we JUST added, undo it
      final currentSegment = _mazePath.userPath.sublist(lastState.userPath.length);
      if (currentSegment.any((loc) => loc.row == location.row && loc.col == location.col)) {
        undo();
        return;
      }
    }

    // Try to move to the new location (auto-moving to next decision point)
    final targetPath = _mazePath.moveByLocation(location);
    _animateToPath(targetPath);
  }

  void clearPath() {
    if (_isAnimating) return;
    setState(() {
      _mazePath = MazePath.fromMaze(widget.maze);
    });
    widget.onPathChanged?.call(_mazePath);
  }

  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent || _isAnimating) return;

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

    if (direction != null) {
      // If moving backwards, trigger undo
      if (_isMovingBackwards(direction)) {
        undo();
      } else {
        final targetPath = _mazePath.moveInDirection(direction);
        _animateToPath(targetPath);
      }
    }
  }

  void _handleSwipe(DragEndDetails details) {
    if (_isAnimating) return;

    final velocity = details.velocity.pixelsPerSecond;
    
    // Threshold to avoid accidental tiny swipes
    if (velocity.distance < 300) return;

    final Direction direction;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      // Horizontal swipe is stronger
      direction = velocity.dx > 0 ? Direction.east : Direction.west;
    } else {
      // Vertical swipe is stronger
      direction = velocity.dy > 0 ? Direction.south : Direction.north;
    }

    // If moving backwards, trigger undo
    if (_isMovingBackwards(direction)) {
      undo();
    } else {
      final targetPath = _mazePath.moveInDirection(direction);
      _animateToPath(targetPath);
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
        onPanEnd: _handleSwipe,
        child: MouseRegion(
          onHover: (event) => _handleHover(event.localPosition),
          onExit: _handleExit,
          cursor: _hoveredLocation != null && 
                  _mazePath.isLocationReachable(_hoveredLocation!)
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          child: GestureDetector(
            onTapDown: (details) => _handleTap(details.localPosition),
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              size: widget.coordinates.getMazeSize(widget.maze.mazeArray.rows, widget.maze.mazeArray.cols),
              painter: PathPainter(
                path: _mazePath.userPath,
                coordinates: widget.coordinates,
                animatedPlayerPosition: _animatedPlayerPosition,
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
  final Offset? animatedPlayerPosition;

  PathPainter({
    required this.path,
    required this.coordinates,
    this.pathColor = Colors.blue,
    this.highlightColor = Colors.yellow,
    this.animatedPlayerPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final double offsetDist = coordinates.tileSize * 0.12;

    // Paint for the path line
    final linePaint = Paint()
      ..color = pathColor.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Paint for the dots at each point
    final dotPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.fill;

    // Convert locations to screen points
    final List<Offset> points = path.map(coordinates.locationToCenter).toList();
    
    // Add the currently animating position if applicable
    if (animatedPlayerPosition != null) {
      points.add(animatedPlayerPosition!);
    }

    if (points.length < 2) {
      // In initial state, show the player dot at the start position
      final highlightPaint = Paint()
        ..color = highlightColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.first, 7.0, highlightPaint);
      return;
    }

    // 1. Calculate segment directions and perpendicular offsets
    final List<Offset> segmentOffsets = [];
    final List<Offset> unitDirections = [];
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final direction = p2 - p1;
      
      if (direction.distance < 0.1) {
        // Same point, reuse previous direction or default
        unitDirections.add(unitDirections.isNotEmpty ? unitDirections.last : const Offset(1, 0));
        segmentOffsets.add(segmentOffsets.isNotEmpty ? segmentOffsets.last : Offset.zero);
        continue;
      }
      
      final unitDir = direction / direction.distance;
      unitDirections.add(unitDir);
      // Offset to the right of travel
      segmentOffsets.add(Offset(-unitDir.dy, unitDir.dx) * offsetDist);
    }

    // 2. Build the offset path points
    final List<Offset> offsetPoints = [];
    
    // First point
    offsetPoints.add(points.first + segmentOffsets.first);

    // Intermediate points
    for (int i = 1; i < points.length - 1; i++) {
      final offPrev = segmentOffsets[i - 1];
      final offNext = segmentOffsets[i];
      
      // Calculate dot product to detect U-turns
      final dot = (offPrev.dx * offNext.dx + offPrev.dy * offNext.dy) / (offsetDist * offsetDist);
      
      if (dot < -0.9) {
        // U-turn detected: Use two points to sweep around the center
        offsetPoints.add(points[i] + offPrev);
        offsetPoints.add(points[i] + offNext);
      } else {
        // Average the offsets for a smooth join
        // For 90 degree turns, we could use miter joins, but averaging is simple and effective
        offsetPoints.add(points[i] + (offPrev + offNext) / 2);
      }
    }

    // Last point
    offsetPoints.add(points.last + segmentOffsets.last);

    // 3. Draw the lines
    final drawPath = Path();
    drawPath.moveTo(offsetPoints.first.dx, offsetPoints.first.dy);
    for (int i = 1; i < offsetPoints.length; i++) {
      drawPath.lineTo(offsetPoints[i].dx, offsetPoints[i].dy);
    }
    canvas.drawPath(drawPath, linePaint);

    // 4. Draw direction arrows on each segment
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i+1];
      if ((p2 - p1).distance < 0.1) continue;

      final off = segmentOffsets[i];
      final mid = (p1 + p2) / 2 + off;
      _drawArrow(canvas, mid, unitDirections[i], pathColor);
    }

    // 5. Highlight the current player position
    final lastCenter = offsetPoints.last;
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastCenter, 7.0, highlightPaint);
  }

  void _drawArrow(Canvas canvas, Offset center, Offset direction, Color color) {
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    const double arrowSize = 5.0;
    final perp = Offset(-direction.dy, direction.dx);
    
    final p1 = center + direction * arrowSize;
    final p2 = center - direction * (arrowSize / 2) + perp * (arrowSize / 1.5);
    final p3 = center - direction * (arrowSize / 2) - perp * (arrowSize / 1.5);
    
    final arrowPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) {
    return oldDelegate.path != path || 
           oldDelegate.coordinates != coordinates ||
           oldDelegate.pathColor != pathColor ||
           oldDelegate.highlightColor != highlightColor ||
           oldDelegate.animatedPlayerPosition != animatedPlayerPosition;
  }
}
