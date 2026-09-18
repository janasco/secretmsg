import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // In-memory caches: secure-storage reads are slow IPC; the token and
  // fingerprint are read on nearly every request. Cleared with the session.
  static String? _memToken;
  static String? _memFp;

  static Future<String?> getToken() async {
    if (_memToken != null && _memToken!.isNotEmpty) return _memToken;
    final token = await _storage.read(key: _kTokenKey);
    if (token != null && token.isNotEmpty) _memToken = token;
    return token;
  }

  static Future<void> setToken(String token) async {
    _memToken = token;
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
    _memToken = null;
    _memFp = null;
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
  // Plain preferences, not secure storage: game progress is neither secret
  // nor worth the encrypted IPC cost on every inbox load.
  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<Map<String, dynamic>?> _readJson(String key) async {
    try {
      final raw = (await _prefs).getString(key);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeJson(String key, Map<String, dynamic> value) async {
    try {
      await (await _prefs).setString(key, jsonEncode(value));
    } catch (_) {}
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
    if (_memFp != null && _memFp!.isNotEmpty) return _memFp!;
    final existing = await _storage.read(key: _kDeviceFpKey);
    if (existing != null && existing.isNotEmpty) {
      _memFp = existing;
      return existing;
    }

    final rand = Random.secure();
    final fp = List.generate(32, (_) => _fpChars[rand.nextInt(_fpChars.length)]).join();
    await _storage.write(key: _kDeviceFpKey, value: fp);
    _memFp = fp;
    return fp;
  }

  static Future<void> clearDeviceFingerprint() async {
    await _storage.delete(key: _kDeviceFpKey);
  }
}