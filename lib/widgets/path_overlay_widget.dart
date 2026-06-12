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

      // Pop the last location from the current list to update the blue path line
      setState(() {
        currentFullDisplayPath.removeAt(i);
        // We temporarily create a path with one fewer element for visual feedback
        // This is safe because we're just updating the visual 'userPath'
        _mazePath = _mazePath.cloneWithUserPath(currentFullDisplayPath);
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

    // Draw current moving segment if any
    if (animatedPlayerPosition != null && path.isNotEmpty) {
      final lastPathPoint = coordinates.locationToCenter(path.last);
      canvas.drawLine(lastPathPoint, animatedPlayerPosition!, linePaint);
    }

    // Draw dots at each point
    for (final location in path) {
      final center = coordinates.locationToCenter(location);
      canvas.drawCircle(center, 6.0, dotPaint);
    }

    // Highlight the latest point
    final lastCenter = animatedPlayerPosition ?? coordinates.locationToCenter(path.last);
    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(lastCenter, 8.0, highlightPaint);
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
