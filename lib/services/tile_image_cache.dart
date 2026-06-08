import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// Centralized cache for tile images loaded from the asset bundle.
/// Extends ChangeNotifier so consumers can react when loading completes.
class TileImageCache extends ChangeNotifier {
  final Map<int, ui.Image> _images = {};
  bool _isReady = false;

  bool get isReady => _isReady;

  /// Look up a tile image by ID. Returns null if not loaded or missing.
  ui.Image? imageFor(int id) => _images[id];

  static const List<int> _baseShapeIds = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  static const List<int> _specialIds = [41, 42, 43];

  static List<int> get _allTileIds => [
        for (final base in _baseShapeIds) ...[
          base,
          base + 10,
          base + 20,
          base + 30,
        ],
        ..._specialIds,
      ];

  /// Load all tile variant images from the asset bundle.
  Future<void> loadAll() async {
    for (final id in _allTileIds) {
      try {
        final data = await rootBundle.load('tiles/Variant$id.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _images[id] = frame.image;
      } catch (_) {
        // Skip tiles with missing images
      }
    }
    _isReady = true;
    notifyListeners();
  }
}
