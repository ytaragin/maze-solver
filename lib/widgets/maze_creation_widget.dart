import 'package:flutter/material.dart';
import 'package:maze/maze.dart';
import '../models/maze.dart';
import 'tile_palette_widget.dart';
import 'creation_grid_widget.dart';

/// Main orchestrator widget for maze creation mode.
/// Manages the maze state, selected tile, and coordinates between
/// the tile palette and the creation grid.
class MazeCreationWidget extends StatefulWidget {
  final int rows;
  final int cols;

  const MazeCreationWidget({
    super.key,
    required this.rows,
    required this.cols,
  });

  @override
  State<MazeCreationWidget> createState() => _MazeCreationWidgetState();
}

class _MazeCreationWidgetState extends State<MazeCreationWidget> {
  final TileManager _tileManager = TileManager.withVariants();
  late Maze _maze;
  int? _selectedTileId;

  /// Sentinel tile ID representing an empty/unfilled cell.
  static const int emptyTileId = 0;

  @override
  void initState() {
    super.initState();
    final emptyTile = _tileManager.getTile(emptyTileId);
    final tiles = List.generate(
      widget.rows,
      (_) => List.filled(widget.cols, emptyTile),
    );
    _maze = Maze(mazeArray: MazeArray(tiles: tiles), csvPath: 'created');
  }

  void _onTileSelected(int tileId) {
    setState(() {
      _selectedTileId = tileId;
    });
  }

  void _onCellTap(({int row, int col}) cell) {
    if (_selectedTileId == null) return;
    setState(() {
      print('Tapped cell: (${cell.row}, ${cell.col}) with tile ID: $_selectedTileId');
      _maze.mazeArray.tiles[cell.row][cell.col] =
          _tileManager.getTile(_selectedTileId!);
      _rebuildMaze();
    });
  }

  void _onCellClear(({int row, int col}) cell) {
    setState(() {
      _maze.mazeArray.tiles[cell.row][cell.col] =
          _tileManager.getTile(emptyTileId);
      _rebuildMaze();
    });
  }

  /// Whether every cell has been filled (no tile with ID 0).
  bool get isGridComplete => _maze.mazeArray.tiles
      .every((row) => row.every((tile) => tile.id != emptyTileId));

  /// Rebuild the Maze wrapper to get a fresh MazeGraph.
  void _rebuildMaze() {
    _maze = Maze(mazeArray: _maze.mazeArray, csvPath: 'created');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tile palette sidebar
        TilePalette(
          selectedTileId: _selectedTileId,
          onTileSelected: _onTileSelected,
        ),
        // Creation grid (takes remaining space)
        Expanded(
          child: CreationGrid(
            mazeArray: _maze.mazeArray,
            selectedTileId: _selectedTileId,
            onCellTap: _onCellTap,
            onCellClear: _onCellClear,
          ),
        ),
      ],
    );
  }
}
