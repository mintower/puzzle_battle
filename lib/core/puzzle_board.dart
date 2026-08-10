/// Immutable sliding-puzzle board. Tiles are stored row-major; the value
/// `0` marks the empty slot. A solved board of size `n` is
/// `[1, 2, ..., n*n - 1, 0]`.
class PuzzleBoard {
  final int size;
  final List<int> tiles;

  PuzzleBoard({required this.size, required List<int> tiles})
      : tiles = List.unmodifiable(tiles) {
    assert(tiles.length == size * size);
  }

  factory PuzzleBoard.solved(int size) {
    final tileCount = size * size;
    final tiles = List<int>.generate(tileCount, (i) => (i + 1) % tileCount);
    return PuzzleBoard(size: size, tiles: tiles);
  }

  int get emptyIndex => tiles.indexOf(0);

  bool get isSolved {
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return true;
  }

  /// How many tiles (excluding the blank) currently sit in their solved
  /// position. Used for both the progress bars and combo tracking.
  int get correctTileCount {
    var correct = 0;
    for (var i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] == i + 1) correct++;
    }
    return correct;
  }

  /// Indices of tiles that are adjacent to the empty slot and can
  /// therefore legally slide into it.
  List<int> get availableMoves {
    final empty = emptyIndex;
    final row = empty ~/ size;
    final col = empty % size;
    final moves = <int>[];
    if (row > 0) moves.add(empty - size);
    if (row < size - 1) moves.add(empty + size);
    if (col > 0) moves.add(empty - 1);
    if (col < size - 1) moves.add(empty + 1);
    return moves;
  }

  /// Slides the tile at [tileIndex] into the empty slot and returns the
  /// resulting board, or `null` if that tile isn't adjacent to the blank.
  PuzzleBoard? move(int tileIndex) {
    if (!availableMoves.contains(tileIndex)) return null;
    final empty = emptyIndex;
    final next = List<int>.of(tiles);
    next[empty] = next[tileIndex];
    next[tileIndex] = 0;
    return PuzzleBoard(size: size, tiles: next);
  }

  @override
  bool operator ==(Object other) {
    if (other is! PuzzleBoard || other.size != size) return false;
    for (var i = 0; i < tiles.length; i++) {
      if (other.tiles[i] != tiles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([size, ...tiles]);
}
