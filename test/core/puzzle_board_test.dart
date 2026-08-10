import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/core/puzzle_board.dart';

void main() {
  group('PuzzleBoard', () {
    test('solved board reports isSolved true with ordered tiles', () {
      final board = PuzzleBoard.solved(3);
      expect(board.isSolved, isTrue);
      expect(board.tiles, [1, 2, 3, 4, 5, 6, 7, 8, 0]);
    });

    test('emptyIndex finds the blank tile', () {
      final board = PuzzleBoard.solved(3);
      expect(board.emptyIndex, 8);
    });

    test('availableMoves only include tiles adjacent to the blank', () {
      final board = PuzzleBoard.solved(3); // blank at index 8 (row 2, col 2)
      final moves = board.availableMoves..sort();
      expect(moves, [5, 7]);
    });

    test('move slides an adjacent tile into the blank slot', () {
      final board = PuzzleBoard.solved(3);
      final moved = board.move(7);
      expect(moved, isNotNull);
      expect(moved!.tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(moved.isSolved, isFalse);
    });

    test('move returns null for a tile that is not adjacent to the blank',
        () {
      final board = PuzzleBoard.solved(3);
      expect(board.move(0), isNull);
    });

    test('move does not mutate the original board (immutability)', () {
      final board = PuzzleBoard.solved(3);
      final original = List<int>.of(board.tiles);
      board.move(7);
      expect(board.tiles, original);
    });

    test('equality is based on size and tile contents', () {
      final a = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 8, 0]);
      final b = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 8, 0]);
      final c = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('correctTileCount counts tiles in their solved position', () {
      expect(PuzzleBoard.solved(3).correctTileCount, 8);
      // Tiles 1..6 are in place; 7 and 8 are swapped with each other.
      final board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 8, 7, 0]);
      expect(board.correctTileCount, 6);
    });
  });
}
