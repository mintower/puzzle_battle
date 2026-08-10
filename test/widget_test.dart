import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_battle/main.dart';
import 'package:puzzle_battle/ui/ai_setup_screen.dart';
import 'package:puzzle_battle/ui/match_screen.dart';
import 'package:puzzle_battle/ui/practice_screen.dart';

void main() {
  testWidgets(
      'Main menu renders nickname and the three ways to play, with AI '
      "difficulty tucked away behind the AI match button (not shown until "
      "you're inside it)", (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());

    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('실시간 온라인 대전'), findsOneWidget);
    expect(find.text('AI와 대전 시작'), findsOneWidget);
    expect(find.text('연습 모드 (혼자 풀기)'), findsOneWidget);
    expect(find.text('AI 난이도'), findsNothing);
  });

  testWidgets(
      'Tapping "AI와 대전 시작" opens the AI difficulty picker, and starting '
      'from there begins a 4x4 match', (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());
    await tester.tap(find.text('AI와 대전 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AiSetupScreen), findsOneWidget);
    expect(find.text('AI 난이도'), findsOneWidget);
    expect(find.byType(MatchScreen), findsNothing);

    await tester.tap(find.text('대전 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MatchScreen), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    // Player's own row is labeled with their nickname (defaults to
    // '플레이어' when nothing has been typed into the field yet).
    expect(find.text('플레이어'), findsOneWidget);
    expect(find.text('이동 횟수: 0'), findsOneWidget);
    // A 4x4 board's highest tile is 15; a 3x3 board would top out at 8.
    expect(find.text('15'), findsOneWidget);

    // The match screen runs a periodic timer and an AI move loop; drain
    // them before the test ends so flutter_test doesn't flag a pending
    // Timer. Unmounting cancels the periodic timer, and mounted-checks
    // inside the AI loop let its in-flight delayed move resolve safely.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets(
      'typing a nickname and starting a match through the AI setup screen '
      'shows that nickname, not the stale value from startup (regression: '
      'GameSetupPanel is built inline with the nickname baked in as a '
      'constructor param, so editing the field must trigger a rebuild or '
      'the typed name never reaches it)', (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());
    await tester.enterText(find.byType(TextField), '민토');
    await tester.pump();

    await tester.tap(find.text('AI와 대전 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('대전 시작'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MatchScreen), findsOneWidget);
    // Scoped to MatchScreen: the nickname TextField (still holding "민토"
    // underneath, in the now-unmounted-in-spirit-but-not-disposed
    // MainMenuScreen) would otherwise also match.
    expect(
      find.descendant(of: find.byType(MatchScreen), matching: find.text('민토')),
      findsOneWidget,
    );
    expect(find.text('플레이어'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Tapping practice mode navigates to a solo board with no AI',
      (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());
    await tester.tap(find.text('연습 모드 (혼자 풀기)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PracticeScreen), findsOneWidget);
    expect(find.text('이동 횟수: 0'), findsOneWidget);
    expect(find.text('AI'), findsNothing);

    // Only a periodic timer runs here (no AI loop), but drain it anyway.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
