import 'dart:async';

import 'package:flutter/material.dart';

import '../core/puzzle_session.dart';
import '../core/sound_service.dart';
import '../online/match_repository.dart';
import '../online/online_models.dart';
import 'board_view.dart';
import 'online_rematch_waiting_screen.dart';
import 'progress_row.dart';
import 'puzzle_artwork.dart';
import 'result_screen.dart';

/// Live race against a real opponent, synced through Firestore. Both
/// clients build an identical [PuzzleSession] from the room's shared
/// size/seed and only exchange progress (correct-tile ratio + a finished
/// flag) — never full board state — which is what keeps this cheap enough
/// to run without a dedicated realtime server.
class OnlineMatchScreen extends StatefulWidget {
  final String roomCode;
  final String myUid;
  final TileStyle tileStyle;
  final String nickname;

  const OnlineMatchScreen({
    super.key,
    required this.roomCode,
    required this.myUid,
    this.tileStyle = TileStyle.numbers,
    this.nickname = '플레이어',
  });

  @override
  State<OnlineMatchScreen> createState() => _OnlineMatchScreenState();
}

class _OnlineMatchScreenState extends State<OnlineMatchScreen> {
  static const _heartbeatInterval = Duration(seconds: 5);
  static const _opponentTimeout = Duration(seconds: 12);

  final _repo = MatchRepository();
  StreamSubscription<OnlineRoom>? _roomSub;
  PuzzleSession? _session;
  OnlineRoom? _room;
  final _stopwatch = Stopwatch();
  Timer? _tickTimer;
  Timer? _heartbeatTimer;
  bool _navigatedToResult = false;

  @override
  void initState() {
    super.initState();
    _roomSub = _repo.watchRoom(widget.roomCode).listen(_onRoom);
  }

  void _onRoom(OnlineRoom room) {
    setState(() => _room = room);

    if (_session == null) {
      _session = PuzzleSession(size: room.size, seed: room.seed);
      _stopwatch.start();
      _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (!mounted) return;
        setState(() {});
        _checkOpponentAlive();
      });
      _repo.sendHeartbeat(code: widget.roomCode, uid: widget.myUid);
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
        _repo.sendHeartbeat(code: widget.roomCode, uid: widget.myUid);
      });
    }

    final opponentUid = room.opponentUidFor(widget.myUid);
    final opponentProgress =
        opponentUid == null ? null : room.progress[opponentUid];
    if (opponentProgress?.finished == true) {
      _endMatch(playerWon: false);
    }
  }

  /// Detects an opponent who left mid-match (closing a tab never gets a
  /// chance to signal it) by watching for their heartbeat going stale.
  /// Runs off the existing 100ms tick rather than the room stream, since a
  /// stopped heartbeat produces no new Firestore snapshot to react to.
  void _checkOpponentAlive() {
    if (_navigatedToResult) return;
    final room = _room;
    if (room == null) return;
    final opponentUid = room.opponentUidFor(widget.myUid);
    if (opponentUid == null) return;
    final lastSeen = room.presence[opponentUid];
    if (lastSeen == null) return; // haven't heard from them yet — don't guess
    if (DateTime.now().difference(lastSeen) > _opponentTimeout) {
      _endMatch(playerWon: true, note: '상대가 나가서 승리했습니다.');
    }
  }

  void _handleTileTap(int tileIndex) {
    final session = _session;
    if (session == null || _navigatedToResult) return;
    if (!session.tryMove(tileIndex)) return;
    SoundService.playMove();
    setState(() {});

    final tiles = session.board.tiles;
    final total = tiles.length - 1;
    var correct = 0;
    for (var i = 0; i < total; i++) {
      if (tiles[i] == i + 1) correct++;
    }
    _repo.reportProgress(
      code: widget.roomCode,
      uid: widget.myUid,
      correct: correct,
      total: total,
      finished: session.isComplete,
    );

    if (session.isComplete) {
      _endMatch(playerWon: true);
    }
  }

  void _endMatch({required bool playerWon, String? note}) {
    if (_navigatedToResult) return;
    _navigatedToResult = true;
    _stopwatch.stop();
    _tickTimer?.cancel();
    _heartbeatTimer?.cancel();
    playerWon ? SoundService.playWin() : SoundService.playLose();
    final elapsed = _stopwatch.elapsed;
    final myMoves = _session?.moveCount ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
          playerWon: playerWon,
          elapsed: elapsed,
          playerMoves: myMoves,
          note: note,
          onRematch: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => OnlineRematchWaitingScreen(
                roomCode: widget.roomCode,
                myUid: widget.myUid,
                tileStyle: widget.tileStyle,
                nickname: widget.nickname,
              ),
            ));
          },
        ),
      ));
    });
  }

  double _myProgress(PuzzleSession session) {
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
    _roomSub?.cancel();
    _tickTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final room = _room;
    if (session == null || room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final opponentUid = room.opponentUidFor(widget.myUid);
    final opponentProgress = (opponentUid == null
        ? null
        : room.progress[opponentUid]) ??
        const PlayerProgress(correct: 0, total: 1, finished: false);
    final opponentName =
        opponentUid == null ? '상대' : room.nameFor(opponentUid, fallback: '상대');
    final myName = room.nameFor(widget.myUid, fallback: '나');

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
              label: opponentName,
              progress: opponentProgress.ratio,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 8),
            ProgressRow(
              label: myName,
              progress: _myProgress(session),
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Text('이동 횟수: ${session.moveCount}'),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: BoardView(
                    board: session.board,
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
