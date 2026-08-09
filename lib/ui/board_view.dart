import 'package:flutter/material.dart';

import '../core/puzzle_board.dart';
import 'puzzle_artwork.dart';

/// Whether tiles show their number or a slice of a picture that
/// reassembles as the puzzle is solved.
enum TileStyle { numbers, picture }

/// Renders a [PuzzleBoard] as a grid of sliding tiles. Each tile is keyed
/// by its value (not its position), so Flutter's implicit animations
/// smoothly slide a tile to its new spot whenever the board changes.
class BoardView extends StatelessWidget {
  final PuzzleBoard board;
  final ValueChanged<int>? onTileTap;
  final Color? tileColor;
  final TileStyle tileStyle;

  const BoardView({
    super.key,
    required this.board,
    this.onTileTap,
    this.tileColor,
    this.tileStyle = TileStyle.numbers,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSide = constraints.maxWidth;
        final tileSide = boardSide / board.size;
        final color = tileColor ?? Theme.of(context).colorScheme.primary;

        final tiles = <Widget>[];
        for (var index = 0; index < board.tiles.length; index++) {
          final value = board.tiles[index];
          if (value == 0) continue;
          final row = index ~/ board.size;
          final col = index % board.size;
          tiles.add(
            AnimatedPositioned(
              key: ValueKey(value),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              left: col * tileSide,
              top: row * tileSide,
              width: tileSide,
              height: tileSide,
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Material(
                  color: tileStyle == TileStyle.picture ? Colors.transparent : color,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: onTileTap == null ? null : () => onTileTap!(index),
                    child: _tileContent(value, boardSide, tileSide),
                  ),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: boardSide,
          height: boardSide,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              ...tiles,
            ],
          ),
        );
      },
    );
  }

  Widget _tileContent(int value, double boardSide, double tileSide) {
    if (tileStyle == TileStyle.numbers) {
      return Center(
        child: Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Picture mode: each tile shows the slice of one shared painting that
    // corresponds to its *solved* position, so the picture reassembles as
    // the puzzle is completed regardless of where the tile sits now.
    final goalIndex = value - 1;
    final goalRow = goalIndex ~/ board.size;
    final goalCol = goalIndex % board.size;

    return ClipRect(
      child: OverflowBox(
        maxWidth: boardSide,
        maxHeight: boardSide,
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: Offset(-goalCol * tileSide, -goalRow * tileSide),
          child: SizedBox(
            width: boardSide,
            height: boardSide,
            child: const CustomPaint(painter: PuzzleArtworkPainter()),
          ),
        ),
      ),
    );
  }
}
