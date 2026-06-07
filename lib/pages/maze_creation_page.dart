import 'package:flutter/material.dart';
import '../widgets/maze_creation_widget.dart';

/// Page for creating a new maze.
/// Shows a dimension dialog on first load, then the creation widget.
class MazeCreationPage extends StatefulWidget {
  const MazeCreationPage({super.key});

  @override
  State<MazeCreationPage> createState() => _MazeCreationPageState();
}

class _MazeCreationPageState extends State<MazeCreationPage> {
  int? _rows;
  int? _cols;

  @override
  void initState() {
    super.initState();
    // Show dimension dialog after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDimensionDialog();
    });
  }

  Future<void> _showDimensionDialog() async {
    final rowsController = TextEditingController(text: '5');
    final colsController = TextEditingController(text: '5');

    final result = await showDialog<({int rows, int cols})>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Maze'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: rowsController,
                decoration: const InputDecoration(labelText: 'Rows'),
                keyboardType: TextInputType.number,
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: colsController,
                decoration: const InputDecoration(labelText: 'Columns'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final rows = int.tryParse(rowsController.text) ?? 5;
                final cols = int.tryParse(colsController.text) ?? 5;
                Navigator.of(context).pop((rows: rows, cols: cols));
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _rows = result.rows;
        _cols = result.cols;
      });
    } else {
      // User cancelled — go back to solver.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/solve');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_rows != null ? 'Maze Creator ($_rows × $_cols)' : 'Maze Creator'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/solve');
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Solve'),
          ),
        ],
      ),
      body: _rows != null && _cols != null
          ? MazeCreationWidget(rows: _rows!, cols: _cols!)
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
