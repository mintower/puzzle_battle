import 'dart:math';

import 'puzzle_board.dart';
import 'puzzle_shuffler.dart';

/// Tracks one player's progress through a single puzzle round: the current
/// board state and how many moves they've made. Two [PuzzleSession]s built
/// with the same [size] and [seed] start from an identical board, which is
/// what lets a race mode work without syncing full board state.
class PuzzleSession {
  final int size;
  final int seed;
  PuzzleBoard board;
  int moveCount = 0;

  /// Consecutive moves that increased [PuzzleBoard.correctTileCount].
  /// Resets to 0 on any move that doesn't (including one applied by
  /// [applyDisruption]). Online battle mode converts this into attack
  /// charges; other modes just don't read it.
  int combo = 0;

  PuzzleSession({required this.size, required this.seed})
      : board = PuzzleShuffler.generate(size: size, seed: seed);

  bool get isComplete => board.isSolved;

  /// Attempts to slide the tile at [tileIndex] into the empty slot.
  /// Returns `true` if the move was legal and applied.
  bool tryMove(int tileIndex) {
    if (isComplete) return false;
    final correctBefore = board.correctTileCount;
    final next = board.move(tileIndex);
    if (next == null) return false;
    board = next;
    moveCount++;
    combo = next.correctTileCount > correctBefore ? combo + 1 : 0;
    return true;
  }

  /// Applies [steps] random legal moves — used to simulate an opponent's
  /// attack disrupting this board. Unlike [tryMove], this doesn't count
  /// toward [moveCount] (the player didn't make these moves) and always
  /// resets [combo] to 0 (an attack breaking your streak is the point).
  void applyDisruption(int steps, Random random) {
    for (var i = 0; i < steps; i++) {
      if (isComplete) return;
      final moves = board.availableMoves;
      board = board.move(moves[random.nextInt(moves.length)])!;
    }
    combo = 0;
  }
}
