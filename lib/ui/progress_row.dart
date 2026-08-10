import 'package:flutter/material.dart';

/// A labeled progress bar used on both the AI match screen and the online
/// match screen to show a player's fraction of correctly placed tiles.
///
/// The nickname sits on its own line above; below it, [leading] (e.g. an
/// opponent's live mini board) and [trailing] (e.g. the picture-mode
/// reference thumbnail) sit at the row's edges while the bar itself is
/// pinned to the screen's middle third via [Positioned], independent of
/// how wide [leading]/[trailing] are. That's what keeps "my" bar and the
/// opponent's bar lined up at the same x position even though only the
/// opponent's row has a mini board next to it.
class ProgressRow extends StatelessWidget {
  static const double _rowHeight = 56;

  // The ambient horizontal padding this row is expected to sit inside
  // (see match_screen.dart / online_match_screen.dart's outer
  // Padding(all: 16)) — backed out so the bar's *screen*-relative math
  // lands on the 1/3–2/3 marks rather than 1/3–2/3 of the padded row.
  static const double _ambientInset = 16;

  final String label;
  final double progress;
  final Color color;

  /// Shown at the row's left edge, vertically centered — the opponent's
  /// live mini board.
  final Widget? leading;

  /// Shown at the row's right edge, vertically centered — the picture-mode
  /// reference thumbnail.
  final Widget? trailing;

  const ProgressRow({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final barLeft = screenWidth / 3 - _ambientInset;
    final barWidth = screenWidth / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: _rowHeight,
          child: Stack(
            children: [
              if (leading != null)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(child: leading),
                ),
              Positioned(
                left: barLeft,
                width: barWidth,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                ),
              ),
              if (trailing != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(child: trailing),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
