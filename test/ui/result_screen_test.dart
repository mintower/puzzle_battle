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

  testWidgets('ResultScreen shows an optional note (e.g. opponent left)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ResultScreen(
        playerWon: true,
        elapsed: Duration(seconds: 5),
        playerMoves: 3,
        note: '상대가 나가서 승리했습니다.',
      ),
    ));

    expect(find.text('승리!'), findsOneWidget);
    expect(find.text('상대가 나가서 승리했습니다.'), findsOneWidget);
  });

  testWidgets('ResultScreen without onRematch hides the rematch button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: ResultScreen(
        playerWon: true,
        elapsed: Duration(seconds: 1),
        playerMoves: 1,
      ),
    ));

    expect(find.text('다시하기'), findsNothing);
    expect(find.text('메인으로'), findsOneWidget);
  });

  testWidgets(
      'ResultScreen with onRematch navigates to the returned screen using '
      'its own context (regression: a bare VoidCallback built by the '
      'previous, now-disposed screen silently failed to navigate)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ResultScreen(
        playerWon: true,
        elapsed: const Duration(seconds: 1),
        playerMoves: 1,
        onRematch: () => const Scaffold(body: Text('rematch-screen')),
      ),
    ));

    expect(find.text('다시하기'), findsOneWidget);
    await tester.tap(find.text('다시하기'));
    await tester.pumpAndSettle();

    expect(find.text('rematch-screen'), findsOneWidget);
  });
}
