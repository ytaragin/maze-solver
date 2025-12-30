import 'package:flutter/services.dart';
import 'src/maze_array.dart';

/// Extension to load MazeArray from Flutter assets.
extension MazeArrayFlutter on MazeArray {
  /// Loads a maze from a CSV asset file using Flutter's rootBundle.
  /// The CSV file should be listed in pubspec.yaml assets section.
  static Future<MazeArray> fromAsset(String assetPath) async {
    try {
      final csvString = await rootBundle.loadString(assetPath);
      return MazeArray.fromCsvString(csvString);
    } catch (e) {
      throw Exception('Failed to load maze from asset: $e');
    }
  }
}
