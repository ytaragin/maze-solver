import 'package:flutter/material.dart';
import '../models/maze.dart';
import '../widgets/interactive_maze_widget.dart';

/// Page for solving an existing maze.
/// Can receive a [Maze] directly (from creation mode) or load from a CSV asset path.
class MazeSolverPage extends StatelessWidget {
  final Maze? maze;
  final String? csvPath;

  const MazeSolverPage({super.key, this.maze, this.csvPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Maze Solver'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/create');
            },
            icon: const Icon(Icons.edit),
            label: const Text('Create'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InteractiveMaze(
                csvPath: csvPath ?? 'mazes/maze251103v2.csv',
                tileSize: 40.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
