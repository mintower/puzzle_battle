import 'dart:math';

import 'puzzle_board.dart';
import 'puzzle_regions.dart';
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
  /// Purely informational — online battle mode charges attacks off
  /// quadrant completion ([checkNewlyCompletedQuadrants]), not this.
  int combo = 0;

  /// Tile value -> remaining own-moves before the lock wears off. A
  /// locked tile can't be moved (see [tryMove]); ticks down by 1 on every
  /// move this player successfully makes, regardless of which tile moved.
  final Map<int, int> lockedTiles = {};

  List<bool>? _quadrantComplete;

  PuzzleSession({required this.size, required this.seed})
      : board = PuzzleShuffler.generate(size: size, seed: seed);

  bool get isComplete => board.isSolved;

  /// Attempts to slide the tile at [tileIndex] into the empty slot.
  /// Returns `true` if the move was legal and applied. Fails if that tile
  /// is currently locked (see [applyIncomingLock]).
  bool tryMove(int tileIndex) {
    if (isComplete) return false;
    final tileValue = board.tiles[tileIndex];
    if (tileValue != 0 && lockedTiles.containsKey(tileValue)) return false;

    final correctBefore = board.correctTileCount;
    final next = board.move(tileIndex);
    if (next == null) return false;
    board = next;
    moveCount++;
    combo = next.correctTileCount > correctBefore ? combo + 1 : 0;
    _tickLocks();
    return true;
  }

  void _tickLocks() {
    if (lockedTiles.isEmpty) return;
    final expired = <int>[];
    lockedTiles.updateAll((tile, turnsLeft) => turnsLeft - 1);
    lockedTiles.forEach((tile, turnsLeft) {
      if (turnsLeft <= 0) expired.add(tile);
    });
    expired.forEach(lockedTiles.remove);
  }

  /// Simulates an incoming "shuffle" attack: scrambles a 2x2 window of
  /// the board via real legal slides (never an arbitrary cell swap),
  /// which is what guarantees the board stays solvable no matter how many
  /// attacks land. The window is chosen to contain the current blank so
  /// this never has to disturb cells outside the window to reach it.
  void applyShuffle(Random random, {int steps = 6}) {
    if (isComplete) return;
    final blank = board.emptyIndex;
    final blankRow = blank ~/ size;
    final blankCol = blank % size;
    final top = (blankRow - random.nextInt(2)).clamp(0, size - 2);
    final left = (blankCol - random.nextInt(2)).clamp(0, size - 2);
    final window = {
      top * size + left,
      top * size + left + 1,
      (top + 1) * size + left,
      (top + 1) * size + left + 1,
    };

    for (var i = 0; i < steps; i++) {
      final moves = board.availableMoves.where(window.contains).toList();
      if (moves.isEmpty) break;
      board = board.move(moves[random.nextInt(moves.length)])!;
    }
    combo = 0;
  }

  /// Simulates an incoming "lock" attack: picks 1-2 currently-misplaced
  /// tiles at random and freezes them for [turns] of this player's own
  /// moves. No-op once the board is solved or has nothing left to lock.
  void applyIncomingLock(Random random, {int turns = 5}) {
    if (isComplete) return;
    final misplaced = <int>[];
    for (var i = 0; i < board.tiles.length - 1; i++) {
      final value = board.tiles[i];
      if (value != i + 1) misplaced.add(value);
    }
    if (misplaced.isEmpty) return;
    misplaced.shuffle(random);
    for (final value in misplaced.take(2)) {
      lockedTiles[value] = turns;
    }
    combo = 0;
  }

  /// Call after every change to [board] (a move, or an incoming attack).
  /// Returns how many of the board's 4 quadrants just transitioned from
  /// incomplete to complete — online battle mode converts that 1:1 into
  /// attack charges.
  int checkNewlyCompletedQuadrants() {
    final quadrants = puzzleQuadrants(size);
    _quadrantComplete ??= List.filled(quadrants.length, false);
    var newlyCompleted = 0;
    for (var i = 0; i < quadrants.length; i++) {
      final complete = isQuadrantSolved(board, quadrants[i]);
      if (complete && !_quadrantComplete![i]) newlyCompleted++;
      _quadrantComplete![i] = complete;
    }
    return newlyCompleted;
  }

  /// Current per-quadrant completion, in the same [top-left, top-right,
  /// bottom-left, bottom-right] order as [puzzleQuadrants]. Reflects
  /// whatever [checkNewlyCompletedQuadrants] last observed.
  List<bool> get quadrantStatus =>
      List.unmodifiable(_quadrantComplete ?? List.filled(4, false));
}
