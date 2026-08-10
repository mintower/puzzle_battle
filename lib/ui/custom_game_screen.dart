import 'package:flutter/material.dart';

import 'game_setup_panel.dart';

/// Off the main screen (which is a fixed 4x4 "15-puzzle vs."), this is
/// where the non-standard board sizes live.
class CustomGameScreen extends StatefulWidget {
  final String nickname;

  const CustomGameScreen({super.key, required this.nickname});

  @override
  State<CustomGameScreen> createState() => _CustomGameScreenState();
}

class _CustomGameScreenState extends State<CustomGameScreen> {
  int _boardSize = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('커스텀 게임')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('보드 크기', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 3, label: segmentLabel('3x3')),
                    ButtonSegment(value: 5, label: segmentLabel('5x5')),
                  ],
                  selected: {_boardSize},
                  onSelectionChanged: (s) => setState(() => _boardSize = s.first),
                ),
                const SizedBox(height: 24),
                GameSetupPanel(boardSize: _boardSize, nickname: widget.nickname),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
