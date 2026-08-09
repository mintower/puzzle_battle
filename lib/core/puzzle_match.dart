import 'puzzle_session.dart';

enum MatchResult { ongoing, playerWon, opponentWon, draw }

/// Pairs two [PuzzleSession]s that share the same size/seed into a race:
/// whoever completes their own board first wins. This works the same
/// whether the opponent session is driven by an AI or, later, by moves
/// synced from a real online opponent — the match logic doesn't care who
/// is making the moves.
class PuzzleMatch {
  final PuzzleSession player;
  final PuzzleSession opponent;

  PuzzleMatch({required this.player, required this.opponent})
      : assert(player.size == opponent.size),
        assert(player.seed == opponent.seed);

  MatchResult get result {
    final playerDone = player.isComplete;
    final opponentDone = opponent.isComplete;
    if (playerDone && opponentDone) return MatchResult.draw;
    if (playerDone) return MatchResult.playerWon;
    if (opponentDone) return MatchResult.opponentWon;
    return MatchResult.ongoing;
  }

  bool get isOver => result != MatchResult.ongoing;
}
