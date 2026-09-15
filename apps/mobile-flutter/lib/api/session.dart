import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

const _kTokenKey = 'secretmsg_auth_token';
const _kProfileKey = 'secretmsg_user_profile';
const _kDeviceFpKey = 'secretmsg_device_fingerprint';
const _kLastRankKey = 'secretmsg_last_seen_rank';
const _kStreakKey = 'secretmsg_streak';
const _kDayKey = 'secretmsg_day_snapshot';
const _kBadgesKey = 'secretmsg_badges';
const _kDonePrefix = 'secretmsg_chdone_';

const _fpChars =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

class Session {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String?> getToken() async {
    return _storage.read(key: _kTokenKey);
  }

  static Future<void> setToken(String token) async {
    await _storage.write(key: _kTokenKey, value: token);
  }

  static Future<void> saveUser(UserProfile user) async {
    await _storage.write(
      key: _kProfileKey,
      value: jsonEncode(user.toJson()),
    );
  }

  static Future<UserProfile?> getSavedUser() async {
    try {
      final raw = await _storage.read(key: _kProfileKey);
      if (raw == null) return null;
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    await _storage.delete(key: _kTokenKey);
    await _storage.delete(key: _kProfileKey);
  }

  /// Last rank tier celebrated for an account, stored as "userId|tier" so a
  /// different login never triggers a bogus rank-up celebration.
  static Future<String?> getLastSeenRank() async {
    return _storage.read(key: _kLastRankKey);
  }

  static Future<void> setLastSeenRank(String userId, String tier) async {
    await _storage.write(key: _kLastRankKey, value: '$userId|$tier');
  }

  // ---- Gamification stores (all scoped per account where relevant) ----
  static Future<Map<String, dynamic>?> _readJson(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    await _storage.write(key: key, value: jsonEncode(value));
  }

  static Future<Map<String, dynamic>?> getStreak() => _readJson(_kStreakKey);
  static Future<void> setStreak(Map<String, dynamic> value) =>
      _writeJson(_kStreakKey, value);

  static Future<Map<String, dynamic>?> getDaySnapshot() => _readJson(_kDayKey);
  static Future<void> setDaySnapshot(Map<String, dynamic> value) =>
      _writeJson(_kDayKey, value);

  static Future<Map<String, dynamic>?> getBadges() => _readJson(_kBadgesKey);
  static Future<void> setBadges(Map<String, dynamic> value) =>
      _writeJson(_kBadgesKey, value);

  static Future<List<String>> getDoneChallenges(String date) async {
    final doc = await _readJson('$_kDonePrefix$date');
    final list = doc?['ids'];
    if (list is List) return list.map((e) => e.toString()).toList();
    return <String>[];
  }

  static Future<void> setDoneChallenges(String date, List<String> ids) async {
    await _writeJson('$_kDonePrefix$date', {'ids': ids});
  }

  static Future<void> updateSavedUser(UserProfile user) async {
    await saveUser(user);
  }

  // Stable anonymous device fingerprint for sender blocking. Generated once
  // per install, stored in secure storage, never shared with or revealed to
  // recipients - the server keeps only its SHA-256.
  static Future<String> getDeviceFingerprint() async {
    final existing = await _storage.read(key: _kDeviceFpKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final rand = Random.secure();
    final fp = List.generate(32, (_) => _fpChars[rand.nextInt(_fpChars.length)]).join();
    await _storage.write(key: _kDeviceFpKey, value: fp);
    return fp;
  }

  static Future<void> clearDeviceFingerprint() async {
    await _storage.delete(key: _kDeviceFpKey);
  }
}