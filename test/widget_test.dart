import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_battle/main.dart';
import 'package:puzzle_battle/ui/custom_game_screen.dart';
import 'package:puzzle_battle/ui/match_screen.dart';
import 'package:puzzle_battle/ui/practice_screen.dart';

void main() {
  testWidgets(
      'Main menu renders nickname, difficulty controls, and a custom-game link '
      '(no inline board-size picker — 4x4 is the fixed default)',
      (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());

    expect(find.text('AI와 대전 시작'), findsOneWidget);
    expect(find.text('닉네임'), findsOneWidget);
    expect(find.text('보드 크기'), findsNothing);
    expect(find.text('커스텀 게임 (3x3 / 5x5)'), findsOneWidget);
  });

  testWidgets('Tapping start navigates to a 4x4 match by default',
      (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());
    await tester.tap(find.text('AI와 대전 시작'));
    await tester.pump(); // start the push transition
    await tester.pump(const Duration(milliseconds: 300)); // finish it

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

  testWidgets(
      'Custom game screen offers only 3x3/5x5 and starts a 3x3 match by default',
      (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());
    // The button sits below the fold on the default test viewport, inside
    // a SingleChildScrollView — scroll it into view before tapping.
    await tester.ensureVisible(find.text('커스텀 게임 (3x3 / 5x5)'));
    await tester.tap(find.text('커스텀 게임 (3x3 / 5x5)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CustomGameScreen), findsOneWidget);
    expect(find.text('3x3'), findsOneWidget);
    expect(find.text('5x5'), findsOneWidget);
    expect(find.text('4x4'), findsNothing);

    // MainMenuScreen (also holding an "AI와 대전 시작" button) stays mounted
    // underneath CustomGameScreen in the Navigator stack, so scope the tap
    // to the current screen instead of matching both.
    await tester.tap(find.descendant(
      of: find.byType(CustomGameScreen),
      matching: find.text('AI와 대전 시작'),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MatchScreen), findsOneWidget);
    // A 3x3 board's highest tile is 8; there is no tile '15' on it.
    expect(find.text('15'), findsNothing);
    expect(find.text('8'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
  });
}
