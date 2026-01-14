import 'package:maze_image/maze_image.dart';

void main() {
  // Create a tile renderer pointing to the tiles folder
  final renderer = TileRenderer(tilesFolder: '../../tiles');

  // Example 1: Load a single tile
  print('Loading tile 1...');
  final tile1 = renderer.getTileImage(1);
  if (tile1 != null) {
    print('Tile 1 loaded: ${tile1.width}x${tile1.height} pixels');
  } else {
    print('Tile 1 not found');
  }

  // Example 2: Preload all tiles
  print('\nPreloading all tiles...');
  final count = renderer.preloadAllTiles();
  print('Loaded $count tiles');
  print('Cache size: ${renderer.cacheSize}');

  // Example 3: Load multiple specific tiles
  print('\nLoading specific tiles:');
  for (int id in [1, 2, 3, 4, 5]) {
    final tile = renderer.getTileImage(id);
    if (tile != null) {
      print('  Variant$id.png: ${tile.width}x${tile.height}');
    } else {
      print('  Variant$id.png: not found');
    }
  }

  // Example 4: Clear cache
  print('\nClearing cache...');
  renderer.clearCache();
  print('Cache size after clear: ${renderer.cacheSize}');
}
