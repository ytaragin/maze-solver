import 'spot_type.dart';

/// Represents a single tile with its properties.
class Tile {
  final int id;
  final SpotType type;

  final Set<Direction> directions;

  const Tile({
    required this.id,
    required this.type,
    // a set of possible directions
    required this.directions,
  });

  /// Creates a tile with a variant number.
  /// Example: Tile.variant(1) creates a tile with imagePath 'tiles/Variant1.png'
  factory Tile.variant(
    int variantNumber,
    SpotType type,
    Set<Direction> directions,
  ) {
    return Tile(id: variantNumber, type: type, directions: directions);
  }

  /// Returns a 3x3 array of SpotTypes representing the tile's layout.
  ///
  /// The center (1,1) is the tile's type.
  /// All corners are walls.
  /// Edges are paths if the corresponding direction is in the tile's directions, otherwise walls.
  ///
  /// Layout:
  /// ```
  /// [0,0] [0,1]     [0,2]
  ///       north
  /// [1,0] [1,1]     [1,2]
  /// west  center    east
  /// [2,0] [2,1]     [2,2]
  ///       south
  /// ```
  List<List<SpotType>> getFullSpotArray() {
    return [
      [
        SpotType.wall, // top-left corner
        directions.contains(Direction.north)
            ? SpotType.path
            : SpotType.wall, // north edge
        SpotType.wall, // top-right corner
      ],
      [
        directions.contains(Direction.west)
            ? SpotType.path
            : SpotType.wall, // west edge
        type, // center
        directions.contains(Direction.east)
            ? SpotType.path
            : SpotType.wall, // east edge
      ],
      [
        SpotType.wall, // bottom-left corner
        directions.contains(Direction.south)
            ? SpotType.path
            : SpotType.wall, // south edge
        SpotType.wall, // bottom-right corner
      ],
    ];
  }

  bool canConnectToOtherTileInDirection(Direction direction, Tile other) {
    // print("\tChecking if $this can connect to $other");
    if (!directions.contains(direction)) {
      return false;
    }
    return other.directions.contains(direction.getOpposite());
  }

  @override
  String toString() {
    return 'Tile(id: $id, type: $type, directions: $directions)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Manages a collection of tiles, mapping tile IDs to Tile definitions.
class TileManager {
  /// Tile ID for east-west tunnel
  static const int tunnelEWID = -1;

  /// Tile ID for north-south tunnel
  static const int tunnelNSID = -2;

  final Map<int, Tile> _tiles = {};

  TileManager();

  /// Adds a tile to the manager.
  void addTile(Tile tile) {
    _tiles[tile.id] = tile;
  }

  /// Adds multiple tiles to the manager.
  void addTiles(List<Tile> tiles) {
    for (var tile in tiles) {
      addTile(tile);
    }
  }

  /// Gets a tile by its ID. Returns null if not found.
  Tile getTile(int id) {
    return _tiles[id] ?? Tile.variant(0, SpotType.path, {});
  }

  /// Checks if a tile with the given ID exists.
  bool hasTile(int id) {
    return _tiles.containsKey(id);
  }

  /// Gets all tile IDs.
  List<int> get tileIds => _tiles.keys.toList();

  /// Gets all tiles.
  List<Tile> get tiles => _tiles.values.toList();

  /// Gets the number of tiles.
  int get count => _tiles.length;

  /// Removes a tile by its ID.
  void removeTile(int id) {
    _tiles.remove(id);
  }

  /// Clears all tiles.
  void clear() {
    _tiles.clear();
  }

  /// Creates a TileManager with variant tiles for the given IDs.
  factory TileManager.withVariants() {
    final manager = TileManager();

    void addSetOfTiles(int baseId, Set<Direction> directions) {
      manager.addTile(Tile.variant(baseId, SpotType.path, directions));
      manager.addTile(Tile.variant(baseId + 10, SpotType.cent, directions));
      manager.addTile(Tile.variant(baseId + 20, SpotType.start, directions));
      manager.addTile(Tile.variant(baseId + 30, SpotType.end, directions));
    }

    addSetOfTiles(1, {Direction.north, Direction.south});
    addSetOfTiles(2, {Direction.east, Direction.west});
    addSetOfTiles(3, {Direction.east, Direction.south});
    addSetOfTiles(4, {Direction.south, Direction.west});
    addSetOfTiles(5, {Direction.north, Direction.east});
    addSetOfTiles(6, {Direction.north, Direction.west});
    addSetOfTiles(7, {Direction.north, Direction.east, Direction.south});
    addSetOfTiles(8, {Direction.north, Direction.west, Direction.south});
    addSetOfTiles(9, {Direction.west, Direction.east, Direction.south});
    addSetOfTiles(10, {Direction.north, Direction.east, Direction.west});

    manager.addTile(
      Tile.variant(41, SpotType.bridgeNS, {Direction.north, Direction.south}),
    );
    manager.addTile(
      Tile.variant(42, SpotType.bridgeEW, {Direction.east, Direction.west}),
    );
    manager.addTile(
      Tile.variant(43, SpotType.path, {
        Direction.north,
        Direction.south,
        Direction.east,
        Direction.west,
      }),
    );

    manager.addTile(
      Tile.variant(TileManager.tunnelEWID, SpotType.tunnelEW, {
        Direction.east,
        Direction.west,
      }),
    );

    manager.addTile(
      Tile.variant(TileManager.tunnelNSID, SpotType.tunnelNS, {
        Direction.north,
        Direction.south,
      }),
    );
    return manager;
  }

  @override
  String toString() {
    return 'TileManager(count: $count, ids: ${tileIds.join(", ")})';
  }
}
