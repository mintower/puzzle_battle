import 'package:flutter/material.dart';

/// Shown after a match (win/loss against the AI) or a solo practice round
/// (set [solo] to true, in which case [playerWon] and [aiMoves] are
/// ignored/omitted).
class ResultScreen extends StatelessWidget {
  final bool solo;
  final bool playerWon;
  final Duration elapsed;
  final int playerMoves;
  final int? aiMoves;
  final String? note;

  /// When set, shows a rematch button that navigates to whatever screen
  /// this builds. Takes a builder (not a bare navigation callback) so the
  /// push happens with *this* screen's own BuildContext — a callback built
  /// back in the previous (now-disposed) screen would capture a context
  /// that's no longer valid by the time the button is actually tapped.
  final Widget Function()? onRematch;

  const ResultScreen({
    super.key,
    this.solo = false,
    this.playerWon = false,
    required this.elapsed,
    required this.playerMoves,
    this.aiMoves,
    this.note,
    this.onRematch,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final title = solo ? '완료!' : (playerWon ? '승리!' : '패배...');

    final IconData icon;
    final Color badgeColor;
    if (solo) {
      icon = Icons.flag_circle_rounded;
      badgeColor = scheme.primary;
    } else if (playerWon) {
      icon = Icons.emoji_events_rounded;
      badgeColor = const Color(0xFFF59E0B);
    } else {
      icon = Icons.sentiment_dissatisfied_rounded;
      badgeColor = scheme.error;
    }

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 38, color: badgeColor),
                ),
                const SizedBox(height: 20),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (note != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    note!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        _StatRow(label: '기록', value: '$minutes:$seconds'),
                        _StatRow(
                          label: solo ? '이동 횟수' : '내 이동 횟수',
                          value: '$playerMoves',
                        ),
                        if (aiMoves != null)
                          _StatRow(label: 'AI 이동 횟수', value: '$aiMoves', last: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (onRematch != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => onRematch!(),
                        ));
                      },
                      child: const Text('다시하기'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('메인으로'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _StatRow({required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: scheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
