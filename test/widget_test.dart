import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_battle/main.dart';
import 'package:puzzle_battle/ui/match_screen.dart';
import 'package:puzzle_battle/ui/practice_screen.dart';

void main() {
  testWidgets('Main menu renders board size and difficulty controls',
      (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());

    expect(find.text('AI와 대전 시작'), findsOneWidget);
    expect(find.text('3x3'), findsOneWidget);
    expect(find.text('4x4'), findsOneWidget);
  });

  testWidgets('Tapping start navigates to the match screen', (tester) async {
    await tester.pumpWidget(const PuzzleBattleApp());
    await tester.tap(find.text('AI와 대전 시작'));
    await tester.pump(); // start the push transition
    await tester.pump(const Duration(milliseconds: 300)); // finish it

    expect(find.byType(MatchScreen), findsOneWidget);
    expect(find.text('AI'), findsOneWidget);
    expect(find.text('나'), findsOneWidget);
    expect(find.text('이동 횟수: 0'), findsOneWidget);

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
}
