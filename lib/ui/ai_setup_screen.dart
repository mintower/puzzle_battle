import 'package:flutter/material.dart';

import '../core/ai_opponent.dart';
import 'board_view.dart';
import 'game_setup_panel.dart' show segmentLabel;
import 'match_screen.dart';

/// Shown after tapping "AI와 대전 시작" — picking a difficulty is specific
/// to the AI match, so it lives behind that button instead of sitting on
/// the main menu where it'd apply to online/practice modes too.
class AiSetupScreen extends StatefulWidget {
  static const _boardSize = 4;

  final TileStyle tileStyle;
  final String nickname;

  const AiSetupScreen({
    super.key,
    required this.tileStyle,
    required this.nickname,
  });

  @override
  State<AiSetupScreen> createState() => _AiSetupScreenState();
}

class _AiSetupScreenState extends State<AiSetupScreen> {
  String _difficultyLabel = 'Medium';

  AiDifficultyProfile get _difficulty => switch (_difficultyLabel) {
        'Easy' => AiDifficultyProfile.easy,
        'Hard' => AiDifficultyProfile.hard,
        _ => AiDifficultyProfile.medium,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI와 대전')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AI 난이도', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                const SizedBox(height: 32),
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MatchScreen(
                        boardSize: AiSetupScreen._boardSize,
                        difficulty: _difficulty,
                        tileStyle: widget.tileStyle,
                        nickname: widget.nickname,
                      ),
                    ));
                  },
                  child: const Text('대전 시작'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
