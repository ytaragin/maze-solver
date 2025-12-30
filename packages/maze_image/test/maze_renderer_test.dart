import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:maze/maze.dart';
import 'package:maze_image/maze_image.dart';
import 'dart:io';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('maze_renderer_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MazeRenderer', () {
    test('creates a PNG from a simple maze', () {
      // Create a simple 2x2 maze
      final tiles = [
        [
          Tile.variant(1, SpotType.path, {Direction.east, Direction.south}),
          Tile.variant(2, SpotType.path, {Direction.west, Direction.south}),
        ],
        [
          Tile.variant(3, SpotType.path, {Direction.north, Direction.east}),
          Tile.variant(4, SpotType.path, {Direction.north, Direction.west}),
        ],
      ];
      
      final mazeArray = MazeArray(tiles: tiles);
      final tileManager = TileManager.withVariants();
      final tileRenderer = TileRenderer(tilesFolder: tempDir.path, tileSize: 32);
      
      final renderer = MazeRenderer(mazeArray, tileManager, tileRenderer);
      final pngBytes = renderer.renderToPng();
      
      expect(pngBytes, isA<Uint8List>());
      expect(pngBytes.length, greaterThan(0));
      
      // Verify PNG header (starts with PNG signature)
      expect(pngBytes[0], equals(0x89));
      expect(pngBytes[1], equals(0x50)); // 'P'
      expect(pngBytes[2], equals(0x4E)); // 'N'
      expect(pngBytes[3], equals(0x47)); // 'G'
    });

    test('handles custom tile sizes', () {
      final tiles = [
        [Tile.variant(1, SpotType.path, {Direction.east})],
      ];
      
      final mazeArray = MazeArray(tiles: tiles);
      final tileManager = TileManager.withVariants();
      final tileRenderer = TileRenderer(tilesFolder: tempDir.path, tileSize: 64);
      
      final renderer = MazeRenderer(mazeArray, tileManager, tileRenderer);
      final pngBytes = renderer.renderToPng();
      
      expect(pngBytes, isA<Uint8List>());
      expect(pngBytes.length, greaterThan(0));
    });
  });
}
