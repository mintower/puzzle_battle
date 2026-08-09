import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_battle/ui/result_screen.dart';

void main() {
  testWidgets('ResultScreen shows the outcome and move/time stats',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ResultScreen(
        playerWon: true,
        elapsed: Duration(seconds: 42),
        playerMoves: 10,
        aiMoves: 15,
      ),
    ));

    expect(find.text('승리!'), findsOneWidget);
    expect(find.text('기록: 00:42'), findsOneWidget);
    expect(find.text('내 이동 횟수: 10'), findsOneWidget);
    expect(find.text('AI 이동 횟수: 15'), findsOneWidget);
  });

  testWidgets('ResultScreen shows a loss when the player did not win',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ResultScreen(
        playerWon: false,
        elapsed: Duration(seconds: 10),
        playerMoves: 5,
        aiMoves: 5,
      ),
    ));

    expect(find.text('패배...'), findsOneWidget);
  });

  testWidgets('ResultScreen in solo mode omits the AI line entirely',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ResultScreen(
        solo: true,
        elapsed: Duration(seconds: 30),
        playerMoves: 22,
      ),
    ));

    expect(find.text('완료!'), findsOneWidget);
    expect(find.text('이동 횟수: 22'), findsOneWidget);
    expect(find.textContaining('AI'), findsNothing);
  });
}
