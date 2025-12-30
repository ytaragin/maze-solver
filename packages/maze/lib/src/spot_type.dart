/// Represents the type of a spot in the maze.
enum SpotType {
  /// A regular walkable path
  path,

  /// A wall or obstacle
  wall,

  /// The starting position
  start,

  /// The ending/goal position
  end,

  cent,
  bridgeNS,
  bridgeEW,
  tunnelNS,
  tunnelEW;

  @override
  String toString() {
    switch (this) {
      case SpotType.path:
        return 'O';
      case SpotType.wall:
        return '.';
      case SpotType.start:
        return 'S';
      case SpotType.end:
        return 'E';
      case SpotType.cent:
        return 'C';
      case SpotType.bridgeNS:
        return '"';
      case SpotType.bridgeEW:
        return '=';
      case SpotType.tunnelNS:
        return 'T"';
      case SpotType.tunnelEW:
        return 'T=';
    }
  }
}

enum Direction {
  north,
  south,
  east,
  west;

  Direction getOpposite() {
    switch (this) {
      case Direction.north:
        return Direction.south;
      case Direction.south:
        return Direction.north;
      case Direction.east:
        return Direction.west;
      case Direction.west:
        return Direction.east;
    }
  }
}
