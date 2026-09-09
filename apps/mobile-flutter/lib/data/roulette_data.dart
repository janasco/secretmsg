import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class RouletteCategory {
  final String key;
  final String label;
  final List<String> prompts;
  const RouletteCategory(this.key, this.label, this.prompts);
}

/// Loads the prompt pool from `assets/roulette_prompts.json`.
///
/// These 9,000 prompts used to be compiled Dart constants, which put roughly
/// 1.7 MB of strings into the AOT snapshot of every ABI and kept them resident
/// from launch — for one screen most people never open. As an asset they are
/// stored once and read only when the dice screen is opened.
///
/// The asset holds only the six real categories. "All Vibes" was previously a
/// second, verbatim copy of all of them, doubling the payload for nothing, so
/// it is rebuilt here from the others instead.
class RouletteData {
  RouletteData._();

  static const _assetPath = 'assets/roulette_prompts.json';
  static const allKey = 'all';
  static const allLabel = 'All Vibes';

  static List<RouletteCategory>? _cache;
  static Future<List<RouletteCategory>>? _pending;

  /// Cached after the first read, so reopening the screen is instant.
  static Future<List<RouletteCategory>> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final pending = _pending ??= _read();
    try {
      return await pending;
    } catch (_) {
      // Drop the failed future so a retry can actually try again.
      _pending = null;
      rethrow;
    }
  }

  static Future<List<RouletteCategory>> _read() async {
    final decoded = jsonDecode(await rootBundle.loadString(_assetPath)) as List<dynamic>;

    final categories = <RouletteCategory>[];
    final everything = <String>[];

    for (final entry in decoded) {
      final map = entry as Map<String, dynamic>;
      final prompts = List<String>.unmodifiable(
        (map['prompts'] as List<dynamic>).cast<String>(),
      );
      everything.addAll(prompts);
      categories.add(
        RouletteCategory(map['key'] as String, map['label'] as String, prompts),
      );
    }

    final result = List<RouletteCategory>.unmodifiable([
      RouletteCategory(allKey, allLabel, List<String>.unmodifiable(everything)),
      ...categories,
    ]);

    _cache = result;
    _pending = null;
    return result;
  }
}
