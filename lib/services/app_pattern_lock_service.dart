import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores a user-drawn unlock pattern (hashed) as an alternative to device biometrics.
class AppPatternLockService {
  static const _hashKey = 'znote_app_pattern_hash_v1';
  static const _saltKey = 'znote_app_pattern_salt_v1';
  static const _preferKey = 'znote_prefer_app_pattern_v1';

  Future<bool> hasPattern() async {
    final p = await SharedPreferences.getInstance();
    return p.containsKey(_hashKey) && p.containsKey(_saltKey);
  }

  Future<bool> getPreferAppPattern() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_preferKey) ?? false;
  }

  Future<void> setPreferAppPattern(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_preferKey, value);
  }

  Future<void> savePattern(List<int> path) async {
    if (path.length < 4) {
      throw ArgumentError('Pattern must connect at least 4 dots.');
    }
    final p = await SharedPreferences.getInstance();
    final salt = base64Url.encode(List<int>.generate(24, (_) => Random.secure().nextInt(256)));
    final hash = _hash(salt, path);
    await p.setString(_saltKey, salt);
    await p.setString(_hashKey, hash);
  }

  Future<bool> verify(List<int> path) async {
    if (path.length < 4) return false;
    final p = await SharedPreferences.getInstance();
    final salt = p.getString(_saltKey);
    final stored = p.getString(_hashKey);
    if (salt == null || stored == null) return false;
    return stored == _hash(salt, path);
  }

  Future<void> clearPattern() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_hashKey);
    await p.remove(_saltKey);
    await p.remove(_preferKey);
  }

  String _hash(String salt, List<int> path) {
    final payload = '$salt:${path.join(",")}';
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
