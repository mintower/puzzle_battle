import 'dart:async';

import 'package:flutter/material.dart';

import '../online/match_repository.dart';
import '../online/online_models.dart';
import 'board_view.dart';
import 'online_match_screen.dart';

/// Shown after tapping "다시하기" in an online match. Votes to rematch,
/// then waits for the opponent to do the same — [MatchRepository] only
/// actually resets the room (new seed, cleared progress) once both sides
/// have voted, so both clients land on a fresh [OnlineMatchScreen]
/// together instead of one silently restarting underneath the other.
class OnlineRematchWaitingScreen extends StatefulWidget {
  final String roomCode;
  final String myUid;
  final TileStyle tileStyle;
  final String nickname;

  const OnlineRematchWaitingScreen({
    super.key,
    required this.roomCode,
    required this.myUid,
    required this.tileStyle,
    required this.nickname,
  });

  @override
  State<OnlineRematchWaitingScreen> createState() =>
      _OnlineRematchWaitingScreenState();
}

class _OnlineRematchWaitingScreenState
    extends State<OnlineRematchWaitingScreen> {
  final _repo = MatchRepository();
  StreamSubscription<OnlineRoom>? _sub;
  int? _startingRound;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _repo.voteRematch(code: widget.roomCode, uid: widget.myUid);
    _sub = _repo.watchRoom(widget.roomCode).listen(_onRoom);
  }

  void _onRoom(OnlineRoom room) {
    _startingRound ??= room.round;

    if (room.round > _startingRound!) {
      _goToMatch();
      return;
    }

    final opponentUid = room.opponentUidFor(widget.myUid);
    if (opponentUid == null) return;

    // Opportunistically resolve the rematch — safe for both clients to
    // call; MatchRepository only actually resets once both have voted.
    _repo.resolveRematchIfReady(
      code: widget.roomCode,
      hostUid: room.hostUid,
      guestUid: opponentUid,
    );
  }

  void _goToMatch() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _sub?.cancel();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OnlineMatchScreen(
        roomCode: widget.roomCode,
        myUid: widget.myUid,
        tileStyle: widget.tileStyle,
        nickname: widget.nickname,
      ),
    ));
  }

  void _cancel() {
    _repo.clearRematchVote(code: widget.roomCode, uid: widget.myUid);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('상대의 재대결 수락을 기다리는 중...', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            TextButton(onPressed: _cancel, child: const Text('취소')),
          ],
        ),
      ),
    );
  }
}
