import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/core/puzzle_board.dart';
import 'package:puzzle_battle/core/puzzle_session.dart';

void main() {
  group('PuzzleSession', () {
    test('two sessions with the same seed start with identical boards', () {
      final a = PuzzleSession(size: 4, seed: 7);
      final b = PuzzleSession(size: 4, seed: 7);
      expect(a.board, b.board);
    });

    test('tryMove applies legal moves and increments moveCount', () {
      final session = PuzzleSession(size: 3, seed: 1);
      final legalMove = session.board.availableMoves.first;

      final applied = session.tryMove(legalMove);

      expect(applied, isTrue);
      expect(session.moveCount, 1);
    });

    test('tryMove rejects illegal moves without changing state', () {
      final session = PuzzleSession(size: 3, seed: 1);
      final illegalMove = session.board.emptyIndex; // sliding the blank itself

      final rejected = session.tryMove(illegalMove);

      expect(rejected, isFalse);
      expect(session.moveCount, 0);
    });

    test('isComplete reflects whether the board is solved', () {
      final session = PuzzleSession(size: 3, seed: 1);
      expect(session.isComplete, isFalse);

      session.board = PuzzleBoard.solved(3);
      expect(session.isComplete, isTrue);
    });

    test('tryMove does nothing once the session is already complete', () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard.solved(3);

      final result = session.tryMove(session.board.availableMoves.first);

      expect(result, isFalse);
      expect(session.moveCount, 0);
    });

    test(
        'combo increases when a move raises correctTileCount and resets '
        'when a move lowers it', () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 0, 6, 7, 5, 8]);
      expect(session.combo, 0);

      session.tryMove(7); // -> [1,2,3,4,5,6,7,0,8]: correct count 6 -> 7
      expect(session.combo, 1);

      session.tryMove(6); // -> [1,2,3,4,5,6,0,7,8]: correct count 7 -> 6
      expect(session.combo, 0);
    });

    test(
        'applyDisruption moves the board without counting as the player\'s '
        'own moves, and resets combo', () {
      final session = PuzzleSession(size: 4, seed: 3);
      session.tryMove(session.board.availableMoves.first);
      final movesBefore = session.moveCount;

      session.applyDisruption(3, Random(0));

      expect(session.moveCount, movesBefore);
      expect(session.combo, 0);
      final sortedTiles = List<int>.of(session.board.tiles)..sort();
      expect(sortedTiles, List<int>.generate(16, (i) => i));
    });

    test('applyDisruption is a no-op once the board is already solved', () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard.solved(3);

      session.applyDisruption(5, Random(0));

      expect(session.board, PuzzleBoard.solved(3));
    });
  });
}
