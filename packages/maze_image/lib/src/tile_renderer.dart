import 'dart:io';
import 'package:image/image.dart' as img;

/// A class for loading and rendering individual tile images from PNG files.
/// 
/// This class loads tile images from a folder containing files named
/// VariantX.png where X is the tile ID.
class TileRenderer {
  final String tilesFolder;
  
  /// Cache of loaded images to avoid repeated file I/O
  final Map<int, img.Image> _imageCache = {};

  /// Size of each tile in pixels
  final int tileSize;

  TileRenderer({
    required this.tilesFolder,
    this.tileSize = 32,
  });

  /// Gets the image for a tile with the given ID.
  /// 
  /// Returns the loaded PNG image, or null if the file doesn't exist
  /// or cannot be loaded. Results are cached for performance.
  img.Image? getTileImage(int tileId) {
    // Check cache first
    if (_imageCache.containsKey(tileId)) {
      return _imageCache[tileId];
    }

    // Construct the file path
    final filePath = '$tilesFolder/Variant$tileId.png';
    final file = File(filePath);

    // Check if file exists
    if (!file.existsSync()) {
      return null;
    }

    try {
      // Load and decode the PNG
      final bytes = file.readAsBytesSync();
      final image = img.decodePng(bytes);

      // Cache the result
      if (image != null) {
        _imageCache[tileId] = image;
      }

      return image;
    } catch (e) {
      // Return null if there's an error loading the image
      return null;
    }
  }

  /// Preloads all tile images from the tiles folder.
  /// 
  /// This can be useful to load all images at startup rather than
  /// on-demand. Returns the number of images successfully loaded.
  int preloadAllTiles() {
    final dir = Directory(tilesFolder);
    if (!dir.existsSync()) {
      return 0;
    }

    int loadedCount = 0;
    final files = dir.listSync();

    for (final file in files) {
      if (file is File && file.path.endsWith('.png')) {
        // Extract tile ID from filename (VariantX.png)
        final fileName = file.path.split('/').last;
        final match = RegExp(r'Variant(\d+)\.png').firstMatch(fileName);

        if (match != null) {
          final tileId = int.parse(match.group(1)!);
          if (getTileImage(tileId) != null) {
            loadedCount++;
          }
        }
      }
    }

    return loadedCount;
  }

  /// Clears the image cache to free up memory.
  void clearCache() {
    _imageCache.clear();
  }

  /// Gets the number of cached images.
  int get cacheSize => _imageCache.length;

  /// Renders a tile onto the target image at the specified position.
  /// 
  /// Loads the tile image from the tiles folder and composites it onto
  /// the target image. Returns true if successful, false if the tile
  /// image could not be loaded.
  bool renderTile(img.Image targetImage, int tileId, int x, int y) {
    final tileImage = getTileImage(tileId);
    if (tileImage == null) {
      return false;
    }
    
    // Resize if necessary and composite onto target
    final resized = tileImage.width != tileSize || tileImage.height != tileSize
        ? img.copyResize(tileImage, width: tileSize, height: tileSize)
        : tileImage;
    
    img.compositeImage(targetImage, resized, dstX: x, dstY: y);
    return true;
  }
}
