import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_battle/core/puzzle_board.dart';
import 'package:puzzle_battle/ui/board_view.dart';

void main() {
  testWidgets(
      'BoardView renders one tile per non-blank value and reports taps by board position',
      (tester) async {
    final board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    int? tappedIndex;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 300,
          child: BoardView(
            board: board,
            onTileTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    ));

    for (var value = 1; value <= 8; value++) {
      expect(find.text('$value'), findsOneWidget);
    }
    expect(find.text('0'), findsNothing);

    // Tile '8' sits at board index 8, adjacent to the blank at index 7.
    await tester.tap(find.text('8'));
    await tester.pump();

    expect(tappedIndex, 8);
  });
}
