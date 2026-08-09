import 'package:flutter/material.dart';

import '../core/ai_opponent.dart';
import '../core/nickname_service.dart';
import 'board_view.dart';
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
  TileStyle _tileStyle = TileStyle.numbers;
  final _nicknameController = TextEditingController();

  AiDifficultyProfile get _difficulty => switch (_difficultyLabel) {
        'Easy' => AiDifficultyProfile.easy,
        'Hard' => AiDifficultyProfile.hard,
        _ => AiDifficultyProfile.medium,
      };

  @override
  void initState() {
    super.initState();
    NicknameService.getOrCreate().then((name) {
      if (!mounted) return;
      setState(() => _nicknameController.text = name);
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  String get _nickname {
    final trimmed = _nicknameController.text.trim();
    return trimmed.isEmpty ? '플레이어' : trimmed;
  }

  /// Scales the label down to fit its segment instead of wrapping or
  /// clipping when the segment is narrower than the text (e.g. "어려움"
  /// in a 3-way segmented button at phone width).
  Widget _segmentLabel(String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, softWrap: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('슬라이딩 퍼즐 대전')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('닉네임', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nicknameController,
                  maxLength: 12,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    counterText: '',
                    hintText: '온라인 대전에서 표시될 이름',
                  ),
                  onChanged: (value) => NicknameService.setNickname(value),
                ),
                const SizedBox(height: 16),
                const Text('보드 크기', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 3, label: _segmentLabel('3x3')),
                    ButtonSegment(value: 4, label: _segmentLabel('4x4')),
                    ButtonSegment(value: 5, label: _segmentLabel('5x5')),
                  ],
                  selected: {_boardSize},
                  onSelectionChanged: (s) => setState(() => _boardSize = s.first),
                ),
                const SizedBox(height: 24),
                const Text('타일 모양', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<TileStyle>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: TileStyle.numbers, label: _segmentLabel('숫자')),
                    ButtonSegment(value: TileStyle.picture, label: _segmentLabel('그림')),
                  ],
                  selected: {_tileStyle},
                  onSelectionChanged: (s) => setState(() => _tileStyle = s.first),
                ),
                const SizedBox(height: 24),
                const Text('AI 난이도', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'Easy', label: _segmentLabel('쉬움')),
                    ButtonSegment(value: 'Medium', label: _segmentLabel('보통')),
                    ButtonSegment(value: 'Hard', label: _segmentLabel('어려움')),
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
                        tileStyle: _tileStyle,
                      ),
                    ));
                  },
                  child: const Text('AI와 대전 시작'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PracticeScreen(
                        boardSize: _boardSize,
                        tileStyle: _tileStyle,
                      ),
                    ));
                  },
                  child: const Text('연습 모드 (혼자 풀기)'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => OnlineLobbyScreen(
                        boardSize: _boardSize,
                        tileStyle: _tileStyle,
                        nickname: _nickname,
                      ),
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
