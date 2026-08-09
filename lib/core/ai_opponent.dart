import 'dart:math';

import 'puzzle_session.dart';
import 'puzzle_solver.dart';

/// Tunable parameters that make the AI feel like a competitor with a given
/// skill level, expressed as think-time per move and a chance to make a
/// genuine mistake (a random legal move instead of the optimal one) —
/// rather than by weakening the search itself, since a partially-searched
/// solver just looks buggy instead of "easy".
class AiDifficultyProfile {
  final Duration minThink;
  final Duration maxThink;
  final double mistakeChance;

  const AiDifficultyProfile({
    required this.minThink,
    required this.maxThink,
    required this.mistakeChance,
  });

  static const easy = AiDifficultyProfile(
    minThink: Duration(milliseconds: 900),
    maxThink: Duration(milliseconds: 1800),
    mistakeChance: 0.35,
  );

  static const medium = AiDifficultyProfile(
    minThink: Duration(milliseconds: 500),
    maxThink: Duration(milliseconds: 1000),
    mistakeChance: 0.15,
  );

  static const hard = AiDifficultyProfile(
    minThink: Duration(milliseconds: 200),
    maxThink: Duration(milliseconds: 500),
    mistakeChance: 0.03,
  );

  Duration thinkTime(Random random) {
    final rangeMs = maxThink.inMilliseconds - minThink.inMilliseconds;
    final offset = rangeMs > 0 ? random.nextInt(rangeMs + 1) : 0;
    return Duration(milliseconds: minThink.inMilliseconds + offset);
  }
}

/// Plays a [PuzzleSession] move-by-move on behalf of the AI, so the UI can
/// animate one tile slide at a time instead of jumping straight to a
/// solved board.
///
/// On boards up to 3x3, the AI computes an exact optimal plan up front
/// (measured: worst case ~17ms — see [PuzzleSolver]). On larger boards an
/// exact solve is too slow to run synchronously on the UI thread, so the
/// AI instead picks each move greedily one step at a time. This keeps
/// [playNextMove] fast regardless of board size instead of ever risking a
/// multi-second (or longer) freeze.
class AiOpponent {
  static const _exactSolveMaxSize = 3;

  final PuzzleSession session;
  final AiDifficultyProfile profile;
  final Random _random;
  List<int> _plan;
  int? _lastMoveOrigin;

  AiOpponent({
    required this.session,
    required this.profile,
    int? randomSeed,
  })  : _random = Random(randomSeed),
        _plan = session.size <= _exactSolveMaxSize
            ? List<int>.of(PuzzleSolver.solve(session.board) ?? const [])
            : const [];

  /// Waits an appropriate think-time, then applies exactly one move
  /// (occasionally a deliberate mistake). Returns `false` once the
  /// session is already complete.
  Future<bool> playNextMove() async {
    if (session.isComplete) return false;

    await Future.delayed(profile.thinkTime(_random));
    if (session.isComplete) return false;

    if (_random.nextDouble() < profile.mistakeChance) {
      final legalMoves = session.board.availableMoves;
      _applyMove(legalMoves[_random.nextInt(legalMoves.length)]);
      return true;
    }

    if (session.size <= _exactSolveMaxSize) {
      if (_plan.isEmpty) {
        _plan = List<int>.of(PuzzleSolver.solve(session.board) ?? const []);
      }
      if (_plan.isNotEmpty) _applyMove(_plan.removeAt(0));
    } else {
      _applyMove(PuzzleSolver.greedyMove(session.board, _random,
          avoidMove: _lastMoveOrigin));
    }
    return true;
  }

  void _applyMove(int move) {
    _lastMoveOrigin = session.board.emptyIndex;
    session.tryMove(move);
  }
}
