import 'dart:async';

import 'package:flutter/material.dart';

import 'main_menu_screen.dart';
import 'puzzle_logo.dart';

/// Brief branded intro shown once at app launch, before the main menu.
/// Advances automatically after a short delay, or immediately on tap —
/// it's a beat of polish, not a gate, so it never blocks the player.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  static const _autoAdvanceDelay = Duration(milliseconds: 1800);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _autoAdvance;
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _autoAdvance = Timer(_autoAdvanceDelay, _enterApp);
  }

  void _enterApp() {
    if (_entered || !mounted) return;
    _entered = true;
    _autoAdvance?.cancel();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const MainMenuScreen(),
    ));
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enterApp,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PuzzleLogoMark(size: 96),
                const SizedBox(height: 28),
                Text(
                  '15-puzzle vs.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '밀어서 맞추고, 실시간으로 겨루세요',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: scheme.primary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
