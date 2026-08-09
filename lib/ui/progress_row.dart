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
    return Row(
      children: [
        SizedBox(width: 32, child: Text(label)),
        Expanded(
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
      ],
    );
  }
}
