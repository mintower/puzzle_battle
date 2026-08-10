import 'package:flutter/material.dart';

/// A labeled progress bar used on both the AI match screen and the online
/// match screen to show a player's fraction of correctly placed tiles.
class ProgressRow extends StatelessWidget {
  final String label;
  final double progress;
  final Color color;

  const ProgressRow({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Sized off the phone screen width (not the parent's width), so the
    // bar reads as a fixed "about half the phone" length instead of
    // stretching to fill whatever row it's placed in.
    final barWidth = MediaQuery.of(context).size.width * 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        // Flexible (not a fixed SizedBox) so this caps out at barWidth but
        // still shrinks instead of overflowing in tighter contexts, like
        // the opponent row that also has a mini board next to it.
        Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: barWidth),
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
      ],
    );
  }
}
