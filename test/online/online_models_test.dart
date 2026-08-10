import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_battle/online/online_models.dart';

void main() {
  group('PlayerProgress', () {
    test('fromMap(null) defaults to zero progress, not finished', () {
      final progress = PlayerProgress.fromMap(null);
      expect(progress.correct, 0);
      expect(progress.total, 1);
      expect(progress.finished, isFalse);
      expect(progress.ratio, 0);
    });

    test('fromMap reads correct/total/finished and computes ratio', () {
      final progress = PlayerProgress.fromMap({
        'correct': 6,
        'total': 8,
        'finished': false,
      });
      expect(progress.ratio, 0.75);
    });

    test('fromMap converts a Firestore Timestamp to DateTime', () {
      final timestamp = Timestamp.fromMillisecondsSinceEpoch(1000);
      final progress = PlayerProgress.fromMap({
        'correct': 8,
        'total': 8,
        'finished': true,
        'finishedAt': timestamp,
      });
      expect(progress.finished, isTrue);
      expect(progress.finishedAt, timestamp.toDate());
    });

    test('tiles is null when absent (older rooms, or before the first move)',
        () {
      expect(PlayerProgress.fromMap(null).tiles, isNull);
      expect(PlayerProgress.fromMap({'correct': 0, 'total': 8}).tiles, isNull);
    });

    test('fromMap parses tiles for the opponent mini-board preview', () {
      final progress = PlayerProgress.fromMap({
        'correct': 1,
        'total': 8,
        'tiles': [1, 2, 3, 4, 5, 6, 7, 0, 8],
      });
      expect(progress.tiles, [1, 2, 3, 4, 5, 6, 7, 0, 8]);
    });
  });

  group('OnlineRoom', () {
    OnlineRoom buildRoom({String? guestUid}) {
      return OnlineRoom.fromMap('1234', {
        'size': 3,
        'seed': 42,
        'hostUid': 'host-uid',
        'guestUid': guestUid,
        'status': guestUid == null ? 'waiting' : 'active',
        'progress': {
          'host-uid': {'correct': 2, 'total': 8, 'finished': false},
        },
      });
    }

    test('hasGuest is false while waiting for an opponent', () {
      expect(buildRoom().hasGuest, isFalse);
      expect(buildRoom(guestUid: 'guest-uid').hasGuest, isTrue);
    });

    test('opponentUidFor returns the other player\'s uid', () {
      final room = buildRoom(guestUid: 'guest-uid');
      expect(room.opponentUidFor('host-uid'), 'guest-uid');
      expect(room.opponentUidFor('guest-uid'), 'host-uid');
    });

    test('parses per-player progress from the raw map', () {
      final room = buildRoom(guestUid: 'guest-uid');
      expect(room.progress['host-uid']!.ratio, 0.25);
      expect(room.progress.containsKey('guest-uid'), isFalse);
    });

    test('round and names default sensibly when absent from older rooms',
        () {
      final room = buildRoom(guestUid: 'guest-uid');
      expect(room.round, 0);
      expect(room.nameFor('host-uid', fallback: '나'), '나');
    });

    test('parses names and round when present', () {
      final room = OnlineRoom.fromMap('1234', {
        'size': 3,
        'seed': 42,
        'hostUid': 'host-uid',
        'guestUid': 'guest-uid',
        'status': 'active',
        'progress': <String, dynamic>{},
        'names': {'host-uid': '민토', 'guest-uid': '친구'},
        'round': 2,
      });
      expect(room.nameFor('host-uid'), '민토');
      expect(room.nameFor('guest-uid'), '친구');
      expect(room.round, 2);
    });

    test('shuffleAttacks/lockAttacks default to empty and parse when present',
        () {
      final defaultRoom = buildRoom(guestUid: 'guest-uid');
      expect(defaultRoom.shuffleAttacks, isEmpty);
      expect(defaultRoom.lockAttacks, isEmpty);

      final room = OnlineRoom.fromMap('1234', {
        'size': 3,
        'seed': 42,
        'hostUid': 'host-uid',
        'guestUid': 'guest-uid',
        'status': 'active',
        'progress': <String, dynamic>{},
        'shuffleAttacks': {'guest-uid': 2},
        'lockAttacks': {'host-uid': 1},
      });
      expect(room.shuffleAttacks['guest-uid'], 2);
      expect(room.shuffleAttacks['host-uid'], isNull);
      expect(room.lockAttacks['host-uid'], 1);
      expect(room.lockAttacks['guest-uid'], isNull);
    });
  });
}
