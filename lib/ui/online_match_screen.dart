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
/// size/seed. Each move also reports the full tile array, so the
/// opponent's progress row can show a small live read-only board preview
/// — still far cheaper than a dedicated realtime server.
///
/// Attack gauge: completing one of the board's 4 quadrants charges 1
/// attack (see [PuzzleSession.checkNewlyCompletedQuadrants]). Firing
/// either sends a shuffle (scrambles a 2x2 window of the opponent's
/// board) or a lock (freezes 1-2 of their misplaced tiles for 5 of their
/// own moves) — detected via [OnlineRoom.shuffleAttacks]/[lockAttacks]
/// ticking up, then applied locally by the target's own client, so no
/// board-state sync is needed for the attack itself.
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
  static const _lockTurns = 5;

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
  int _lastSeenShuffleAttacks = 0;
  int _lastSeenLockAttacks = 0;

  @override
  void initState() {
    super.initState();
    _roomSub = _repo.watchRoom(widget.roomCode).listen(_onRoom);
  }

  void _onRoom(OnlineRoom room) {
    setState(() => _room = room);

    if (_session == null) {
      _session = PuzzleSession(size: room.size, seed: room.seed);
      _session!.checkNewlyCompletedQuadrants(); // establish the baseline
      _lastSeenShuffleAttacks = room.shuffleAttacks[widget.myUid] ?? 0;
      _lastSeenLockAttacks = room.lockAttacks[widget.myUid] ?? 0;
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
      _checkForIncomingAttacks(room);
    }

    final opponentUid = room.opponentUidFor(widget.myUid);
    final opponentProgress =
        opponentUid == null ? null : room.progress[opponentUid];
    if (opponentProgress?.finished == true) {
      _endMatch(playerWon: false);
    }
  }

  /// Reacts to [OnlineRoom.shuffleAttacks]/[lockAttacks] going up since we
  /// last checked by applying the corresponding effect to our own board —
  /// the attacker never dictates our exact tiles, just that an attack of
  /// a given type landed.
  void _checkForIncomingAttacks(OnlineRoom room) {
    if (_navigatedToResult) return;
    final session = _session;
    if (session == null) return;

    final shuffles = room.shuffleAttacks[widget.myUid] ?? 0;
    final locks = room.lockAttacks[widget.myUid] ?? 0;
    var changed = false;

    if (shuffles > _lastSeenShuffleAttacks) {
      final delta = shuffles - _lastSeenShuffleAttacks;
      _lastSeenShuffleAttacks = shuffles;
      for (var i = 0; i < delta; i++) {
        session.applyShuffle(_random);
      }
      changed = true;
    }
    if (locks > _lastSeenLockAttacks) {
      final delta = locks - _lastSeenLockAttacks;
      _lastSeenLockAttacks = locks;
      for (var i = 0; i < delta; i++) {
        session.applyIncomingLock(_random, turns: _lockTurns);
      }
      changed = true;
    }

    if (changed) {
      _grantChargesForCompletedQuadrants();
      setState(() {});
      _reportProgress();
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

  void _grantChargesForCompletedQuadrants() {
    final newlyCompleted = _session!.checkNewlyCompletedQuadrants();
    if (newlyCompleted <= 0) return;
    _attackCharges =
        min(_attackCharges + newlyCompleted, _maxAttackCharges);
  }

  void _handleTileTap(int tileIndex) {
    final session = _session;
    if (session == null || _navigatedToResult) return;
    if (!session.tryMove(tileIndex)) return;
    SoundService.playMove();

    _grantChargesForCompletedQuadrants();
    setState(() {});
    _reportProgress();

    if (session.isComplete) {
      _endMatch(playerWon: true);
    }
  }

  void _fireShuffleAttack() {
    final opponentUid = _room?.opponentUidFor(widget.myUid);
    if (_attackCharges <= 0 || opponentUid == null) return;
    setState(() => _attackCharges--);
    _repo.sendShuffleAttack(code: widget.roomCode, targetUid: opponentUid);
  }

  void _fireLockAttack() {
    final opponentUid = _room?.opponentUidFor(widget.myUid);
    if (_attackCharges <= 0 || opponentUid == null) return;
    setState(() => _attackCharges--);
    _repo.sendLockAttack(code: widget.roomCode, targetUid: opponentUid);
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

  Widget _quadrantIndicator(List<bool> status) {
    Widget dot(bool done) => Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: done ? Colors.green : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [dot(status[0]), dot(status[1])]),
        Row(mainAxisSize: MainAxisSize.min, children: [dot(status[2]), dot(status[3])]),
      ],
    );
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

    final referenceThumbnail = widget.tileStyle == TileStyle.picture
        ? const PuzzlePreviewThumbnail(size: 40)
        : null;
    final opponentMiniBoard =
        opponentTiles != null && opponentTiles.length == room.size * room.size
            ? SizedBox(
                width: 56,
                height: 56,
                child: BoardView(
                  board: PuzzleBoard(size: room.size, tiles: opponentTiles),
                  tileStyle: widget.tileStyle,
                ),
              )
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('$minutes:$seconds'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ProgressRow(
              label: opponentName,
              progress: opponentProgress.ratio,
              color: Colors.redAccent,
              leading: opponentMiniBoard,
              trailing: referenceThumbnail,
            ),
            const SizedBox(height: 8),
            ProgressRow(
              label: myName,
              progress: session.board.correctTileCount / (session.board.tiles.length - 1),
              color: Colors.blueAccent,
              trailing: referenceThumbnail,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _quadrantIndicator(session.quadrantStatus),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '구역 완성 시 공격 게이지 충전 · 이동 ${session.moveCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                for (var i = 0; i < _maxAttackCharges; i++)
                  Icon(
                    Icons.bolt,
                    size: 20,
                    color: i < _attackCharges
                        ? Colors.orange
                        : Theme.of(context).colorScheme.outlineVariant,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _attackCharges > 0 ? _fireShuffleAttack : null,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('셔플 공격'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _attackCharges > 0 ? _fireLockAttack : null,
                    icon: const Icon(Icons.lock),
                    label: const Text('잠금 공격'),
                  ),
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
                    lockedTileValues: session.lockedTiles.keys.toSet(),
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
