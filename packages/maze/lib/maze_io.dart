import 'dart:io';
import 'src/maze_array.dart';

/// Extension to load MazeArray from file system (for standalone Dart apps).
extension MazeArrayIO on MazeArray {
  /// Loads a maze from a CSV file using dart:io.
  /// The CSV file should contain a 2D array of integers, where each integer
  /// represents a tile variant number.
  static Future<MazeArray> fromCsv(String csvPath) async {
    try {
      final file = File(csvPath);
      final csvString = await file.readAsString();
      return MazeArray.fromCsvString(csvString);
    } catch (e) {
      throw Exception('Failed to load maze from CSV file: $e');
    }
  }
}
