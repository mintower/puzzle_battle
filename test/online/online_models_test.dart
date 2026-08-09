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
  });
}
