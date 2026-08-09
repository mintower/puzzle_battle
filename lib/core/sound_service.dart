import 'package:audioplayers/audioplayers.dart';

/// Short UI sound effects (tile move, win, lose).
///
/// Each sound keeps one persistent, pre-loaded [AudioPlayer] instead of
/// creating a fresh player (and re-fetching the asset) on every play.
/// That matters on web: browsers only allow audio playback triggered
/// directly by a user gesture, and the async delay of fetching+decoding
/// an asset from scratch on every tap is often enough to make strict
/// browsers (iOS Safari especially) silently drop the call as no longer
/// "user-initiated". Pre-loading once and just calling [seek]+[resume]
/// keeps the actual play call close to instant.
class SoundService {
  static final _move = _Sound('sounds/move.wav');
  static final _win = _Sound('sounds/win.wav');
  static final _lose = _Sound('sounds/lose.wav');

  /// Pre-loads every sound. Safe to call more than once (a no-op after
  /// the first successful load). Call this once early (e.g. from `main`)
  /// so gameplay taps never have to wait on a network fetch.
  static Future<void> warmUp() {
    return Future.wait([_move.load(), _win.load(), _lose.load()]);
  }

  static Future<void> playMove() => _move.play();
  static Future<void> playWin() => _win.play();
  static Future<void> playLose() => _lose.play();
}

class _Sound {
  final String _assetPath;
  final AudioPlayer _player = AudioPlayer();
  bool _loaded = false;

  _Sound(this._assetPath) {
    _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      await _player.setSourceAsset(_assetPath);
      await _player.setVolume(1.0);
      _loaded = true;
    } catch (_) {
      // Will just retry lazily from play() below.
    }
  }

  Future<void> play() async {
    try {
      if (!_loaded) await load();
      await _player.seek(Duration.zero);
      await _player.resume();
    } catch (_) {
      // Sound is a nice-to-have; never let playback failures break gameplay.
    }
  }
}
