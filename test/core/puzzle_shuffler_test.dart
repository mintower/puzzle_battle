import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/core/puzzle_shuffler.dart';

/// Independent re-implementation of the classic n-puzzle solvability
/// theorem, kept separate from PuzzleShuffler's internals so this test
/// actually catches bugs in that implementation rather than just mirroring
/// it.
bool _isSolvableReference(List<int> tiles, int size) {
  final values = tiles.where((t) => t != 0).toList();
  var inversions = 0;
  for (var i = 0; i < values.length; i++) {
    for (var j = i + 1; j < values.length; j++) {
      if (values[i] > values[j]) inversions++;
    }
  }
  if (size.isOdd) return inversions.isEven;
  final blankIndex = tiles.indexOf(0);
  final blankRowFromBottom = size - (blankIndex ~/ size);
  return (inversions + blankRowFromBottom).isOdd;
}

void main() {
  group('PuzzleShuffler', () {
    test('same seed produces an identical board (required for online races)',
        () {
      final a = PuzzleShuffler.generate(size: 4, seed: 42);
      final b = PuzzleShuffler.generate(size: 4, seed: 42);
      expect(a, b);
    });

    test('different seeds usually produce different boards', () {
      final a = PuzzleShuffler.generate(size: 4, seed: 1);
      final b = PuzzleShuffler.generate(size: 4, seed: 2);
      expect(a, isNot(b));
    });

    test('every generated board is solvable, across sizes and seeds', () {
      for (final size in [3, 4, 5]) {
        for (var seed = 0; seed < 200; seed++) {
          final board = PuzzleShuffler.generate(size: size, seed: seed);
          expect(
            _isSolvableReference(board.tiles, size),
            isTrue,
            reason: 'size=$size seed=$seed produced an unsolvable board',
          );
        }
      }
    });

    test('output always contains exactly one of each tile value', () {
      final board = PuzzleShuffler.generate(size: 4, seed: 7);
      final sorted = List<int>.of(board.tiles)..sort();
      expect(sorted, List<int>.generate(16, (i) => i));
    });
  });
}
