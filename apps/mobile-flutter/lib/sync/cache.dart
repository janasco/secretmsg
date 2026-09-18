/// Inbox snapshot cache: last good server state, rendered instantly on
/// cold start and when offline, then replaced by a fresh fetch.
///
/// Snapshots are advisory (server wins on every sync); they only ever make
/// the app feel instant and stay useful with no network.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../api/models.dart';

const String _kInboxKey = 'cache_inbox_v1';
const String _kTrayKey = 'cache_tray_v1';
const String _kSavedAtKey = 'cache_saved_at_v1';

class InboxSnapshot {
  final List<AnonymousMessage> messages;
  final List<AnonymousMessage> tray;
  final DateTime savedAt;

  const InboxSnapshot({
    required this.messages,
    required this.tray,
    required this.savedAt,
  });
}

class InboxCache {
  InboxCache._();

  static Future<void> save(
      List<AnonymousMessage> messages, List<AnonymousMessage> tray) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kInboxKey, jsonEncode(messages.map((m) => m.toJson()).toList()));
      await prefs.setString(
          _kTrayKey, jsonEncode(tray.map((m) => m.toJson()).toList()));
      await prefs.setInt(
          _kSavedAtKey, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Drops snapshots (logout / account switch: cached mail belongs to the
  /// previous owner and must never leak across accounts).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kInboxKey);
      await prefs.remove(_kTrayKey);
      await prefs.remove(_kSavedAtKey);
    } catch (_) {}
  }

  static Future<InboxSnapshot?> load() async {    try {
      final prefs = await SharedPreferences.getInstance();
      final rawInbox = prefs.getString(_kInboxKey);
      final savedAtMs = prefs.getInt(_kSavedAtKey);
      if (rawInbox == null || rawInbox.isEmpty || savedAtMs == null) {
        return null;
      }
      List<AnonymousMessage> parse(String? raw) {
        if (raw == null || raw.isEmpty) return const [];
        return (jsonDecode(raw) as List)
            .whereType<Map<String, dynamic>>()
            .map(AnonymousMessage.fromJson)
            .where((m) => m.id.isNotEmpty)
            .toList();
      }

      return InboxSnapshot(
        messages: parse(rawInbox),
        tray: parse(prefs.getString(_kTrayKey)),
        savedAt: DateTime.fromMillisecondsSinceEpoch(savedAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  /// Human staleness label: "just now", "5m ago", "3h ago", "2d ago".
  static String stalenessLabel(DateTime savedAt, DateTime now) {    final diff = now.difference(savedAt);
    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
