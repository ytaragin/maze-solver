import 'dart:io';
import 'package:args/args.dart';
import 'package:maze/maze.dart';
import 'package:maze/maze_io.dart';
import 'package:maze_image/maze_image.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Display usage information')
    ..addFlag('solve', abbr: 's', negatable: false, help: 'Solve the maze and output solution')
    ..addFlag('info', abbr: 'i', negatable: false, help: 'Display maze information and statistics')
    ..addFlag('graph', abbr: 'g', negatable: false, help: 'Display maze graph')
    ..addFlag('render', abbr: 'r', negatable: false, help: 'Render maze to PNG image')
    ..addOption('output', abbr: 'o', help: 'Output file (default: <input>.sol for solve, <input>.png for render)')
    ..addOption('solution', help: 'Solution file to overlay on rendered image (default: <input>.sol)')
    ..addOption('tiles', abbr: 't', help: 'Path to tiles folder for rendering', defaultsTo: 'tiles')
    ..addOption('tile-size', help: 'Size of each tile in pixels', defaultsTo: '50');

  try {
    final results = parser.parse(args);

    if (results['help'] || results.rest.isEmpty) {
      printUsage(parser);
      exit(results['help'] ? 0 : 1);
    }

    final csvPath = results.rest[0];
    
    // Load the maze
    final maze = await loadMaze(csvPath);
    
    // Get base filename without extension for default output names
    final baseFilename = path.withoutExtension(csvPath);
    
    // Execute requested actions
    if (results['info']) {
      displayMazeInfo(maze);
    }
    
    if (results['graph']) {
      displayMazeGraph(maze);
    }
    
    String? generatedSolutionFile;
    if (results['solve']) {
      final outputFile = results['output'] as String? ?? '$baseFilename.sol';
      solveMaze(maze, outputFile);
      generatedSolutionFile = outputFile;
    }
    
    if (results['render']) {
      final outputFile = results['output'] as String? ?? '$baseFilename.png';
      // If solve was run, use the generated solution file; otherwise use the specified/default solution file
      final solutionFile = generatedSolutionFile ?? (results['solution'] as String? ?? '$baseFilename.sol');
      final tilesPath = results['tiles'] as String;
      final tileSize = int.parse(results['tile-size'] as String);
      renderMaze(maze, outputFile, tilesPath, tileSize, solutionFile);
    }
    
    // If no specific flags, show everything (default behavior)
    if (!results['info'] && !results['graph'] && !results['solve'] && !results['render']) {
      displayMazeInfo(maze);
      displayMazeGraph(maze);
      solveMaze(maze, '$baseFilename.sol');
    }
    
  } on FormatException catch (e) {
    print('Error: ${e.message}\n');
    printUsage(parser);
    exit(1);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void printUsage(ArgParser parser) {
  print('Maze Tool - Analyze and solve mazes from CSV files\n');
  print('Usage: dart run maze_tool [options] <path_to_csv_file>\n');
  print('Options:');
  print(parser.usage);
  print('\nExamples:');
  print('  dart run maze_tool mazes/small.csv');
  print('  dart run maze_tool -s -o solution.txt mazes/maze1.csv');
  print('  dart run maze_tool --info --graph mazes/maze1.csv');
  print('  dart run maze_tool -r -o output.png mazes/maze1.csv');
  print('  dart run maze_tool -r --tiles tiles --tile-size 64 mazes/maze1.csv');
}

Future<MazeArray> loadMaze(String csvPath) async {
  print('Loading maze from: $csvPath');
  return await MazeArrayIO.fromCsv(csvPath);
}

void displayMazeInfo(MazeArray maze) {
  print('\n=== Maze Information ===');
  print('Size: ${maze.rows} rows x ${maze.cols} columns');
  print('Total tiles: ${maze.rows * maze.cols}');

  final uniqueTiles = maze.getUniqueTiles();
  print('Unique tile types: ${uniqueTiles.length}');

  print('\n=== Tile Distribution ===');
  final tileCount = <Tile, int>{};
  for (var row in maze.tiles) {
    for (var tile in row) {
      tileCount[tile] = (tileCount[tile] ?? 0) + 1;
    }
  }

  for (var entry in tileCount.entries) {
    print('${entry.key}: ${entry.value} occurrences');
  }

  print('\n=== Maze Array ===');
  maze.printMaze(stdout);
}

void displayMazeGraph(MazeArray maze) {
  final graph = MazeGraph(maze);
  graph.printGraph(stdout);
}

void solveMaze(MazeArray maze, String outputPath) {
  final graph = MazeGraph(maze);
  final solver = MazeShortestPath(graph);
  final res = solver.findPath();
  
  if (res.pathFound) {
    final outSol = StringBuffer();
    var counter = 1;
    for (var p in res.path) {
      outSol.writeln('$counter: ${p.row},${p.col}');
      counter++;
    }
    final File solFile = File(outputPath);
    solFile.writeAsStringSync(outSol.toString());
    print('\n=== Solution ===');
    print('Path found! Solution saved to: $outputPath');
    print('Path length: ${res.path.length} steps');
  } else {
    print('\n=== Solution ===');
    print('No path found!');
  }
}

void renderMaze(MazeArray maze, String outputPath, String tilesPath, int tileSize, String solutionFile) {
  print('\n=== Rendering Maze ===');
  print('Tiles folder: $tilesPath');
  print('Tile size: ${tileSize}px');
  
  // Check if solution file exists
  final hasSolution = File(solutionFile).existsSync();
  if (hasSolution) {
    print('Solution file: $solutionFile');
  }
  
  try {
    final tileRenderer = TileRenderer(
      tilesFolder: tilesPath,
      tileSize: tileSize,
    );
    
    // Preload tiles for better performance
    final tilesLoaded = tileRenderer.preloadAllTiles();
    print('Loaded $tilesLoaded tile images');
    
    final tileManager = TileManager.withVariants();
    final mazeRenderer = MazeRenderer(
      maze, 
      tileManager, 
      tileRenderer,
      solutionFile: hasSolution ? solutionFile : null,
    );
    
    final pngBytes = mazeRenderer.renderToPng();
    File(outputPath).writeAsBytesSync(pngBytes);
    
    print('Maze rendered successfully!');
    print('Output saved to: $outputPath');
    print('Image size: ${maze.cols * tileSize}x${maze.rows * tileSize} pixels');
  } catch (e) {
    print('Error rendering maze: $e');
    exit(1);
  }
}
