import 'package:image/image.dart' as img;
import 'package:maze/maze.dart';

/// A tile location with row and column coordinates.
typedef TileLocation = ({int row, int col});

/// Draws a solution path on top of a maze image.
///
/// The off-center "two-lane" geometry is provided by [LanePathGeometry] from
/// the `maze` package and shared with the Flutter overlay renderer; this class
/// is only responsible for rasterizing the computed segments onto an
/// `img.Image`.
class SolutionPathDraw {
  final img.Image image;
  final int tileSize;
  final img.Color pathColor;
  final TileManager tileManager;
  final MazeArray mazeArray;
  final LanePathGeometry geometry;

  /// Creates a solution path drawer.
  /// 
  /// [image] - The image to draw the path on
  /// [tileSize] - The size of each tile in pixels
  /// [pathColor] - The color to use for drawing the path
  /// [tileManager] - The tile manager for the maze
  /// [mazeArray] - The maze array structure
  SolutionPathDraw({
    required this.image,
    required this.tileSize,
    required this.pathColor,
    required this.tileManager,
    required this.mazeArray,
  }) : geometry = LanePathGeometry(tileSize: tileSize.toDouble());

  /// Draws a solution path on the image given a list of positions.
  /// 
  /// [path] - List of tile locations representing the solution path
  void drawPath(List<TileLocation> path) {
    if (path.isEmpty) return;

    final segments = geometry.computeSegments(
      [for (final tile in path) MazeLocation(row: tile.row, col: tile.col)],
    );

    for (final segment in segments) {
      img.drawLine(
        image,
        x1: segment.start.x.round(),
        y1: segment.start.y.round(),
        x2: segment.end.x.round(),
        y2: segment.end.y.round(),
        color: pathColor,
        thickness: 3,
      );

      final arrow = segment.arrow;
      if (arrow != null) {
        img.fillPolygon(
          image,
          vertices: [
            for (final vertex in arrow)
              img.Point(vertex.x.round(), vertex.y.round()),
          ],
          color: pathColor,
        );
      }
    }
  }
}

