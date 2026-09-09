import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

const _kTokenKey = 'secretmsg_auth_token';
const _kProfileKey = 'secretmsg_user_profile';

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

  static Future<void> updateSavedUser(UserProfile user) async {
    await saveUser(user);
  }
}