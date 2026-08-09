import 'dart:math';

import 'puzzle_board.dart';

/// Finds an optimal (shortest) solution for a [PuzzleBoard] using IDA*
/// with a Manhattan-distance heuristic.
///
/// Returns the sequence of tile positions to feed into
/// [PuzzleBoard.move]/[PuzzleSession.tryMove], in order, or `null` if no
/// solution was found within [maxDepth] moves.
///
/// Measured: plain Manhattan distance (no linear-conflict enhancement) is
/// fast for 3x3 (low single-digit ms, worst case), but a fully random 4x4
/// shuffle can take minutes even on the Dart VM — and web debug builds are
/// far slower still. Do not call [solve] synchronously for boards larger
/// than 3x3; use [greedyMove] instead, which is O(branching factor) per
/// call.
class PuzzleSolver {
  static List<int>? solve(PuzzleBoard board, {int maxDepth = 80}) {
    if (board.isSolved) return const [];

    var threshold = _heuristic(board);
    final path = <int>[];

    while (true) {
      final result = _search(board, 0, threshold, null, path, maxDepth);
      if (result == _found) return List<int>.unmodifiable(path);
      if (result == _noSolution || threshold > maxDepth) return null;
      threshold = result;
    }
  }

  static const int _found = -1;
  static const int _noSolution = 1 << 30;

  static int _search(
    PuzzleBoard board,
    int g,
    int threshold,
    int? bannedMove,
    List<int> path,
    int maxDepth,
  ) {
    final f = g + _heuristic(board);
    if (f > threshold) return f;
    if (board.isSolved) return _found;
    if (g >= maxDepth) return _noSolution;

    var min = _noSolution;
    final parentEmpty = board.emptyIndex;
    for (final move in board.availableMoves) {
      if (move == bannedMove) continue; // don't immediately undo the last move
      final child = board.move(move)!;
      path.add(move);
      final result =
          _search(child, g + 1, threshold, parentEmpty, path, maxDepth);
      if (result == _found) return _found;
      if (result < min) min = result;
      path.removeLast();
    }
    return min;
  }

  /// Picks a single move using one-ply Manhattan-distance lookahead: the
  /// legal move that reduces total heuristic distance the most, breaking
  /// ties randomly. [avoidMove] excludes immediately undoing the previous
  /// move (pass the blank's index from before that move).
  ///
  /// This is O(branching factor) instead of [solve]'s exponential search,
  /// so it's the safe choice for boards where an exact solve is too
  /// expensive to run synchronously. It isn't guaranteed optimal, or even
  /// guaranteed to finish the puzzle — it can stall on a heuristic
  /// plateau — which is an acceptable trade for an AI opponent.
  static int greedyMove(PuzzleBoard board, Random random, {int? avoidMove}) {
    final allMoves = board.availableMoves;
    final candidates = avoidMove == null
        ? allMoves
        : allMoves.where((m) => m != avoidMove).toList();
    final options = candidates.isEmpty ? allMoves : candidates;

    var best = <int>[options.first];
    var bestScore = _heuristic(board.move(options.first)!);
    for (final move in options.skip(1)) {
      final score = _heuristic(board.move(move)!);
      if (score < bestScore) {
        bestScore = score;
        best = [move];
      } else if (score == bestScore) {
        best.add(move);
      }
    }
    return best[random.nextInt(best.length)];
  }

  static int _heuristic(PuzzleBoard board) {
    final size = board.size;
    var distance = 0;
    for (var i = 0; i < board.tiles.length; i++) {
      final value = board.tiles[i];
      if (value == 0) continue;
      final goalRow = (value - 1) ~/ size;
      final goalCol = (value - 1) % size;
      final row = i ~/ size;
      final col = i % size;
      distance += (row - goalRow).abs() + (col - goalCol).abs();
    }
    return distance;
  }
}
