/// Simple Point class for maze coordinates
class Point {
  final int row;
  final int col;

  Point(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Point && row == other.row && col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => 'Point($row, $col)';
}
