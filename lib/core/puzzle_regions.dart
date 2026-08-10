import 'puzzle_board.dart';

/// Splits a board into 4 non-overlapping quadrants (by board index),
/// ordered [top-left, top-right, bottom-left, bottom-right]. For odd
/// sizes the halves aren't perfectly equal (e.g. 3x3 splits 1/2 rows),
/// but every cell still belongs to exactly one quadrant.
List<List<int>> puzzleQuadrants(int size) {
  final split = size ~/ 2;
  final quadrants = List.generate(4, (_) => <int>[]);
  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      final quadrant = (row < split ? 0 : 2) + (col < split ? 0 : 1);
      quadrants[quadrant].add(row * size + col);
    }
  }
  return quadrants;
}

/// Whether every cell in [quadrant] currently holds its solved value
/// (the blank's solved value is 0, only at the board's last index).
bool isQuadrantSolved(PuzzleBoard board, List<int> quadrant) {
  final lastIndex = board.tiles.length - 1;
  for (final i in quadrant) {
    final expected = i == lastIndex ? 0 : i + 1;
    if (board.tiles[i] != expected) return false;
  }
  return true;
}
