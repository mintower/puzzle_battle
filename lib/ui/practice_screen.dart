import 'dart:async';

import 'package:flutter/material.dart';

import '../core/puzzle_session.dart';
import 'board_view.dart';
import 'puzzle_artwork.dart';
import 'result_screen.dart';

/// Solo mode: no AI, no race — just the puzzle, a timer, and a move
/// counter, for getting a feel for the sliding mechanic.
class PracticeScreen extends StatefulWidget {
  final int boardSize;
  final TileStyle tileStyle;

  const PracticeScreen({
    super.key,
    required this.boardSize,
    this.tileStyle = TileStyle.numbers,
  });

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late final PuzzleSession _session;
  final _stopwatch = Stopwatch();
  Timer? _tickTimer;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _session = PuzzleSession(
      size: widget.boardSize,
      seed: DateTime.now().millisecondsSinceEpoch,
    );
    _stopwatch.start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  void _handleTileTap(int tileIndex) {
    if (!_session.tryMove(tileIndex)) return;
    setState(() {});

    if (_session.isComplete && !_navigatedToResult) {
      _navigatedToResult = true;
      _stopwatch.stop();
      _tickTimer?.cancel();
      final elapsed = _stopwatch.elapsed;
      final moves = _session.moveCount;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => ResultScreen(
            solo: true,
            elapsed: elapsed,
            playerMoves: moves,
          ),
        ));
      });
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(title: Text('$minutes:$seconds')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('이동 횟수: ${_session.moveCount}'),
                if (widget.tileStyle == TileStyle.picture)
                  const PuzzlePreviewThumbnail(),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: BoardView(
                    board: _session.board,
                    onTileTap: _handleTileTap,
                    tileStyle: widget.tileStyle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
