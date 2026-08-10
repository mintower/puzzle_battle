import 'package:flutter/material.dart';

import '../core/nickname_service.dart';
import 'custom_game_screen.dart';
import 'game_setup_panel.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  static const _defaultBoardSize = 4;

  final _nicknameController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('15-puzzle vs.')),
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
                  onChanged: (value) {
                    NicknameService.setNickname(value);
                    // GameSetupPanel below is built with the current
                    // _nickname value baked in as a constructor param, so
                    // without a rebuild here it keeps showing whatever
                    // nickname was loaded at startup instead of what's
                    // just been typed.
                    setState(() {});
                  },
                ),
                const SizedBox(height: 24),
                GameSetupPanel(
                  boardSize: _defaultBoardSize,
                  nickname: _nickname,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CustomGameScreen(nickname: _nickname),
                    ));
                  },
                  child: const Text('커스텀 게임 (3x3 / 5x5)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
