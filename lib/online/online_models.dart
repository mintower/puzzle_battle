import 'package:cloud_firestore/cloud_firestore.dart';

/// One player's reported progress within an [OnlineRoom]. [total] is the
/// number of non-blank tiles on the board, so [ratio] is directly
/// comparable to the local progress bar math used for the AI match screen.
class PlayerProgress {
  final int correct;
  final int total;
  final bool finished;
  final DateTime? finishedAt;

  /// The player's current board tiles, if they've reported at least one
  /// move — lets the opponent render a live read-only mini board. `null`
  /// before the first move (or for older rooms from before this field
  /// existed).
  final List<int>? tiles;

  const PlayerProgress({
    required this.correct,
    required this.total,
    required this.finished,
    this.finishedAt,
    this.tiles,
  });

  double get ratio => total == 0 ? 0 : correct / total;

  factory PlayerProgress.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PlayerProgress(correct: 0, total: 1, finished: false);
    }
    final finishedAt = map['finishedAt'];
    final rawTiles = map['tiles'];
    return PlayerProgress(
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 1,
      finished: map['finished'] as bool? ?? false,
      finishedAt: finishedAt is Timestamp ? finishedAt.toDate() : null,
      tiles: rawTiles is List
          ? rawTiles.map((t) => (t as num).toInt()).toList()
          : null,
    );
  }
}

/// A Firestore-backed race room: both players share [size]/[seed] (so each
/// generates an identical board locally) and report their own progress
/// into [progress], keyed by uid.
class OnlineRoom {
  final String code;
  final int size;
  final int seed;
  final String hostUid;
  final String? guestUid;
  final String status; // 'waiting' | 'active'
  final Map<String, PlayerProgress> progress;

  /// Last heartbeat timestamp per uid, used to detect a player who left
  /// (closed the tab) without the app getting a chance to signal it.
  final Map<String, DateTime> presence;

  /// Display nickname per uid, set when a player creates/joins/matches
  /// into the room.
  final Map<String, String> names;

  /// Bumped each time both players vote to rematch — clients watch for
  /// this to know a fresh round has started in the same room.
  final int round;

  /// Which uids have voted to rematch for the *next* round.
  final Map<String, bool> rematchVotes;

  /// Total attacks *received* by each uid so far (monotonically
  /// increasing). A client compares this against the last count it's
  /// already applied locally to detect and react to new incoming attacks.
  final Map<String, int> attackCount;

  const OnlineRoom({
    required this.code,
    required this.size,
    required this.seed,
    required this.hostUid,
    required this.guestUid,
    required this.status,
    required this.progress,
    required this.presence,
    required this.names,
    required this.round,
    required this.rematchVotes,
    required this.attackCount,
  });

  bool get hasGuest => guestUid != null;

  String? opponentUidFor(String myUid) =>
      myUid == hostUid ? guestUid : hostUid;

  String nameFor(String uid, {String fallback = ''}) => names[uid] ?? fallback;

  factory OnlineRoom.fromMap(String code, Map<String, dynamic> data) {
    final rawProgress = (data['progress'] as Map<String, dynamic>?) ?? const {};
    final rawPresence = (data['presence'] as Map<String, dynamic>?) ?? const {};
    final rawNames = (data['names'] as Map<String, dynamic>?) ?? const {};
    final rawVotes = (data['rematchVotes'] as Map<String, dynamic>?) ?? const {};
    final rawAttacks = (data['attackCount'] as Map<String, dynamic>?) ?? const {};
    return OnlineRoom(
      code: code,
      size: (data['size'] as num).toInt(),
      seed: (data['seed'] as num).toInt(),
      hostUid: data['hostUid'] as String,
      guestUid: data['guestUid'] as String?,
      status: data['status'] as String? ?? 'waiting',
      progress: rawProgress.map(
        (uid, value) => MapEntry(
          uid,
          PlayerProgress.fromMap(value as Map<String, dynamic>?),
        ),
      ),
      presence: rawPresence.map(
        (uid, value) => MapEntry(
          uid,
          value is Timestamp ? value.toDate() : DateTime.fromMillisecondsSinceEpoch(0),
        ),
      ),
      names: rawNames.map((uid, value) => MapEntry(uid, value as String)),
      round: (data['round'] as num?)?.toInt() ?? 0,
      rematchVotes: rawVotes.map((uid, value) => MapEntry(uid, value as bool)),
      attackCount: rawAttacks.map(
        (uid, value) => MapEntry(uid, (value as num).toInt()),
      ),
    );
  }
}
