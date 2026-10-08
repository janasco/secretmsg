import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/config.dart';
import '../../api/session.dart';

/// Errors returned by /api/social/*. The message is the server's plain-language
/// copy and is safe to show to the user.
class SocialApiException implements Exception {
  final String message;
  final int statusCode;

  const SocialApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Fixed six-emoji inventory. Mirrors GET /api/social/emoji and the web
/// client; one reaction per person per message, and no downvote glyph exists
/// anywhere in the product.
class ReactionEmoji {
  final String id;
  final String glyph;
  final String label;

  const ReactionEmoji(this.id, this.glyph, this.label);
}

const List<ReactionEmoji> kReactionEmoji = <ReactionEmoji>[
  ReactionEmoji('heart', '\u2764\uFE0F', 'React with heart'),
  ReactionEmoji('laugh', '\u{1F602}', 'React with laugh'),
  ReactionEmoji('wow', '\u{1F62E}', 'React with wow'),
  ReactionEmoji('sad', '\u{1F622}', 'React with sad'),
  ReactionEmoji('clap', '\u{1F44F}', 'React with clap'),
  ReactionEmoji('fire', '\u{1F525}', 'React with fire'),
];

/// Interim seals.
///
/// The 1.8 design seals reactions, feed posts, and member-box messages under
/// thread key material so the server stores ciphertext it cannot read. The
/// end-to-end envelope is being built in a separate change; until it lands,
/// these helpers produce base64 JSON with the same outer shape. The server
/// treats every payload as opaque either way, so replacing these two
/// functions with the real envelope does not change any API call here.
String sealReactionPayload(String emojiId) {
  return base64Encode(utf8.encode(jsonEncode(<String, dynamic>{'v': 1, 'e': emojiId})));
}

String? openReactionPayload(String payload) {
  final Map<String, dynamic>? raw = openInterimEnvelope(payload);
  if (raw == null || raw['e'] is! String) return null;
  final String id = raw['e'] as String;
  for (final ReactionEmoji emoji in kReactionEmoji) {
    if (emoji.id == id) return id;
  }
  return null;
}

String sealInterimEnvelope(Map<String, dynamic> body) {
  return base64Encode(utf8.encode(jsonEncode(<String, dynamic>{'v': 1, ...body})));
}

Map<String, dynamic>? openInterimEnvelope(String sealed) {
  try {
    final Object? decoded = jsonDecode(utf8.decode(base64Decode(sealed)));
    if (decoded is Map<String, dynamic> && decoded['v'] == 1) return decoded;
  } catch (_) {
    // Unknown or corrupted payload: render a neutral placeholder, never raw text.
  }
  return null;
}

/// Thin client for the social routes. Uses the same session token and base URL
/// as [ApiClient] without touching that shared file.
class SocialApi {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> _call(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (auth) {
      final String? token = await Session.getToken();
      if (token == null || token.isEmpty) {
        throw const SocialApiException('Session expired. Please log in again.', 401);
      }
      headers['Authorization'] = 'Bearer $token';
    }
    final Uri uri = Uri.parse('$kApiBaseUrl$path');
    final String? encoded = body == null ? null : jsonEncode(body);
    http.Response res;
    if (method == 'GET') {
      res = await http.get(uri, headers: headers).timeout(_timeout);
    } else if (method == 'PUT') {
      res = await http.put(uri, headers: headers, body: encoded).timeout(_timeout);
    } else if (method == 'DELETE') {
      res = await http.delete(uri, headers: headers, body: encoded).timeout(_timeout);
    } else {
      res = await http.post(uri, headers: headers, body: encoded).timeout(_timeout);
    }
    Map<String, dynamic> data = <String, dynamic>{};
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = <String, dynamic>{};
    }
    if (res.statusCode >= 400) {
      throw SocialApiException(
        data['error']?.toString() ?? 'Request failed (${res.statusCode})',
        res.statusCode,
      );
    }
    return data;
  }

  // ---- Handles & box theming ------------------------------------------------

  static Future<Map<String, dynamic>> resolveHandle(String handle) {
    return _call('GET', '/api/social/handle/${Uri.encodeComponent(handle)}/resolve');
  }

  static Future<Map<String, dynamic>> claimHandle(String handle) {
    return _call('POST', '/api/social/handle/claim',
        body: <String, dynamic>{'handle': handle}, auth: true);
  }

  static Future<Map<String, dynamic>> getMyHandles() {
    return _call('GET', '/api/social/handle/mine', auth: true);
  }

  static Future<Map<String, dynamic>> getBoxTheme(String handle) {
    return _call('GET', '/api/social/box/${Uri.encodeComponent(handle)}/theme');
  }

