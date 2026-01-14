import 'package:flutter/material.dart';
import '../models/maze.dart';
import '../utils/maze_coordinates.dart';
import 'csv_maze_widget.dart';
import 'path_overlay_widget.dart';
import 'solution_layer.dart';

/// Interactive Maze Widget with path building
class InteractiveMaze extends StatefulWidget {
  final String csvPath;
  final double tileSize;

  const InteractiveMaze({
    super.key,
    required this.csvPath,
    this.tileSize = 32.0,
  });

  @override
  State<InteractiveMaze> createState() => _InteractiveMazeState();
}

class _InteractiveMazeState extends State<InteractiveMaze> {
  Maze? _maze;
  bool _isLoading = true;
  String? _errorMessage;
  int _pathLength = 0;
  int _coinsCollected = 0;
  final GlobalKey<PathOverlayState> _pathOverlayKey = GlobalKey();
  final GlobalKey<SolutionLayerState> _solutionLayerKey = GlobalKey();

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

    final coordinates = MazeCoordinates(tileSize: widget.tileSize);

    return Stack(
      children: [
        Column(
          children: [
            // Controls
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _pathOverlayKey.currentState?.clearPath(),
                  child: const Text('Clear Path'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _solutionLayerKey.currentState?.advanceStep(),
                  child: const Text('Advance Solution'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _solutionLayerKey.currentState?.setFullPath(),
                  child: const Text('Full Solution'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _solutionLayerKey.currentState?.clearSolution(),
                  child: const Text('Clear Solution'),
                ),
                const SizedBox(width: 8),
                Text('Steps: $_pathLength, Coins: $_coinsCollected'),
              ],
            ),
            const SizedBox(height: 8),
            
            // Stack maze rendering with path overlay
            Stack(
              children: [
                // Background maze tiles
                CsvMaze(
                  maze: _maze!,
                  coordinates: coordinates,
                ),
                
                // Solution path overlay
                SolutionLayer(
                  key: _solutionLayerKey,
                  maze: _maze!,
                  coordinates: coordinates,
                ),
                
                // Path overlay with interaction (drawn on top)
                PathOverlay(
                  key: _pathOverlayKey,
                  maze: _maze!,
                  coordinates: coordinates,
                  onPathChanged: (path) {
                    setState(() {
                      _pathLength = path.pathLength;
                      _coinsCollected = path.coinsCollected;
                    });
                  },
                ),
              ],
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
