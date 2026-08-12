import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/firebase_options.dart';
import 'ui/app_theme.dart';
import 'ui/intro_screen.dart';

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
      title: '15-puzzle vs.',
      theme: AppTheme.light(),
      home: const IntroScreen(),
    );
  }
}
