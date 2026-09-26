library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import 'ads_config.dart';

typedef AdsFlagFetcher = Future<bool?> Function();
typedef AdsFlagClock = DateTime Function();

class AdsFlagSnapshot {
  final bool enabled;
  final DateTime fetchedAt;

  const AdsFlagSnapshot({required this.enabled, required this.fetchedAt});
}

class AdsFlagCache {
  AdsFlagCache._();

  static Future<AdsFlagSnapshot?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(kAdsFlagsKey);
      final at = prefs.getInt(kAdsFlagsFetchedAtKey);
      if (enabled == null || at == null) return null;
      return AdsFlagSnapshot(
        enabled: enabled,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(at),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(bool enabled, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(kAdsFlagsKey, enabled);
      await prefs.setInt(kAdsFlagsFetchedAtKey, now.millisecondsSinceEpoch);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kAdsFlagsKey);
      await prefs.remove(kAdsFlagsFetchedAtKey);
    } catch (_) {}
  }
}

class AdsFlagResolver {
  final AdsFlagFetcher fetcher;
  final AdsFlagClock clock;
  final Duration maxAge;

  AdsFlagResolver({
    AdsFlagFetcher? fetcher,
    AdsFlagClock? clock,
    this.maxAge = kAdsFlagsMaxAge,
  })  : fetcher = fetcher ?? ApiClient.getAdsEnabled,
        clock = clock ?? DateTime.now;

  Future<bool> resolve() async {
    final cached = await AdsFlagCache.read();
    if (cached != null &&
        clock().difference(cached.fetchedAt) < maxAge) {
      return cached.enabled;
    }
    try {
      final fresh = await fetcher();
      if (fresh != null) {
        await AdsFlagCache.write(fresh, clock());
        return fresh;
      }
    } catch (_) {}
    if (cached != null) return cached.enabled;
    return kAdsEnabledWithoutServerFlag;
  }
}
