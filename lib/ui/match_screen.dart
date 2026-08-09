import 'dart:async';

import 'package:flutter/material.dart';

import '../core/ai_opponent.dart';
import '../core/puzzle_match.dart';
import '../core/puzzle_session.dart';
import 'board_view.dart';
import 'progress_row.dart';
import 'puzzle_artwork.dart';
import 'result_screen.dart';

class MatchScreen extends StatefulWidget {
  final int boardSize;
  final AiDifficultyProfile difficulty;
  final TileStyle tileStyle;

  const MatchScreen({
    super.key,
    required this.boardSize,
    required this.difficulty,
    this.tileStyle = TileStyle.numbers,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late final PuzzleSession _playerSession;
  late final PuzzleSession _aiSession;
  late final AiOpponent _ai;
  late final PuzzleMatch _match;
  final _stopwatch = Stopwatch();
  Timer? _tickTimer;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    // Same seed for both sessions: the race only works if player and AI
    // start from an identical board.
    final seed = DateTime.now().millisecondsSinceEpoch;
    _playerSession = PuzzleSession(size: widget.boardSize, seed: seed);
    _aiSession = PuzzleSession(size: widget.boardSize, seed: seed);
    _ai = AiOpponent(session: _aiSession, profile: widget.difficulty);
    _match = PuzzleMatch(player: _playerSession, opponent: _aiSession);

    _stopwatch.start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
    _runAiLoop();
  }

  Future<void> _runAiLoop() async {
    while (mounted && !_match.isOver) {
      final played = await _ai.playNextMove();
      if (!mounted) return;
      setState(() {});
      _checkForMatchEnd();
      if (!played) break;
    }
  }

  void _handleTileTap(int tileIndex) {
    if (_match.isOver) return;
    final applied = _playerSession.tryMove(tileIndex);
    if (applied) {
      setState(() {});
      _checkForMatchEnd();
    }
  }

  void _checkForMatchEnd() {
    if (_navigatedToResult || !_match.isOver) return;
    _navigatedToResult = true;
    _stopwatch.stop();
    _tickTimer?.cancel();
    final elapsed = _stopwatch.elapsed;
    final playerWon = _match.result == MatchResult.playerWon;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
          playerWon: playerWon,
          elapsed: elapsed,
          playerMoves: _playerSession.moveCount,
          aiMoves: _aiSession.moveCount,
        ),
      ));
    });
  }

  double _progressOf(PuzzleSession session) {
    final tiles = session.board.tiles;
    final total = tiles.length - 1;
    var correct = 0;
    for (var i = 0; i < total; i++) {
      if (tiles[i] == i + 1) correct++;
    }
    return correct / total;
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
      appBar: AppBar(
        title: Text('$minutes:$seconds'),
        actions: [
          if (widget.tileStyle == TileStyle.picture)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: PuzzlePreviewThumbnail(size: 40)),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProgressRow(
              label: 'AI',
              progress: _progressOf(_aiSession),
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            ProgressRow(
              label: '나',
              progress: _progressOf(_playerSession),
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Text('이동 횟수: ${_playerSession.moveCount}'),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: BoardView(
                    board: _playerSession.board,
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
