import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'online_models.dart';

/// Talks to Firestore for room-code and public-queue online matches.
///
/// Matching happens entirely client-side via transactions — there's no
/// Cloud Functions dependency, so this stays on Firebase's free Spark
/// plan. Two clients never write conflicting state because every pairing
/// decision (claiming a room, claiming a queue slot) goes through a
/// transaction that re-checks the relevant field is still unset.
class MatchRepository {
  final FirebaseFirestore _db;

  MatchRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _queue => _db.collection('queue');

  static Future<String> currentUid() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser ?? (await auth.signInAnonymously()).user;
    return user!.uid;
  }

  /// Creates a room with a short, human-typeable code. Retries on the rare
  /// chance of a code collision.
  Future<String> createRoom({required int size, required String hostUid}) async {
    final random = Random();
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = (1000 + random.nextInt(9000)).toString();
      final doc = _rooms.doc(code);
      final created = await _db.runTransaction<bool>((tx) async {
        final snapshot = await tx.get(doc);
        if (snapshot.exists) return false;
        tx.set(doc, {
          'size': size,
          'seed': random.nextInt(1 << 31),
          'hostUid': hostUid,
          'guestUid': null,
          'status': 'waiting',
          'progress': <String, dynamic>{},
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (created) return code;
    }
    throw StateError('방 코드를 만들지 못했습니다. 다시 시도해주세요.');
  }

  /// Joins an existing waiting room. Throws if the code doesn't exist or
  /// is already full.
  Future<void> joinRoom({required String code, required String guestUid}) {
    final doc = _rooms.doc(code);
    return _db.runTransaction((tx) async {
      final snapshot = await tx.get(doc);
      if (!snapshot.exists) {
        throw StateError('존재하지 않는 방 코드입니다.');
      }
      final data = snapshot.data()!;
      if (data['guestUid'] != null) {
        throw StateError('이미 다른 사람이 들어간 방입니다.');
      }
      if (data['hostUid'] == guestUid) {
        throw StateError('자기 자신이 만든 방에는 들어갈 수 없습니다.');
      }
      tx.update(doc, {'guestUid': guestUid, 'status': 'active'});
    });
  }

  Stream<OnlineRoom> watchRoom(String code) {
    return _rooms
        .doc(code)
        .snapshots()
        .map((snap) => OnlineRoom.fromMap(code, snap.data() ?? const {}));
  }

  Future<void> reportProgress({
    required String code,
    required String uid,
    required int correct,
    required int total,
    required bool finished,
  }) {
    return _rooms.doc(code).update({
      'progress.$uid': {
        'correct': correct,
        'total': total,
        'finished': finished,
        if (finished) 'finishedAt': FieldValue.serverTimestamp(),
      },
    });
  }

  /// Public matchmaking: joins the shared pool. Pair with [watchQueueMatch]
  /// (someone else finds us) and periodic [tryFindMatch] calls (we find
  /// someone else) to actually get matched. [tileStyle] is 'numbers' or
  /// 'picture' — players are only paired within the same style.
  Future<void> joinQueue({
    required String uid,
    required int size,
    required String tileStyle,
  }) {
    return _queue.doc(uid).set({
      'uid': uid,
      'size': size,
      'tileStyle': tileStyle,
      'matchedRoomCode': null,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveQueue(String uid) => _queue.doc(uid).delete();

  Stream<String?> watchQueueMatch(String uid) {
    return _queue.doc(uid).snapshots().map((snap) {
      final data = snap.data();
      return data == null ? null : data['matchedRoomCode'] as String?;
    });
  }

  /// One attempt to find and pair with a waiting opponent of the same
  /// board size *and* tile style (numbers only match numbers, picture
  /// only matches picture). Safe to call repeatedly (e.g. every couple
  /// seconds) while sitting in the queue. Returns the new room code if
  /// this call made the match, `null` otherwise.
  Future<String?> tryFindMatch({
    required String uid,
    required int size,
    required String tileStyle,
  }) async {
    final candidates = await _queue
        .where('size', isEqualTo: size)
        .where('tileStyle', isEqualTo: tileStyle)
        .where('matchedRoomCode', isNull: true)
        .orderBy('joinedAt')
        .limit(5)
        .get();

    for (final candidate in candidates.docs) {
      if (candidate.id == uid) continue;
      final roomCode = await _db.runTransaction<String?>((tx) async {
        final mine = await tx.get(_queue.doc(uid));
        final theirs = await tx.get(candidate.reference);
        if (!mine.exists || !theirs.exists) return null;
        if (mine.data()?['matchedRoomCode'] != null) return null;
        if (theirs.data()?['matchedRoomCode'] != null) return null;

        final code = (1000000 + Random().nextInt(8999999)).toString();
        tx.set(_rooms.doc(code), {
          'size': size,
          'seed': Random().nextInt(1 << 31),
          'hostUid': uid,
          'guestUid': candidate.id,
          'status': 'active',
          'progress': <String, dynamic>{},
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(_queue.doc(uid), {'matchedRoomCode': code});
        tx.update(candidate.reference, {'matchedRoomCode': code});
        return code;
      });
      if (roomCode != null) return roomCode;
    }
    return null;
  }
}
