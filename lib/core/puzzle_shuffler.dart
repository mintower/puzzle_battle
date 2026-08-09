import 'dart:math';

import 'puzzle_board.dart';

/// Produces a shuffled, always-solvable [PuzzleBoard] from a seed.
///
/// Using a seed (rather than an unseeded shuffle) means two clients — e.g.
/// two players racing online — can independently generate the exact same
/// starting board just by agreeing on a seed, without the server having to
/// transmit the whole board.
class PuzzleShuffler {
  static PuzzleBoard generate({required int size, required int seed}) {
    final random = Random(seed);
    final tiles = List<int>.generate(size * size, (i) => i)..shuffle(random);

    if (!_isSolvable(tiles, size)) {
      _swapFirstTwoNonBlank(tiles);
    }

    return PuzzleBoard(size: size, tiles: tiles);
  }

  /// Classic n-puzzle solvability check based on inversion parity.
  static bool _isSolvable(List<int> tiles, int size) {
    final inversions = _countInversions(tiles);
    if (size.isOdd) {
      return inversions.isEven;
    }
    final blankIndex = tiles.indexOf(0);
    final blankRowFromBottom = size - (blankIndex ~/ size);
    return (inversions + blankRowFromBottom).isOdd;
  }

  static int _countInversions(List<int> tiles) {
    final values = tiles.where((t) => t != 0).toList();
    var inversions = 0;
    for (var i = 0; i < values.length; i++) {
      for (var j = i + 1; j < values.length; j++) {
        if (values[i] > values[j]) inversions++;
      }
    }
    return inversions;
  }

  /// Swapping any two non-blank tiles flips the inversion parity by one,
  /// which flips solvability — the cheapest possible fix.
  static void _swapFirstTwoNonBlank(List<int> tiles) {
    final i = tiles.indexWhere((t) => t != 0);
    final j = tiles.indexWhere((t) => t != 0, i + 1);
    final tmp = tiles[i];
    tiles[i] = tiles[j];
    tiles[j] = tmp;
  }
}
