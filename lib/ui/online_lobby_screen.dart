import 'dart:async';

import 'package:flutter/material.dart';

import '../online/match_repository.dart';
import 'board_view.dart';
import 'online_match_screen.dart';

enum _LobbyState { idle, creatingRoom, waitingForGuest, joiningRoom, queued, error }

/// Entry point for real-time online play: create a room and share the
/// code, join with a code a friend shared, or drop into the public queue
/// to be paired with whoever else is waiting.
class OnlineLobbyScreen extends StatefulWidget {
  final int boardSize;
  final TileStyle tileStyle;

  const OnlineLobbyScreen({
    super.key,
    required this.boardSize,
    this.tileStyle = TileStyle.numbers,
  });

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _repo = MatchRepository();
  final _codeController = TextEditingController();
  _LobbyState _state = _LobbyState.idle;
  String? _roomCode;
  String? _errorMessage;
  String? _uid;
  bool _navigated = false;
  StreamSubscription<dynamic>? _watchSub;
  Timer? _queuePollTimer;

  Future<String> _uidOrSignIn() async {
    _uid ??= await MatchRepository.currentUid();
    return _uid!;
  }

  void _goToMatch(String code, String uid) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _watchSub?.cancel();
    _queuePollTimer?.cancel();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => OnlineMatchScreen(
        roomCode: code,
        myUid: uid,
        tileStyle: widget.tileStyle,
      ),
    ));
  }

  Future<void> _createRoom() async {
    setState(() {
      _state = _LobbyState.creatingRoom;
      _errorMessage = null;
    });
    try {
      final uid = await _uidOrSignIn();
      final code = await _repo.createRoom(size: widget.boardSize, hostUid: uid);
      if (!mounted) return;
      setState(() {
        _roomCode = code;
        _state = _LobbyState.waitingForGuest;
      });
      _watchSub = _repo.watchRoom(code).listen(
        (room) {
          if (room.hasGuest) _goToMatch(code, uid);
        },
        onError: _showError,
      );
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _joinRoom() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _state = _LobbyState.joiningRoom;
      _errorMessage = null;
    });
    try {
      final uid = await _uidOrSignIn();
      await _repo.joinRoom(code: code, guestUid: uid);
      _goToMatch(code, uid);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _joinPublicQueue() async {
    setState(() {
      _state = _LobbyState.queued;
      _errorMessage = null;
    });
    try {
      final uid = await _uidOrSignIn();
      final styleName = widget.tileStyle.name;
      await _repo.joinQueue(uid: uid, size: widget.boardSize, tileStyle: styleName);

      _watchSub = _repo.watchQueueMatch(uid).listen(
        (code) {
          if (code != null) _goToMatch(code, uid);
        },
        onError: _showError,
      );

      _queuePollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          final code = await _repo.tryFindMatch(
            uid: uid,
            size: widget.boardSize,
            tileStyle: styleName,
          );
          if (code != null) _goToMatch(code, uid);
        } catch (e) {
          _queuePollTimer?.cancel();
          _showError(e);
        }
      });
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    setState(() {
      _state = _LobbyState.error;
      _errorMessage = e.toString().replaceFirst('StateError: ', '');
    });
  }

  void _cancel() {
    _watchSub?.cancel();
    _queuePollTimer?.cancel();
    if (_state == _LobbyState.queued && _uid != null) {
      _repo.leaveQueue(_uid!);
    }
    setState(() {
      _state = _LobbyState.idle;
      _errorMessage = null;
      _roomCode = null;
    });
  }

  @override
  void dispose() {
    _watchSub?.cancel();
    _queuePollTimer?.cancel();
    if (_state == _LobbyState.queued && _uid != null) {
      _repo.leaveQueue(_uid!);
    }
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('실시간 온라인 대전')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LobbyState.waitingForGuest:
        return _WaitingPanel(
          title: '친구에게 이 코드를 알려주세요',
          detail: _roomCode ?? '',
          detailIsCode: true,
          onCancel: _cancel,
        );
      case _LobbyState.queued:
        return _WaitingPanel(
          title: '매칭 상대를 찾는 중...',
          detail: '같은 보드 크기(${widget.boardSize}x${widget.boardSize})·'
              '같은 타일 모양(${widget.tileStyle == TileStyle.picture ? '그림' : '숫자'})으로\n'
              '대기 중인 상대와 자동으로 연결됩니다.',
          detailIsCode: false,
          onCancel: _cancel,
        );
      case _LobbyState.creatingRoom:
      case _LobbyState.joiningRoom:
        return const Center(child: CircularProgressIndicator());
      case _LobbyState.idle:
      case _LobbyState.error:
        return _IdleForm(
          boardSize: widget.boardSize,
          codeController: _codeController,
          errorMessage: _errorMessage,
          onCreateRoom: _createRoom,
          onJoinRoom: _joinRoom,
          onJoinQueue: _joinPublicQueue,
        );
    }
  }
}

class _IdleForm extends StatelessWidget {
  final int boardSize;
  final TextEditingController codeController;
  final String? errorMessage;
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;
  final VoidCallback onJoinQueue;

  const _IdleForm({
    required this.boardSize,
    required this.codeController,
    required this.errorMessage,
    required this.onCreateRoom,
    required this.onJoinRoom,
    required this.onJoinQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorMessage != null) ...[
          SelectableText(errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
        ],
        FilledButton(
          onPressed: onJoinQueue,
          child: const Text('공개 매칭 시작'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: onCreateRoom,
          child: const Text('방 만들기'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: codeController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '친구가 알려준 코드 입력',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: onJoinRoom,
          child: const Text('코드로 참가'),
        ),
      ],
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  final String title;
  final String detail;
  final bool detailIsCode;
  final VoidCallback onCancel;

  const _WaitingPanel({
    required this.title,
    required this.detail,
    required this.detailIsCode,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        if (detailIsCode)
          Text(
            detail,
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 4),
          )
        else
          Text(detail, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        TextButton(onPressed: onCancel, child: const Text('취소')),
      ],
    );
  }
}
