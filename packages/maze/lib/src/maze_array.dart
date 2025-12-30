import 'package:csv/csv.dart';
import 'package:maze/maze.dart';

class MazeLocation {
  final int row;
  final int col;
  final int z;

  MazeLocation({required this.row, required this.col, this.z = 0});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MazeLocation && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => '($row,$col,($z))';
}

/// Represents a 2D array of tiles loaded from a CSV file.
/// Each number in the array refers to a tile variant (e.g., 1 -> Variant1.png).
class MazeArray {
  final List<List<Tile>> tiles;
  int get rows => tiles.length;
  int get cols => tiles.isEmpty ? 0 : tiles[0].length;

  const MazeArray({required this.tiles});

  /// Loads a maze from CSV string content.
  /// This is the base method that works in both Flutter and standalone Dart.
  /// For file loading, use platform-specific methods or pass the content here.
  static MazeArray fromCsvString(String csvString) {
    try {
      final List<List<dynamic>> csvData = const CsvToListConverter(
        shouldParseNumbers: true,
        eol: '\n',
      ).convert(csvString);

      TileManager tileManager = TileManager.withVariants();

      // Convert to int matrix
      final List<List<Tile>> tiles = csvData
          .map(
            (row) => row.map((cell) {
              final id = cell is int
                  ? cell
                  : int.tryParse(cell.toString().trim()) ?? 0;
              return tileManager.getTile(id);
            }).toList(),
          )
          .toList();

      return MazeArray(tiles: tiles);
    } catch (e) {
      throw Exception('Failed to load maze from CSV string: $e');
    }
  }

  MazeLocation getStartLocation() {
    return getNodesByType( SpotType.start)!;
  }

  MazeLocation? getNodesByType(SpotType type) {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (tiles[row][col].type == type) {
          return MazeLocation(row: row, col: col);
        }
      }
    }
    return null; // Not found
  }

  /// Gets the tile number at the specified row and column.
  Tile getTile(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= cols) {
      throw RangeError('Position ($row, $col) is out of bounds');
    }
    return tiles[row][col];
  }

  MazeLocation? getLocationInDirection(
    MazeLocation currentLocation,
    Direction direction,
  ) {
    int newRow = currentLocation.row;
    int newCol = currentLocation.col;

    switch (direction) {
      case Direction.north:
        newRow -= 1;
        break;
      case Direction.east:
        newCol += 1;
        break;
      case Direction.south:
        newRow += 1;
        break;
      case Direction.west:
        newCol -= 1;
        break;
    }

    if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) {
      return null;
    }

    return MazeLocation(row: newRow, col: newCol);
  }

  

  /// Gets all unique tile numbers in the maze.
  Set<Tile> getUniqueTiles() {
    final Set<Tile> uniqueTiles = {};
    for (var row in tiles) {
      uniqueTiles.addAll(row);
    }
    return uniqueTiles;
  }

  /// Prints the maze to the specified output stream.
  ///
  /// [sink] The output stream to write to (e.g., stdout, StringBuffer).
  /// [maxRows] Maximum number of rows to print (default: print all rows).
  /// [maxCols] Maximum number of columns to print (default: print all columns).
  void printMaze(StringSink sink, {int? maxRows, int? maxCols}) {
    final previewRows = maxRows == null
        ? rows
        : (rows < maxRows ? rows : maxRows);
    final previewCols = maxCols == null
        ? cols
        : (cols < maxCols ? cols : maxCols);

    // Each tile is 3x3, so we need to print 3 rows for each tile row
    for (var r = 0; r < previewRows; r++) {
      // Print 3 sub-rows for each tile row
      for (var subRow = 0; subRow < 3; subRow++) {
        final rowPreview = <String>[];
        for (var c = 0; c < previewCols; c++) {
          final spotArray = getTile(r, c).getFullSpotArray();
          // Print all 3 columns of this sub-row
          for (var subCol = 0; subCol < 3; subCol++) {
            rowPreview.add(spotArray[subRow][subCol].toString());
          }
        }
        sink.writeln(rowPreview.join(' '));
      }
    }

    if (cols > previewCols) {
      sink.writeln('... (${cols - previewCols} more columns)');
    }
    if (rows > previewRows) {
      sink.writeln('... (${rows - previewRows} more rows)');
    }
  }

  @override
  String toString() {
    return 'MazeArray(rows: $rows, cols: $cols)';
  }
}
