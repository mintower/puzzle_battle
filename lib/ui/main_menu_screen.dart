import 'package:flutter/material.dart';

import '../core/ai_opponent.dart';
import 'match_screen.dart';
import 'online_lobby_screen.dart';
import 'practice_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _boardSize = 3;
  String _difficultyLabel = 'Medium';

  AiDifficultyProfile get _difficulty => switch (_difficultyLabel) {
        'Easy' => AiDifficultyProfile.easy,
        'Hard' => AiDifficultyProfile.hard,
        _ => AiDifficultyProfile.medium,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('슬라이딩 퍼즐 대전')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('보드 크기', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 3, label: Text('3x3', softWrap: false)),
                    ButtonSegment(value: 4, label: Text('4x4', softWrap: false)),
                    ButtonSegment(value: 5, label: Text('5x5', softWrap: false)),
                  ],
                  selected: {_boardSize},
                  onSelectionChanged: (s) => setState(() => _boardSize = s.first),
                ),
                const SizedBox(height: 24),
                const Text('AI 난이도', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'Easy', label: Text('쉬움', softWrap: false)),
                    ButtonSegment(value: 'Medium', label: Text('보통', softWrap: false)),
                    ButtonSegment(value: 'Hard', label: Text('어려움', softWrap: false)),
                  ],
                  selected: {_difficultyLabel},
                  onSelectionChanged: (s) =>
                      setState(() => _difficultyLabel = s.first),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MatchScreen(
                        boardSize: _boardSize,
                        difficulty: _difficulty,
                      ),
                    ));
                  },
                  child: const Text('AI와 대전 시작'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PracticeScreen(boardSize: _boardSize),
                    ));
                  },
                  child: const Text('연습 모드 (혼자 풀기)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OnlineLobbyScreen(boardSize: _boardSize),
                    ));
                  },
                  child: const Text('실시간 온라인 대전'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
