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

  PuzzleSession({required this.size, required this.seed})
      : board = PuzzleShuffler.generate(size: size, seed: seed);

  bool get isComplete => board.isSolved;

  /// Attempts to slide the tile at [tileIndex] into the empty slot.
  /// Returns `true` if the move was legal and applied.
  bool tryMove(int tileIndex) {
    if (isComplete) return false;
    final next = board.move(tileIndex);
    if (next == null) return false;
    board = next;
    moveCount++;
    return true;
  }
}
