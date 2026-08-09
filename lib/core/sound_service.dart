import 'package:audioplayers/audioplayers.dart';

/// Short UI sound effects (tile move, win, lose). Each call plays a fresh
/// [AudioPlayer] instance so overlapping plays (e.g. rapid tile taps)
/// don't cut each other off.
class SoundService {
  static Future<void> playMove() => _play('move.wav');
  static Future<void> playWin() => _play('win.wav');
  static Future<void> playLose() => _play('lose.wav');

  static Future<void> _play(String assetFile) async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('sounds/$assetFile'));
      player.onPlayerComplete.first.then((_) => player.dispose());
    } catch (_) {
      // Sound is a nice-to-have; never let playback failures break gameplay.
    }
  }
}