  static Future<Map<String, dynamic>> getMyBoxTheme() {
    return _call('GET', '/api/social/box/theme', auth: true);
  }

  static Future<Map<String, dynamic>> saveBoxTheme(Map<String, dynamic> theme) {
    return _call('PUT', '/api/social/box/theme', body: theme, auth: true);
  }

  // ---- Reactions -------------------------------------------------------------

  static Future<Map<String, dynamic>> getMessageReactions(String messageId) {
    return _call('GET', '/api/social/message/${Uri.encodeComponent(messageId)}/reactions',
        auth: true);
  }

  static Future<Map<String, dynamic>> putMessageReaction(String messageId, String? payload) {
    return _call(
      'PUT',
      '/api/social/message/${Uri.encodeComponent(messageId)}/reaction',
      body: payload == null
          ? <String, dynamic>{'remove': true}
          : <String, dynamic>{'payload': payload},
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> putPostReaction(
      String groupId, String postId, String? payload) {
    return _call(
      'PUT',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/posts/${Uri.encodeComponent(postId)}/reaction',
      body: payload == null
          ? <String, dynamic>{'remove': true}
          : <String, dynamic>{'payload': payload},
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> getPostReactions(String groupId, String postId) {
    return _call(
      'GET',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/posts/${Uri.encodeComponent(postId)}/reactions',
      auth: true,
    );
  }

  // ---- Verified senders -------------------------------------------------------

  static Future<Map<String, dynamic>> verifiedMe() {
    return _call('GET', '/api/social/verified/me', auth: true);
  }

  static Future<Map<String, dynamic>> consentVerified({int version = 1}) {
    return _call('POST', '/api/social/verified/consent',
        body: <String, dynamic>{'consent': true, 'version': version}, auth: true);
  }

  static Future<Map<String, dynamic>> startVerification(String claimType) {
    return _call('POST', '/api/social/verified/$claimType/start', auth: true);
  }

  static Future<Map<String, dynamic>> getAttestation(String messageId) {
    return _call('GET', '/api/social/verified/attestation/${Uri.encodeComponent(messageId)}',
        auth: true);
  }

  static Future<Map<String, dynamic>> getVerifiedPublicKey() {
    return _call('GET', '/api/social/verified/public-key');
  }

  // ---- Groups -----------------------------------------------------------------

  static Future<Map<String, dynamic>> listGroups() {
    return _call('GET', '/api/social/groups', auth: true);
  }

  static Future<Map<String, dynamic>> lookupGroup(String slug) {
    return _call('GET', '/api/social/groups/lookup/${Uri.encodeComponent(slug)}');
  }

  static Future<Map<String, dynamic>> createGroup({
    required String slug,
    required String name,
    required String rules,
  }) {
    return _call('POST', '/api/social/groups', body: <String, dynamic>{
      'slug': slug,
      'name': name,
      'rules': rules,
    }, auth: true);
  }

  static Future<Map<String, dynamic>> joinGroup(String groupId, String code) {
    return _call('POST', '/api/social/groups/${Uri.encodeComponent(groupId)}/join',
        body: <String, dynamic>{'code': code}, auth: true);
  }

  static Future<Map<String, dynamic>> getGroup(String groupId) {
    return _call('GET', '/api/social/groups/${Uri.encodeComponent(groupId)}', auth: true);
  }

  static Future<Map<String, dynamic>> updateGroupSettings(
      String groupId, Map<String, dynamic> settings) {
    return _call('PUT', '/api/social/groups/${Uri.encodeComponent(groupId)}/settings',
        body: settings, auth: true);
  }

  static Future<Map<String, dynamic>> updateMemberSettings(
      String groupId, Map<String, dynamic> settings) {
    return _call('PUT', '/api/social/groups/${Uri.encodeComponent(groupId)}/me',
        body: settings, auth: true);
  }

  static Future<Map<String, dynamic>> getRoster(String groupId) {
    return _call('GET', '/api/social/groups/${Uri.encodeComponent(groupId)}/roster',
        auth: true);
  }

  static Future<Map<String, dynamic>> rotateInvite(String groupId) {
    return _call('POST', '/api/social/groups/${Uri.encodeComponent(groupId)}/invites',
        auth: true);
  }

  static Future<Map<String, dynamic>> decideJoinRequest(
      String groupId, String memberId, String action) {
    return _call(
      'POST',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/requests/${Uri.encodeComponent(memberId)}',
      body: <String, dynamic>{'action': action},
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> leaveGroup(String groupId) {
    return _call('POST', '/api/social/groups/${Uri.encodeComponent(groupId)}/leave',
        auth: true);
  }

  static Future<Map<String, dynamic>> freezeGroup(String groupId, bool frozen) {
    return _call('POST', '/api/social/groups/${Uri.encodeComponent(groupId)}/freeze',
        body: <String, dynamic>{'frozen': frozen}, auth: true);
  }

  static Future<Map<String, dynamic>> rotateGroupKey(String groupId) {
    return _call('POST', '/api/social/groups/${Uri.encodeComponent(groupId)}/rotate',
        auth: true);
  }

  static Future<Map<String, dynamic>> listPosts(String groupId, {String? cursor}) {
    final String query = cursor == null ? '' : '?cursor=${Uri.encodeQueryComponent(cursor)}';
    return _call('GET', '/api/social/groups/${Uri.encodeComponent(groupId)}/posts$query',
        auth: true);
  }

  static Future<Map<String, dynamic>> createPost(String groupId, String payload) {
    return _call('POST', '/api/social/groups/${Uri.encodeComponent(groupId)}/posts',
        body: <String, dynamic>{'payload': payload}, auth: true);
  }

  static Future<Map<String, dynamic>> deletePost(String groupId, String postId) {
    return _call(
        'DELETE',
        '/api/social/groups/${Uri.encodeComponent(groupId)}/posts/${Uri.encodeComponent(postId)}',
        auth: true);
  }

  static Future<Map<String, dynamic>> muteMember(
      String groupId, String memberId, bool muted) {
    return _call(
      'POST',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/members/${Uri.encodeComponent(memberId)}/mute',
      body: <String, dynamic>{'muted': muted},
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> removeMember(String groupId, String memberId) {
    return _call(
      'POST',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/members/${Uri.encodeComponent(memberId)}/remove',
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> listMemberBox(String groupId, String memberId) {
    return _call(
      'GET',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/boxes/${Uri.encodeComponent(memberId)}',
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> sendMemberBox(
      String groupId, String memberId, String payload) {
    return _call(
      'POST',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/boxes/${Uri.encodeComponent(memberId)}',
      body: <String, dynamic>{'payload': payload},
      auth: true,
    );
  }

  static Future<Map<String, dynamic>> sendMemberBoxToPostAuthor(
      String groupId, String postId, String payload) {
    return _call(
      'POST',
      '/api/social/groups/${Uri.encodeComponent(groupId)}/boxes/by-post/${Uri.encodeComponent(postId)}',
      body: <String, dynamic>{'payload': payload},
      auth: true,
    );
  }

  // ---- Reports ----------------------------------------------------------------

  static Future<Map<String, dynamic>> report({
    required String targetKind,
    required String targetId,
    required String reason,
    String audience = 'platform',
    bool consent = false,
    String? disclosedPayload,
  }) {
    final Map<String, dynamic> body = <String, dynamic>{
      'target_kind': targetKind,
      'target_id': targetId,
      'reason': reason,
      'audience': audience,
    };
    if (consent && disclosedPayload != null && disclosedPayload.isNotEmpty) {
      body['consent'] = true;
      body['disclosed_payload'] = disclosedPayload;
    }
    return _call('POST', '/api/social/report', body: body, auth: true);
  }
}

/// Viewer-local upvotes. Never sent to the server in any form; stored in
/// shared_preferences and cleared with the app's data. Android auto-backup must
/// exclude this store so a copied device does not reveal rankings — that
/// manifest rule lives outside this feature's files and is noted in the
/// hand-off.
class LocalUpvotes {
  static const String _key = 'secretmsg_upvotes_v1';

  static Future<Set<String>> load() async {
    // Injected lazily so the screens stay testable and the import stays local.
    return _LocalUpvoteStore.load(_key);
  }

  static Future<Set<String>> toggle(String messageId) async {
    final Set<String> current = await load();
    if (!current.remove(messageId)) current.add(messageId);
    await _LocalUpvoteStore.save(_key, current);
    return current;
  }

  static Future<void> clear() async {
    await _LocalUpvoteStore.save(_key, <String>{});
  }

  static List<T> upvotedFirst<T>(
    List<T> items,
    String Function(T item) keyOf,
    Set<String> upvoted,
  ) {
    final List<T> copy = List<T>.of(items);
    copy.sort((T a, T b) {
      final int aRank = upvoted.contains(keyOf(a)) ? 1 : 0;
      final int bRank = upvoted.contains(keyOf(b)) ? 1 : 0;
      return bRank - aRank;
    });
    return copy;
  }
}

class _LocalUpvoteStore {
  static Future<Set<String>> load(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? stored = prefs.getStringList(key);
      return stored == null ? <String>{} : stored.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> save(String key, Set<String> values) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, values.toList());
    } catch (_) {
      // Storage failure only loses this session's ranking; never crash a screen.
    }
  }
}
