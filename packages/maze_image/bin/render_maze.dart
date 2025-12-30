import 'dart:io';
import 'package:maze/maze.dart';
import 'package:maze_image/maze_image.dart';

void main() async {
  // Load a maze from CSV file
  final csvFile = File('../../mazes/small.csv');
  final csvContent = await csvFile.readAsString();
  final mazeArray = MazeArray.fromCsvString(csvContent);
  
  // Create tile manager
  final tileManager = TileManager.withVariants();
  
  // Create tile renderer
  final tileRenderer = TileRenderer(
    tilesFolder: '../../tiles',
    tileSize: 48, // Larger tiles for better visibility
  );
  
  // Create maze renderer
  final renderer = MazeRenderer(
    mazeArray,
    tileManager,
    tileRenderer,
  );
  
  // Render to PNG
  final pngBytes = renderer.renderToPng();
  
  // Save to file
  final outputFile = File('maze_output.png');
  await outputFile.writeAsBytes(pngBytes);
  
  print('Maze rendered to ${outputFile.path}');
  print('Maze size: ${mazeArray.rows} rows x ${mazeArray.cols} columns');
}
