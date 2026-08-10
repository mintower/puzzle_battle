import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/puzzle_board.dart';
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
/// size/seed. Each move reports progress (correct-tile ratio + the full
/// tile array, for the opponent's mini board preview) — still far cheaper
/// than a dedicated realtime server.
///
/// Combo/attack: 3 consecutive moves that each raise your correct-tile
/// count charge 1 attack. Firing an attack applies a few random moves to
/// the opponent's board (detected via [OnlineRoom.attackCount] ticking up)
/// — it costs nothing to sync since each side scrambles its own board
/// locally rather than the attacker dictating exact tile positions.
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
  static const _maxAttackCharges = 3;
  static const _movesPerAttack = 3;
  static const _comboPerCharge = 3;

  final _repo = MatchRepository();
  final _random = Random();
  StreamSubscription<OnlineRoom>? _roomSub;
  PuzzleSession? _session;
  OnlineRoom? _room;
  final _stopwatch = Stopwatch();
  Timer? _tickTimer;
  Timer? _heartbeatTimer;
  bool _navigatedToResult = false;
  int _attackCharges = 0;
  int _lastSeenAttackCount = 0;

  @override
  void initState() {
    super.initState();
    _roomSub = _repo.watchRoom(widget.roomCode).listen(_onRoom);
  }

  void _onRoom(OnlineRoom room) {
    setState(() => _room = room);

    if (_session == null) {
      _session = PuzzleSession(size: room.size, seed: room.seed);
      _lastSeenAttackCount = room.attackCount[widget.myUid] ?? 0;
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
    } else {
      _checkForIncomingAttack(room);
    }

    final opponentUid = room.opponentUidFor(widget.myUid);
    final opponentProgress =
        opponentUid == null ? null : room.progress[opponentUid];
    if (opponentProgress?.finished == true) {
      _endMatch(playerWon: false);
    }
  }

  /// Reacts to [OnlineRoom.attackCount] going up since we last checked by
  /// scrambling our own board — the attacker never dictates our exact
  /// tiles, just how many disruption moves land.
  void _checkForIncomingAttack(OnlineRoom room) {
    if (_navigatedToResult) return;
    final session = _session;
    if (session == null) return;
    final myAttacks = room.attackCount[widget.myUid] ?? 0;
    if (myAttacks <= _lastSeenAttackCount) return;
    final delta = myAttacks - _lastSeenAttackCount;
    _lastSeenAttackCount = myAttacks;
    session.applyDisruption(delta * _movesPerAttack, _random);
    setState(() {});
    _reportProgress();
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

    if (session.combo > 0 &&
        session.combo % _comboPerCharge == 0 &&
        _attackCharges < _maxAttackCharges) {
      _attackCharges++;
    }
    setState(() {});
    _reportProgress();

    if (session.isComplete) {
      _endMatch(playerWon: true);
    }
  }

  void _fireAttack() {
    final room = _room;
    final opponentUid = room?.opponentUidFor(widget.myUid);
    if (_attackCharges <= 0 || opponentUid == null) return;
    setState(() => _attackCharges--);
    _repo.sendAttack(code: widget.roomCode, targetUid: opponentUid);
  }

  void _reportProgress() {
    final session = _session;
    if (session == null) return;
    _repo.reportProgress(
      code: widget.roomCode,
      uid: widget.myUid,
      correct: session.board.correctTileCount,
      total: session.board.tiles.length - 1,
      finished: session.isComplete,
      tiles: session.board.tiles,
    );
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
          onRematch: () => OnlineRematchWaitingScreen(
            roomCode: widget.roomCode,
            myUid: widget.myUid,
            tileStyle: widget.tileStyle,
            nickname: widget.nickname,
          ),
        ),
      ));
    });
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
    final opponentTiles = opponentProgress.tiles;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (opponentTiles != null &&
                    opponentTiles.length == room.size * room.size)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: BoardView(
                        board: PuzzleBoard(size: room.size, tiles: opponentTiles),
                        tileStyle: widget.tileStyle,
                      ),
                    ),
                  ),
                Expanded(
                  child: ProgressRow(
                    label: opponentName,
                    progress: opponentProgress.ratio,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressRow(
              label: myName,
              progress: session.board.correctTileCount / (session.board.tiles.length - 1),
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '콤보 x${session.combo}  ·  이동 ${session.moveCount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _maxAttackCharges; i++)
                      Icon(
                        Icons.bolt,
                        size: 20,
                        color: i < _attackCharges
                            ? Colors.orange
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _attackCharges > 0 ? _fireAttack : null,
                      child: const Text('공격!'),
                    ),
                  ],
                ),
              ],
            ),
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
