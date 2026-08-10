import 'package:flutter/material.dart';

import '../core/ai_opponent.dart';
import 'board_view.dart';
import 'match_screen.dart';
import 'online_lobby_screen.dart';
import 'practice_screen.dart';

/// Scales a segmented-button label down to fit its segment instead of
/// wrapping or clipping when the segment is narrower than the text (e.g.
/// "어려움" in a 3-way segmented button at phone width).
Widget segmentLabel(String text) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, softWrap: false),
  );
}

/// Tile style picker and the three ways to start a 4x4 game.
class GameSetupPanel extends StatefulWidget {
  static const _boardSize = 4;

  final String nickname;

  const GameSetupPanel({super.key, required this.nickname});

  @override
  State<GameSetupPanel> createState() => _GameSetupPanelState();
}

class _GameSetupPanelState extends State<GameSetupPanel> {
  TileStyle _tileStyle = TileStyle.numbers;
  String _difficultyLabel = 'Medium';

  AiDifficultyProfile get _difficulty => switch (_difficultyLabel) {
        'Easy' => AiDifficultyProfile.easy,
        'Hard' => AiDifficultyProfile.hard,
        _ => AiDifficultyProfile.medium,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('타일 모양', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<TileStyle>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: TileStyle.numbers, label: segmentLabel('숫자')),
            ButtonSegment(value: TileStyle.picture, label: segmentLabel('그림')),
          ],
          selected: {_tileStyle},
          onSelectionChanged: (s) => setState(() => _tileStyle = s.first),
        ),
        const SizedBox(height: 32),
        // Primary call to action — real-time online play is the default
        // mode, so it's the highlighted (filled) button, placed first.
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OnlineLobbyScreen(
                boardSize: GameSetupPanel._boardSize,
                tileStyle: _tileStyle,
                nickname: widget.nickname,
              ),
            ));
          },
          child: const Text('실시간 온라인 대전'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MatchScreen(
                boardSize: GameSetupPanel._boardSize,
                difficulty: _difficulty,
                tileStyle: _tileStyle,
                nickname: widget.nickname,
              ),
            ));
          },
          child: const Text('AI와 대전 시작'),
        ),
        const SizedBox(height: 8),
        // AI 난이도 is a sub-choice of "AI와 대전 시작" specifically (it has
        // no effect on online or practice mode), so it sits right under
        // that button instead of applying to the whole panel up top.
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 난이도',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: 'Easy', label: segmentLabel('쉬움')),
                  ButtonSegment(value: 'Medium', label: segmentLabel('보통')),
                  ButtonSegment(value: 'Hard', label: segmentLabel('어려움')),
                ],
                selected: {_difficultyLabel},
                onSelectionChanged: (s) => setState(() => _difficultyLabel = s.first),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PracticeScreen(
                boardSize: GameSetupPanel._boardSize,
                tileStyle: _tileStyle,
              ),
            ));
          },
          child: const Text('연습 모드 (혼자 풀기)'),
        ),
      ],
    );
  }
}
