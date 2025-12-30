import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:maze/maze.dart';
import 'tile_renderer.dart';
import 'solution_path_draw.dart';

/// A class for rendering MazeArray instances to PNG images.
/// 
/// This class coordinates the rendering of a complete maze by using
/// a [TileRenderer] to draw individual tiles. Optionally draws a solution
/// path on top of the maze if a solution file is provided.
class MazeRenderer {
  final MazeArray mazeArray;
  final TileManager tileManager;
  final TileRenderer tileRenderer;
  final String? solutionFile;
  final img.Color pathColor;

  MazeRenderer(
    this.mazeArray,
    this.tileManager,
    this.tileRenderer, {
    this.solutionFile,
    img.Color? pathColor,
  }) : pathColor = pathColor ?? img.ColorRgba8(255, 0, 0, 255); // Red by default

  /// Renders the maze to a PNG image and returns the bytes.
  /// 
  /// If [solutionFile] was provided in the constructor, the solution path
  /// will be drawn on top of the maze.
  Uint8List renderToPng() {
    final tileSize = tileRenderer.tileSize;
    final width = mazeArray.cols * tileSize;
    final height = mazeArray.rows * tileSize;
    
    final image = img.Image(width: width, height: height);
    
    // Fill with white background (tiles have transparent backgrounds)
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
    
    // Render each tile using the tile renderer
    for (int row = 0; row < mazeArray.rows; row++) {
      for (int col = 0; col < mazeArray.cols; col++) {
        final tile = mazeArray.tiles[row][col];
        final x = col * tileSize;
        final y = row * tileSize;
        tileRenderer.renderTile(image, tile.id, x, y);
      }
    }
    
    // Draw solution path if provided
    if (solutionFile != null) {
      final path = _parseSolutionFile(solutionFile!);
      if (path.isNotEmpty) {
        print('Drawing solution path with ${path.length} steps');
        final pathDrawer = SolutionPathDraw(
          image: image,
          tileSize: tileSize,
          pathColor: pathColor,
          tileManager: tileManager,
          mazeArray: mazeArray,
        );
        pathDrawer.drawPath(path);
      }
    }
    
    // Encode to PNG
    return Uint8List.fromList(img.encodePng(image));
  }

  /// Parses a solution file and returns a list of tile locations.
  List<TileLocation> _parseSolutionFile(String filePath) {
    print('Parsing solution file: $filePath');
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        print('Warning: Solution file not found: $filePath');
        return [];
      }

      final content = file.readAsStringSync().trim();
      if (content.isEmpty) {
        return [];
      }

      // Parse the solution format: each line is "<step>: <row>,<col>"
      final positions = <TileLocation>[];
      final lines = content.split('\n');
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        // Split by colon to separate step number from coordinates
        final parts = line.split(':');
        if (parts.length < 2) continue;
        
        // Get the coordinates part (after the colon)
        final coords = parts[1].trim().split(',');
        
        if (coords.length >= 2) {
          final row = int.tryParse(coords[0].trim());
          final col = int.tryParse(coords[1].trim());
          if (row != null && col != null) {
            positions.add((row: row, col: col));
          }
        }
      }

      print('Parsed ${positions.length} positions from solution file'); 
      return positions;
    } catch (e) {
      print('Error parsing solution file: $e');
      return [];
    }
  }
}
