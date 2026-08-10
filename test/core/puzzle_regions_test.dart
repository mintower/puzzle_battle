import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/core/puzzle_board.dart';
import 'package:puzzle_battle/core/puzzle_regions.dart';

void main() {
  group('puzzleQuadrants', () {
    test('covers every cell exactly once for an even size', () {
      final quadrants = puzzleQuadrants(4);
      final all = quadrants.expand((q) => q).toList()..sort();
      expect(all, List<int>.generate(16, (i) => i));
    });

    test('covers every cell exactly once for an odd size', () {
      final quadrants = puzzleQuadrants(3);
      final all = quadrants.expand((q) => q).toList()..sort();
      expect(all, List<int>.generate(9, (i) => i));
    });

    test('top-left quadrant of a 4x4 board is the 2x2 corner', () {
      final quadrants = puzzleQuadrants(4);
      expect(quadrants[0]..sort(), [0, 1, 4, 5]);
    });
  });

  group('isQuadrantSolved', () {
    test('true for a solved board across all quadrants', () {
      final board = PuzzleBoard.solved(4);
      for (final quadrant in puzzleQuadrants(4)) {
        expect(isQuadrantSolved(board, quadrant), isTrue);
      }
    });

    test('false if any cell in the quadrant is out of place', () {
      final board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 8, 7, 0]);
      final bottomRight = puzzleQuadrants(3)[3]; // {4,5,7,8}
      expect(isQuadrantSolved(board, bottomRight), isFalse);
    });
  });
}
