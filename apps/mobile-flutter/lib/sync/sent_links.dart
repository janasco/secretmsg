/// Durable record of reply links for sends that completed through the outbox.
///
/// A queued send can finish long after the composer closed. Keeping only the
/// operation would lose the server's `replyToken` and break the blind-reply
/// loop, so the token is written here as soon as the drain receives it.
///
/// The same store is the client-side guard against re-sending a message the
/// server already accepted: a send whose `clientMsgId` is present is skipped
/// instead of posting a second copy. Only the token, recipient handle, id and
/// timestamp are kept — never the message body.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _kSentLinksKey = 'sent_links_v1';
const int _kMaxStored = 50;

class SentLink {
  final String clientMsgId;
  final String token;
  final String username;
  final int sentAt;

  const SentLink({
    required this.clientMsgId,
    required this.token,
    required this.username,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
        'clientMsgId': clientMsgId,
        'token': token,
        'username': username,
        'sentAt': sentAt,
      };

  factory SentLink.fromJson(Map<String, dynamic> json) => SentLink(
        clientMsgId: json['clientMsgId']?.toString() ?? '',
        token: json['token']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        sentAt: (json['sentAt'] as num?)?.toInt() ?? 0,
      );
}

class SentLinks {
  SentLinks._();

  static Future<List<SentLink>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSentLinksKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(SentLink.fromJson)
          .where((l) => l.token.isNotEmpty && l.clientMsgId.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<SentLink?> find(String clientMsgId) async {
    if (clientMsgId.isEmpty) return null;
    for (final link in await load()) {
      if (link.clientMsgId == clientMsgId) return link;
    }
    return null;
  }

  /// Adds (or replaces) a delivered send. Persisting this before the outbox
  /// operation is removed is what makes a retry safe across app restarts.
  static Future<void> add({
    required String clientMsgId,
    required String token,
    required String username,
  }) async {
    if (clientMsgId.isEmpty || token.isEmpty) return;
    final links = await load();
    links.removeWhere((l) => l.clientMsgId == clientMsgId);
    links.insert(
      0,
      SentLink(
        clientMsgId: clientMsgId,
        token: token,
        username: username,
        sentAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (links.length > _kMaxStored) links.removeRange(_kMaxStored, links.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSentLinksKey,
      jsonEncode(links.map((l) => l.toJson()).toList()),
    );
  }

  static Future<void> remove(String clientMsgId) async {
    final links = await load();
    links.removeWhere((l) => l.clientMsgId == clientMsgId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSentLinksKey,
      jsonEncode(links.map((l) => l.toJson()).toList()),
    );
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSentLinksKey);
    } catch (_) {}
  }
}
