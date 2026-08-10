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

    test('a locked tile cannot be moved, and it unlocks once its turn count '
        'expires', () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 0, 6, 7, 5, 8]);
      session.lockedTiles[5] = 2; // tile '5' sits at index 7

      expect(session.tryMove(7), isFalse, reason: 'tile 5 is locked');
      expect(session.moveCount, 0);

      expect(session.tryMove(3), isTrue); // moves tile '4' instead
      expect(session.lockedTiles[5], 1);

      expect(session.tryMove(0), isTrue); // one more own move expires it
      expect(session.lockedTiles.containsKey(5), isFalse);
    });

    test(
        'applyShuffle only ever produces a valid permutation (it moves the '
        'blank via real legal slides, never swaps arbitrary cells) and '
        "resets combo without counting as the player's own move", () {
      final session = PuzzleSession(size: 4, seed: 3);
      session.tryMove(session.board.availableMoves.first);
      final movesBefore = session.moveCount;

      session.applyShuffle(Random(0));

      expect(session.moveCount, movesBefore);
      expect(session.combo, 0);
      final sortedTiles = List<int>.of(session.board.tiles)..sort();
      expect(sortedTiles, List<int>.generate(16, (i) => i));
    });

    test('applyShuffle is a no-op once the board is already solved', () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard.solved(3);

      session.applyShuffle(Random(0));

      expect(session.board, PuzzleBoard.solved(3));
    });

    test(
        'applyIncomingLock locks 1-2 currently-misplaced tiles and resets '
        'combo', () {
      final session = PuzzleSession(size: 4, seed: 3);
      session.tryMove(session.board.availableMoves.first);

      session.applyIncomingLock(Random(0));

      expect(session.lockedTiles.length, inInclusiveRange(1, 2));
      expect(session.combo, 0);
      for (final value in session.lockedTiles.keys) {
        final index = session.board.tiles.indexOf(value);
        expect(index, isNot(session.board.tiles.length - 1),
            reason: 'a locked tile should be a real misplaced tile, not the blank slot');
      }
    });

    test('applyIncomingLock is a no-op once the board is already solved', () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard.solved(3);

      session.applyIncomingLock(Random(0));

      expect(session.lockedTiles, isEmpty);
    });

    test(
        'checkNewlyCompletedQuadrants reports 4 for an already-solved board, '
        'then 0 on a repeat check with no change', () {
      final session = PuzzleSession(size: 4, seed: 1)..board = PuzzleBoard.solved(4);

      expect(session.checkNewlyCompletedQuadrants(), 4);
      expect(session.quadrantStatus, [true, true, true, true]);
      expect(session.checkNewlyCompletedQuadrants(), 0);
    });

    test('checkNewlyCompletedQuadrants only counts fully-solved quadrants',
        () {
      final session = PuzzleSession(size: 3, seed: 1)
        ..board = PuzzleBoard(size: 3, tiles: [1, 3, 2, 6, 8, 5, 4, 7, 0]);

      expect(session.checkNewlyCompletedQuadrants(), 1); // only the top-left corner
      expect(session.quadrantStatus, [true, false, false, false]);
    });
  });
}
