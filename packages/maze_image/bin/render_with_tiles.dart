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
  
  print('Rendering maze: ${mazeArray.rows} rows x ${mazeArray.cols} columns');
  
  // Example 1: Simple colored rendering (no tile images)
  print('\n1. Creating simple colored maze...');
  final simpleTileRenderer = TileRenderer(
    tilesFolder: '../../tiles',
    tileSize: 48,
  );
  
  final simpleRenderer = MazeRenderer(
    mazeArray,
    tileManager,
    simpleTileRenderer,
  );
  
  final simplePng = simpleRenderer.renderToPng();
  await File('maze_simple.png').writeAsBytes(simplePng);
  print('   Saved to maze_simple.png');
  
  // Example 2: Rendering with actual tile PNG images
  print('\n2. Creating maze with actual tile images...');
  final tileRenderer = TileRenderer(
    tilesFolder: '../../tiles',
    tileSize: 50, // Match the actual tile size
  );
  
  // Preload tiles for better performance
  final tilesLoaded = tileRenderer.preloadAllTiles();
  print('   Preloaded $tilesLoaded tile images');
  
  final imageRenderer = MazeRenderer(
    mazeArray,
    tileManager,
    tileRenderer,
  );
  
  final imagePng = imageRenderer.renderToPng();
  await File('maze_with_tiles.png').writeAsBytes(imagePng);
  print('   Saved to maze_with_tiles.png');
  
  print('\nDone! Generated 2 maze images.');
}
