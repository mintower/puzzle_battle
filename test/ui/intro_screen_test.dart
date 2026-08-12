import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_battle/ui/intro_screen.dart';
import 'package:puzzle_battle/ui/main_menu_screen.dart';

void main() {
  testWidgets('IntroScreen shows the app name and advances to the main menu on tap',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntroScreen()));

    expect(find.text('15-puzzle vs.'), findsOneWidget);
    expect(find.byType(MainMenuScreen), findsNothing);

    await tester.tap(find.byType(IntroScreen));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MainMenuScreen), findsOneWidget);
  });

  testWidgets('IntroScreen advances to the main menu on its own after a short delay',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IntroScreen()));

    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MainMenuScreen), findsOneWidget);
  });
}
