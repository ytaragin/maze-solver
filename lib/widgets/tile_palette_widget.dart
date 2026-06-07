import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

/// Sidebar widget displaying available tiles grouped by type.
/// User selects a type (path/coin/start/end), then picks a shape.
/// Special tiles (41-43) are always visible below.
class TilePalette extends StatefulWidget {
  final int? selectedTileId;
  final ValueChanged<int> onTileSelected;

  const TilePalette({
    super.key,
    required this.selectedTileId,
    required this.onTileSelected,
  });

  @override
  State<TilePalette> createState() => _TilePaletteState();
}

enum TileType {
  path(label: 'Path', offset: 0),
  coin(label: 'Coin', offset: 10),
  start(label: 'Start', offset: 20),
  end(label: 'End', offset: 30);

  final String label;
  final int offset;
  const TileType({required this.label, required this.offset});
}

class _TilePaletteState extends State<TilePalette> {
  TileType _selectedType = TileType.path;
  final Map<int, ui.Image> _tileImages = {};
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    for (final id in _allTileIds) {
      try {
        final data = await rootBundle.load('tiles/Variant$id.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        _tileImages[id] = frame.image;
      } catch (_) {
        // Skip tiles with missing images
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int _resolvedId(int baseId) => baseId + _selectedType.offset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type selector at top
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SegmentedButton<TileType>(
                    segments: TileType.values
                        .map((t) => ButtonSegment(
                              value: t,
                              label: Text(t.label,
                                  style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                    selected: {_selectedType},
                    onSelectionChanged: (selected) {
                      setState(() => _selectedType = selected.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Shape grid (base 1-10, resolved by type)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '${_selectedType.label} Tiles',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _baseShapeIds.map((baseId) {
                      final tileId = _resolvedId(baseId);
                      return _TileButton(
                        tileId: tileId,
                        image: _tileImages[tileId],
                        isSelected: widget.selectedTileId == tileId,
                        onTap: () => widget.onTileSelected(tileId),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                // Special tiles (41-43) — don't change with type
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Special',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: _specialIds.map((id) {
                      return _TileButton(
                        tileId: id,
                        image: _tileImages[id],
                        isSelected: widget.selectedTileId == id,
                        onTap: () => widget.onTileSelected(id),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final int tileId;
  final ui.Image? image;
  final bool isSelected;
  final VoidCallback onTap;

  const _TileButton({
    required this.tileId,
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.0,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: image != null
            ? RawImage(image: image, fit: BoxFit.contain)
            : Center(
                child: Text(
                  '$tileId',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
      ),
    );
  }
}
