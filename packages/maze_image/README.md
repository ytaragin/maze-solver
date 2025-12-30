# maze_image

A Dart library for converting maze data structures and solutions into PNG images.

## Features

- **MazeRenderer**: Render MazeArray to PNG images
- **TileRenderer**: Load and manage tile PNG images from a folder
- Render mazes with actual tile images
- Efficient image caching for better performance
- Customizable tile sizes

## Usage

### Rendering a maze

```dart
import 'package:maze_image/maze_image.dart';

// Create a tile renderer that loads PNG files from a folder
final tileRenderer = TileRenderer(
  tilesFolder: 'path/to/tiles',
  tileSize: 50,
);

// Optionally preload all tiles for better performance
tileRenderer.preloadAllTiles();

// Create a maze renderer
final renderer = MazeRenderer(mazeArray, tileManager, tileRenderer);

// Generate PNG with actual tile images
final pngBytes = renderer.renderToPng();
File('maze.png').writeAsBytesSync(pngBytes);
```

### Using TileRenderer standalone

```dart
// Create a tile renderer
final renderer = TileRenderer(
  tilesFolder: 'tiles',
  tileSize: 32,
);

// Load a specific tile (e.g., Variant1.png)
final tileImage = renderer.getTileImage(1);

// Render a tile onto an existing image
final targetImage = img.Image(width: 100, height: 100);
renderer.renderTile(targetImage, 1, 0, 0);  // Render tile ID 1 at position (0, 0)

// Preload all tiles
final count = renderer.preloadAllTiles();
print('Loaded $count tiles');

// Check cache size
print('Cache size: ${renderer.cacheSize}');

// Clear cache to free memory
renderer.clearCache();
```

## Tile Image Format

The `TileRenderer` expects PNG files in the following format:
- File naming: `VariantX.png` where X is the tile ID
- Example: `Variant1.png`, `Variant2.png`, etc.
- All files should be in the specified tiles folder
