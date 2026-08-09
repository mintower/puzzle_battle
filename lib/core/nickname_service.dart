import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A nickname persisted on-device (not tied to the anonymous Firebase auth
/// uid, which can change if the browser clears storage). Used to show a
/// real name instead of "나"/"상대" in online matches.
class NicknameService {
  static const _key = 'nickname';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = '플레이어${1000 + Random().nextInt(9000)}';
    await prefs.setString(_key, generated);
    return generated;
  }

  static Future<void> setNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = nickname.trim();
    if (trimmed.isEmpty) return;
    await prefs.setString(_key, trimmed);
  }
}
