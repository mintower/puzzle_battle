import 'package:cloud_firestore/cloud_firestore.dart';

/// One player's reported progress within an [OnlineRoom]. [total] is the
/// number of non-blank tiles on the board, so [ratio] is directly
/// comparable to the local progress bar math used for the AI match screen.
class PlayerProgress {
  final int correct;
  final int total;
  final bool finished;
  final DateTime? finishedAt;

  const PlayerProgress({
    required this.correct,
    required this.total,
    required this.finished,
    this.finishedAt,
  });

  double get ratio => total == 0 ? 0 : correct / total;

  factory PlayerProgress.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const PlayerProgress(correct: 0, total: 1, finished: false);
    }
    final finishedAt = map['finishedAt'];
    return PlayerProgress(
      correct: (map['correct'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 1,
      finished: map['finished'] as bool? ?? false,
      finishedAt: finishedAt is Timestamp ? finishedAt.toDate() : null,
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

  const OnlineRoom({
    required this.code,
    required this.size,
    required this.seed,
    required this.hostUid,
    required this.guestUid,
    required this.status,
    required this.progress,
  });

  bool get hasGuest => guestUid != null;

  String? opponentUidFor(String myUid) =>
      myUid == hostUid ? guestUid : hostUid;

  factory OnlineRoom.fromMap(String code, Map<String, dynamic> data) {
    final rawProgress = (data['progress'] as Map<String, dynamic>?) ?? const {};
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
    );
  }
}
