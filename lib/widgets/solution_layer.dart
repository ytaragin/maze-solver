import 'package:flutter/material.dart';
import 'package:maze/maze.dart';
import '../models/maze.dart';
import '../models/maze_path.dart';
import '../utils/maze_coordinates.dart';
import 'path_overlay_widget.dart';

/// Widget for displaying the solution path overlay
class SolutionLayer extends StatefulWidget {
  final Maze maze;
  final MazeCoordinates coordinates;

  const SolutionLayer({
    super.key,
    required this.maze,
    required this.coordinates,
  });

  @override
  SolutionLayerState createState() => SolutionLayerState();
}

class SolutionLayerState extends State<SolutionLayer> {
  MazePath? _solutionPath;

  @override
  void initState() {
    super.initState();
    // TODO: Generate solution path here
  }

  void generateSolution() {
    // TODO: Implement solution generation logic
    // This will use the maze to find the solution path
    setState(() {
      // _solutionPath = ...
    });
  }

  void clearSolution() {
    setState(() {
      _solutionPath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: widget.coordinates.getMazeSize(
          widget.maze.mazeArray.rows,
          widget.maze.mazeArray.cols,
        ),
        painter: _solutionPath != null
            ? PathPainter(
                mazePath: _solutionPath!,
                coordinates: widget.coordinates,
                pathColor: Colors.green,
                highlightColor: Colors.lightGreen,
              )
            : null,
      ),
    );
  }
}
