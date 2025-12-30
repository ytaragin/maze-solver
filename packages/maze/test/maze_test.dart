import 'package:test/test.dart';
import 'package:maze/maze.dart';

void main() {
  group('Tile', () {
    test('creates tile with variant factory', () {
      final tile = Tile.variant(1, SpotType.path, {
        Direction.north,
        Direction.south,
      });
      expect(tile.id, equals(1));
      expect(tile.type, equals(SpotType.path));
      expect(tile.directions, containsAll([Direction.north, Direction.south]));
    });

    test('tiles with same id are equal', () {
      final tile1 = Tile.variant(1, SpotType.path, {Direction.north});
      final tile2 = Tile.variant(1, SpotType.wall, {Direction.south});
      expect(tile1, equals(tile2));
    });
  });

  group('TileManager', () {
    test('adds and retrieves tiles', () {
      final manager = TileManager();
      final tile = Tile.variant(1, SpotType.path, {Direction.north});

      manager.addTile(tile);
      expect(manager.hasTile(1), isTrue);
      expect(manager.getTile(1), equals(tile));
    });

    test('creates default variants', () {
      final manager = TileManager.withVariants();
      expect(manager.count, greaterThan(0));
      expect(manager.hasTile(1), isTrue);
      expect(manager.hasTile(41), isTrue); // bridge
    });
  });

  group('MazeArray', () {
    test('creates maze from CSV string', () {
      const csvString = '''1,2,3
3,5,6
7,8,1''';
      final maze = MazeArray.fromCsvString(csvString);

      expect(maze.rows, equals(3));
      expect(maze.cols, equals(3));
      expect(maze.getTile(0, 0).id, equals(1));
      expect(maze.getTile(2, 2).id, equals(1));
    });

    test('throws error for out of bounds access', () {
      const csvString = '''1,2
3,1''';
      final maze = MazeArray.fromCsvString(csvString);

      expect(() => maze.getTile(5, 5), throwsRangeError);
      expect(() => maze.getTile(-1, 0), throwsRangeError);
    });

    test('gets unique tiles', () {
      const csvString = '''1,2,1
2,3,2
1,1,3''';
      final maze = MazeArray.fromCsvString(csvString);

      final uniqueTiles = maze.getUniqueTiles();
      // Tiles 1, 2, 3 are all valid in TileManager.withVariants()
      expect(uniqueTiles.length, equals(3));
    });
  });
}
