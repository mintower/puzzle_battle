import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/core/ai_opponent.dart';
import 'package:puzzle_battle/core/puzzle_session.dart';

void main() {
  const instant = AiDifficultyProfile(
    minThink: Duration.zero,
    maxThink: Duration.zero,
    mistakeChance: 0.0,
  );

  group('AiOpponent', () {
    test('with zero mistake chance, plays optimally through to completion',
        () async {
      final session = PuzzleSession(size: 3, seed: 3);
      final ai = AiOpponent(session: session, profile: instant, randomSeed: 1);

      var guard = 0;
      while (!session.isComplete && guard < 100) {
        expect(await ai.playNextMove(), isTrue);
        guard++;
      }

      expect(session.isComplete, isTrue);
    });

    test('playNextMove returns false once the session is already complete',
        () async {
      final session = PuzzleSession(size: 3, seed: 3);
      final ai = AiOpponent(session: session, profile: instant);
      while (!session.isComplete) {
        await ai.playNextMove();
      }
      expect(await ai.playNextMove(), isFalse);
    });

    test(
        'a forced mistake still applies a legal move and keeps the board valid',
        () async {
      final session = PuzzleSession(size: 3, seed: 2);
      final ai = AiOpponent(
        session: session,
        profile: const AiDifficultyProfile(
          minThink: Duration.zero,
          maxThink: Duration.zero,
          mistakeChance: 1.0,
        ),
        randomSeed: 4,
      );

      final played = await ai.playNextMove();

      expect(played, isTrue);
      expect(session.moveCount, 1);
      final sortedTiles = List<int>.of(session.board.tiles)..sort();
      expect(sortedTiles, List<int>.generate(9, (i) => i));
    });

    test(
        'on a 4x4 board, uses fast greedy moves instead of an exact search '
        '(regression: an exact solve on a random 4x4 board can take minutes '
        'and freezes the UI thread if run synchronously)', () async {
      final session = PuzzleSession(size: 4, seed: 11);
      final ai = AiOpponent(session: session, profile: instant, randomSeed: 5);

      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 300 && !session.isComplete; i++) {
        await ai.playNextMove();
      }
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(3000),
          reason: 'greedy move selection must stay cheap regardless of '
              'board difficulty');
      final sortedTiles = List<int>.of(session.board.tiles)..sort();
      expect(sortedTiles, List<int>.generate(16, (i) => i));
    });
  });
}
