import 'package:flutter/material.dart';

import '../core/puzzle_board.dart';

/// Renders a [PuzzleBoard] as a grid of sliding tiles. Each tile is keyed
/// by its value (not its position), so Flutter's implicit animations
/// smoothly slide a tile to its new spot whenever the board changes.
class BoardView extends StatelessWidget {
  final PuzzleBoard board;
  final ValueChanged<int>? onTileTap;
  final Color? tileColor;

  const BoardView({
    super.key,
    required this.board,
    this.onTileTap,
    this.tileColor,
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
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onTileTap == null ? null : () => onTileTap!(index),
                    child: Center(
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
}
