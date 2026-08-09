import 'package:flutter/material.dart';

import 'ui/main_menu_screen.dart';

void main() {
  runApp(const PuzzleBattleApp());
}

class PuzzleBattleApp extends StatelessWidget {
  const PuzzleBattleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '슬라이딩 퍼즐 대전',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
