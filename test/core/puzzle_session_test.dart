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
  });
}
