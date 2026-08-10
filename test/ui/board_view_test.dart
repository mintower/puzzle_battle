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

  testWidgets(
      'in picture mode, tiles show artwork slices instead of numbers, and taps still report position',
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
            tileStyle: TileStyle.picture,
            onTileTap: (index) => tappedIndex = index,
          ),
        ),
      ),
    ));

    expect(find.text('1'), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.tapAt(const Offset(280, 280)); // tile '8' at index 8
    await tester.pump();

    expect(tappedIndex, 8);
  });

  testWidgets(
      'a locked tile shows a lock icon and does not report taps, but other '
      'tiles remain tappable', (tester) async {
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
            lockedTileValues: const {8},
          ),
        ),
      ),
    ));

    expect(find.byIcon(Icons.lock), findsOneWidget);

    // The lock overlay visually covers the tile's own text, so the tap
    // lands on the overlay rather than the Text widget underneath — both
    // are inside the same (disabled) InkWell, so the effect is the same.
    await tester.tap(find.text('8'), warnIfMissed: false);
    await tester.pump();
    expect(tappedIndex, isNull);

    await tester.tap(find.text('7')); // unlocked tile — still works
    await tester.pump();
    expect(tappedIndex, 6);
  });
}
