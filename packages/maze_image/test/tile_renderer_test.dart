import 'dart:io';
import 'package:test/test.dart';
import 'package:image/image.dart' as img;
import 'package:maze_image/maze_image.dart';

void main() {
  group('TileRenderer', () {
    late Directory tempDir;
    late TileRenderer renderer;

    setUp(() {
      // Create a temporary directory for test tiles
      tempDir = Directory.systemTemp.createTempSync('tile_renderer_test_');
      renderer = TileRenderer(tilesFolder: tempDir.path, tileSize: 32);
    });

    tearDown(() {
      // Clean up temporary directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns null for non-existent tile', () {
      final image = renderer.getTileImage(999);
      expect(image, isNull);
    });

    test('loads a tile image successfully', () {
      // Create a simple test PNG
      final testImage = img.Image(width: 32, height: 32);
      img.fill(testImage, color: img.ColorRgba8(255, 0, 0, 255));
      
      final pngBytes = img.encodePng(testImage);
      final file = File('${tempDir.path}/Variant1.png');
      file.writeAsBytesSync(pngBytes);

      // Load the tile
      final loadedImage = renderer.getTileImage(1);
      
      expect(loadedImage, isNotNull);
      expect(loadedImage!.width, equals(32));
      expect(loadedImage.height, equals(32));
    });

    test('caches loaded images', () {
      // Create a test PNG
      final testImage = img.Image(width: 32, height: 32);
      final pngBytes = img.encodePng(testImage);
      final file = File('${tempDir.path}/Variant5.png');
      file.writeAsBytesSync(pngBytes);

      // Load twice
      final image1 = renderer.getTileImage(5);
      final image2 = renderer.getTileImage(5);

      expect(image1, isNotNull);
      expect(image2, isNotNull);
      expect(identical(image1, image2), isTrue); // Same object from cache
      expect(renderer.cacheSize, equals(1));
    });

    test('preloads all tiles from folder', () {
      // Create multiple test PNGs
      for (int i = 1; i <= 5; i++) {
        final testImage = img.Image(width: 32, height: 32);
        final pngBytes = img.encodePng(testImage);
        final file = File('${tempDir.path}/Variant$i.png');
        file.writeAsBytesSync(pngBytes);
      }

      final count = renderer.preloadAllTiles();
      
      expect(count, equals(5));
      expect(renderer.cacheSize, equals(5));
    });

    test('clears cache', () {
      // Create and load a test PNG
      final testImage = img.Image(width: 32, height: 32);
      final pngBytes = img.encodePng(testImage);
      final file = File('${tempDir.path}/Variant1.png');
      file.writeAsBytesSync(pngBytes);

      renderer.getTileImage(1);
      expect(renderer.cacheSize, equals(1));

      renderer.clearCache();
      expect(renderer.cacheSize, equals(0));
    });

    test('handles invalid PNG files gracefully', () {
      // Create an invalid PNG file
      final file = File('${tempDir.path}/Variant99.png');
      file.writeAsStringSync('This is not a valid PNG');

      final image = renderer.getTileImage(99);
      expect(image, isNull);
    });
  });
}
