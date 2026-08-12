import 'package:flutter/material.dart';

/// The app's brand mark: a 2x2 slice of a sliding puzzle — three numbered
/// tiles and one empty slot — used on the intro screen and the main menu
/// header. Drawn in code (no image asset) so it always matches the theme.
class PuzzleLogoMark extends StatelessWidget {
  final double size;

  const PuzzleLogoMark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const gap = 8.0;
    final tileSize = (size - gap) / 2;

    Widget tile(String? label) {
      final filled = label != null;
      return Container(
        width: tileSize,
        height: tileSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? scheme.primary : scheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(tileSize * 0.3),
        ),
        child: filled
            ? Text(
                label,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: tileSize * 0.42,
                ),
              )
            : null,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [tile('1'), const SizedBox(width: gap), tile('2')],
          ),
          const SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [tile('3'), const SizedBox(width: gap), tile(null)],
          ),
        ],
      ),
    );
  }
}
