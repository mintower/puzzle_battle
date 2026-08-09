import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/core/puzzle_board.dart';
import 'package:puzzle_battle/core/puzzle_shuffler.dart';
import 'package:puzzle_battle/core/puzzle_solver.dart';

/// Applies [moveCount] random legal moves from the solved state, never
/// immediately undoing the previous move. Keeps the resulting board's
/// optimal solution short and the search fast, which is what we want for
/// a deterministic 4x4 test (a fully random 4x4 shuffle can require a
/// worst-case-slow search with a plain Manhattan heuristic).
PuzzleBoard _lightlyShuffled(int size, int moveCount, Random random) {
  var board = PuzzleBoard.solved(size);
  int? banned;
  for (var i = 0; i < moveCount; i++) {
    final options = board.availableMoves.where((m) => m != banned).toList();
    final choice = options[random.nextInt(options.length)];
    banned = board.emptyIndex;
    board = board.move(choice)!;
  }
  return board;
}

void main() {
  group('PuzzleSolver', () {
    test('returns an empty plan for an already-solved board', () {
      final board = PuzzleBoard.solved(3);
      expect(PuzzleSolver.solve(board), isEmpty);
    });

    test('finds a solution that actually solves a shuffled 3x3 board', () {
      final board = PuzzleShuffler.generate(size: 3, seed: 5);
      final plan = PuzzleSolver.solve(board);
      expect(plan, isNotNull);

      var current = board;
      for (final move in plan!) {
        final next = current.move(move);
        expect(next, isNotNull, reason: 'solver produced an illegal move');
        current = next!;
      }
      expect(current.isSolved, isTrue);
    });

    test('finds the known optimal single move for a one-move-away board',
        () {
      // One legal move away from solved: blank at index 7, tile 8 at index 8.
      final board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      final plan = PuzzleSolver.solve(board);
      expect(plan, [8]);
    });

    test('solves lightly shuffled 4x4 boards quickly', () {
      final random = Random(9);
      for (var trial = 0; trial < 5; trial++) {
        final board = _lightlyShuffled(4, 12, random);
        final plan = PuzzleSolver.solve(board, maxDepth: 30);
        expect(plan, isNotNull);

        var current = board;
        for (final move in plan!) {
          current = current.move(move)!;
        }
        expect(current.isSolved, isTrue);
      }
    });
  });

  group('PuzzleSolver.greedyMove', () {
    test('always returns one of the board\'s currently legal moves', () {
      final random = Random(3);
      var board = PuzzleShuffler.generate(size: 4, seed: 1);
      for (var i = 0; i < 50; i++) {
        final move = PuzzleSolver.greedyMove(board, random);
        expect(board.availableMoves, contains(move));
        board = board.move(move)!;
      }
    });

    test('never picks avoidMove when another legal move exists', () {
      final random = Random(3);
      final board = PuzzleShuffler.generate(size: 4, seed: 1);
      final banned = board.availableMoves.first;
      for (var i = 0; i < 20; i++) {
        final move = PuzzleSolver.greedyMove(board, random, avoidMove: banned);
        expect(move, isNot(banned));
      }
    });

    test('picks the only move that strictly reduces heuristic distance',
        () {
      // One move away from solved: moving tile at index 8 finishes the
      // board, so greedyMove must pick it over the other legal move.
      final board = PuzzleBoard(size: 3, tiles: [1, 2, 3, 4, 5, 6, 7, 0, 8]);
      final move = PuzzleSolver.greedyMove(board, Random(0));
      expect(move, 8);
    });
  });
}
