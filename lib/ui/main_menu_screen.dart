import 'package:flutter/material.dart';

import '../core/nickname_service.dart';
import 'game_setup_panel.dart';
import 'puzzle_logo.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PuzzleLogoMark(size: 72),
                  const SizedBox(height: 16),
                  Text('15-puzzle vs.', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(
                    '밀어서 맞추고, 실시간으로 겨루세요',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('닉네임', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nicknameController,
                            maxLength: 12,
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: '온라인 대전에서 표시될 이름',
                            ),
                            onChanged: (value) {
                              NicknameService.setNickname(value);
                              // GameSetupPanel below is built with the
                              // current _nickname value baked in as a
                              // constructor param, so without a rebuild
                              // here it keeps showing whatever nickname
                              // was loaded at startup instead of what's
                              // just been typed.
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GameSetupPanel(nickname: _nickname),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
