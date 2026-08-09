import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/firebase_options.dart';
import 'ui/main_menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
