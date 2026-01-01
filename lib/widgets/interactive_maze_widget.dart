import 'package:flutter/material.dart';
import '../models/maze.dart';
import 'path_overlay_widget.dart';

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

    return Stack(
      children: [
        Column(
          children: [
            // Maze with path overlay
            PathOverlayWidget(
              maze: _maze!,
              tileSize: widget.tileSize,
            ),
          ],
        ),
        // Version number
        Positioned(
          bottom: 8,
          right: 8,
          child: Text(
            'v0.1.0',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
