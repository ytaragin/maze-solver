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
  late List<MazeLocation> _solutionPath;
  int _depth = 1;

  @override
  void initState() {
    super.initState();
    generateSolution();

  }

  void generateSolution() {
    setState(() {
      final graph = widget.maze.graph;
      final solver = MazeShortestPath(graph);
      final res = solver.findPath();
      if (res.pathFound) {
        _solutionPath = res.path;
      } else {
        _solutionPath = [];
      }
    });
  }

  void setFullPath() {
    setState(() {
      _depth = _solutionPath.length;
    });
  }

  void advanceStep() {
    setState(() {
      if (_depth < _solutionPath.length) {
        _depth++;
      }
    });
  }

  void clearSolution() {
    setState(() {
      _depth = 1;
    });
  }

  List<MazeLocation> getSolutionPath() {
    if (_depth < 0 || _depth > _solutionPath.length) {
      return _solutionPath;
    }
    return _solutionPath.sublist(0, _depth);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: widget.coordinates.getMazeSize(
          widget.maze.mazeArray.rows,
          widget.maze.mazeArray.cols,
        ),
        painter: PathPainter(
          path: getSolutionPath(),
          coordinates: widget.coordinates,
          pathColor: Colors.green,
          highlightColor: Colors.lightGreen,
        ),
      ),
    );
  }
}
