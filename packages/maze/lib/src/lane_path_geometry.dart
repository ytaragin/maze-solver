import 'dart:math';

import 'maze_array.dart';
import 'spot_type.dart';

/// A point in pixel space.
typedef LanePoint = ({double x, double y});

/// A drawable segment of a path between two pixel points.
///
/// [arrow] holds the three triangle vertices to draw a directional arrowhead at
/// the segment's midpoint, or `null` for connector segments that should not be
/// decorated with an arrow.
typedef LaneSegment = ({LanePoint start, LanePoint end, List<LanePoint>? arrow});

/// Rendering-agnostic geometry for drawing a path through a maze with an
/// off-center "two-lane" appearance.
///
/// Each tile is divided into a 3x3 grid of points numbered 0-8 from left to
/// right, top to bottom:
/// ```
/// 0  1  2
/// 3  4  5
/// 6  7  8
/// ```
///
/// By entering and exiting tiles through off-center points (chosen per
/// direction of travel), paths that traverse the same tiles in opposite
/// directions are drawn in separate visible lanes.
///
/// This class only computes coordinates; callers are responsible for the actual
/// rendering (e.g. `dart:ui` Canvas or the `image` package).
class LanePathGeometry {
  /// The size of each tile in pixels.
  final double tileSize;

  /// The spacing between adjacent grid points. Smaller values pull the lane
  /// closer to the tile center.
  final double laneSpacing;

  /// The size of the directional arrowhead drawn at each segment's midpoint.
  final double arrowSize;

  /// Creates a lane path geometry calculator.
  ///
  /// [tileSize] - The size of each tile in pixels.
  /// [laneSpacing] - The spacing between grid points; defaults to `tileSize / 5`.
  /// [arrowSize] - The arrowhead size in pixels; defaults to `5`.
  LanePathGeometry({
    required this.tileSize,
    double? laneSpacing,
    this.arrowSize = 5,
  }) : laneSpacing = laneSpacing ?? tileSize / 5;

  /// Returns the pixel coordinates of grid [index] (0-8) within the tile at
  /// [location].
  LanePoint gridPoint(MazeLocation location, int index) {
    final gridRow = index ~/ 3;
    final gridCol = index % 3;
    final centerX = location.col * tileSize + tileSize / 2;
    final centerY = location.row * tileSize + tileSize / 2;
    return (
      x: centerX + (gridCol - 1) * laneSpacing,
      y: centerY + (gridRow - 1) * laneSpacing,
    );
  }

  /// Returns the `(exitPoint, entryPoint)` grid indices for moving in
  /// [direction]. The off-center choice of points is what produces the
  /// two-lane effect.
  (int, int) pointsForDirection(Direction direction) {
    switch (direction) {
      case Direction.north:
        return (2, 8);
      case Direction.south:
        return (6, 0);
      case Direction.east:
        return (8, 6);
      case Direction.west:
        return (0, 2);
    }
  }

  /// Computes the drawable segments for [path], a list of orthogonally adjacent
  /// tile locations.
  ///
  /// For each step a connector segment (no arrow) is emitted from the previous
  /// step's entry point to the current step's exit point, followed by the main
  /// segment (with an arrow) from the exit point to the next tile's entry point.
  /// Non-adjacent pairs are skipped and break lane continuity, mirroring the
  /// original solution renderer.
  List<LaneSegment> computeSegments(List<MazeLocation> path) {
    final segments = <LaneSegment>[];
    if (path.length < 2) return segments;

    // The (tile, point) where the previous step ended, if any.
    (MazeLocation, int)? previousEndpoint;

    for (var i = 0; i < path.length - 1; i++) {
      final startTile = path[i];
      final endTile = path[i + 1];

      final direction = startTile.directionTo(endTile);
      if (direction == null) {
        // Tiles are not adjacent; break continuity.
        previousEndpoint = null;
        continue;
      }

      final (exitPoint, entryPoint) = pointsForDirection(direction);

      if (previousEndpoint != null) {
        final (prevTile, prevPoint) = previousEndpoint;
        segments.add((
          start: gridPoint(prevTile, prevPoint),
          end: gridPoint(startTile, exitPoint),
          arrow: null,
        ));
      }

      final mainStart = gridPoint(startTile, exitPoint);
      final mainEnd = gridPoint(endTile, entryPoint);
      segments.add((
        start: mainStart,
        end: mainEnd,
        arrow: _arrowVertices(mainStart, mainEnd),
      ));

      previousEndpoint = (endTile, entryPoint);
    }

    return segments;
  }

  /// Computes the three triangle vertices for an arrowhead pointing from
  /// [start] toward [end], centered on the segment's midpoint.
  List<LanePoint>? _arrowVertices(LanePoint start, LanePoint end) {
    final midX = (start.x + end.x) / 2;
    final midY = (start.y + end.y) / 2;

    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = sqrt(dx * dx + dy * dy);
    if (length == 0) return null;

    final ndx = dx / length;
    final ndy = dy / length;

    // Tip points forward in the direction of travel.
    final tip = (x: midX + ndx * arrowSize, y: midY + ndy * arrowSize);
    // Base points perpendicular to the direction.
    final base1 = (
      x: midX - ndx * arrowSize - ndy * arrowSize,
      y: midY - ndy * arrowSize + ndx * arrowSize,
    );
    final base2 = (
      x: midX - ndx * arrowSize + ndy * arrowSize,
      y: midY - ndy * arrowSize - ndx * arrowSize,
    );

    return [tip, base1, base2];
  }
}
