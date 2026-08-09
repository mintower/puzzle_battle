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
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final title = solo ? '완료!' : (playerWon ? '승리!' : '패배...');

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note!, style: const TextStyle(color: Colors.grey)),
            ],
            const SizedBox(height: 16),
            Text('기록: $minutes:$seconds'),
            Text(solo ? '이동 횟수: $playerMoves' : '내 이동 횟수: $playerMoves'),
            if (aiMoves != null) Text('AI 이동 횟수: $aiMoves'),
            const SizedBox(height: 32),
            if (onRematch != null) ...[
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => onRematch!(),
                  ));
                },
                child: const Text('다시하기'),
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              child: const Text('메인으로'),
            ),
          ],
        ),
      ),
    );
  }
}
