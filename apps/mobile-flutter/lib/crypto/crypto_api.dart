// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// HTTP client for the crypto routes defined in
// secretmsg-private/api/src/crypto.ts. Kept inside lib/crypto/ so it can be
// adopted without editing the shared ApiClient while the routes are wired in.
//
// Wire format (v1):
//   POST /api/crypto/keys      { device_id, public_key }
//   GET  /api/crypto/pubkey/:u -> { e2e, keys: [{id, public_key}], filter }
//   POST /api/crypto/message/:u
//        { content, preview, filter_match, turnstileToken, allowClue,
//          deviceFp, client_msg_id }
//   POST /api/crypto/inbox/:id/reply { content }
//   POST /api/crypto/report    { messageId, reason, contentKey, turnstileToken }
//
// The key never appears in a query string or in any URL this client requests;
// only the claim-link fragment carries it (see claim_link.dart).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../api/api_client.dart';
import '../api/config.dart';
import '../api/session.dart';
import 'crypto_service.dart';
import 'message_crypto.dart';

class CryptoApi implements CryptoTransport {
  final String baseUrl;

  const CryptoApi({this.baseUrl = kApiBaseUrl});

  // ---- Device key registration ----

  @override
  Future<void> registerDeviceKey({
    required String deviceId,
    required String publicKeyB64,
  }) async {
    await _postJson('/api/crypto/keys', {
      'device_id': deviceId,
      'public_key': publicKeyB64,
    }, auth: true);
  }

  // ---- Recipient key + filter manifest ----

  @override
  Future<RecipientCrypto> fetchRecipientCrypto(String username) async {
    final data = await _getJson('/api/crypto/pubkey/${Uri.encodeComponent(username)}');
    final keys = <RecipientDeviceKey>[];
    final rawKeys = data['keys'];
    if (rawKeys is List) {
      for (final raw in rawKeys) {
        if (raw is! Map<String, dynamic>) continue;
        final id = raw['id']?.toString() ?? '';
        final pub = raw['public_key']?.toString() ?? '';
        if (id.isEmpty || pub.isEmpty) continue;
        try {
          keys.add(RecipientDeviceKey(
            kid: id,
            publicKey: _decode32(pub),
          ));
        } catch (_) {
          // A malformed key entry is skipped, never treated as valid. If all
          // entries are malformed the send falls back to the legacy lane.
        }
      }
    }
    final rawFilter = data['filter'];
    var mode = 'standard';
    var words = <String>[];
    if (rawFilter is Map<String, dynamic>) {
      final m = rawFilter['mode']?.toString();
      if (m == 'off' || m == 'standard' || m == 'strict') mode = m!;
      final w = rawFilter['words'];
      if (w is List) {
        words = w
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .take(50)
            .toList();
      }
    }
    final e2e = data['e2e'] == true && keys.isNotEmpty;
    return RecipientCrypto(
      e2e: e2e,
      keys: e2e ? keys : const [],
      filterMode: mode,
      hiddenWords: words,
    );
  }

  // ---- Encrypted send ----

  /// Sends an already-prepared encrypted body. [preparation] must have
  /// `e2e == true`; callers use [CryptoService.prepareSend] first.
  Future<String?> sendEncrypted({
    required SendPreparation preparation,
    String? turnstileToken,
    bool allowClue = false,
    String? clientMsgId,
  }) async {
    if (!preparation.e2e) {
      throw ArgumentError('sendEncrypted requires an e2e preparation');
    }
    final data = await _postJson(
      '/api/crypto/message/${Uri.encodeComponent(preparation.username)}',
      {
        'content': preparation.content,
        'preview': preparation.preview,
        'filter_match': preparation.filterMatched,
        'turnstileToken': turnstileToken,
        'allowClue': allowClue,
        'deviceFp': await Session.getDeviceFingerprint(),
        if (clientMsgId != null && clientMsgId.isNotEmpty)
          'client_msg_id': clientMsgId,
      },
    );
    return data['replyToken']?.toString();
  }

  // ---- Encrypted reply ----

  Future<void> sendEncryptedReply({
    required String messageId,
    required String envelope,
  }) async {
    await _postJson('/api/crypto/inbox/$messageId/reply', {
      'content': envelope,
    }, auth: true);
  }

  // ---- Opt-in report disclosure ----

  /// Sends a report. Pass the verified payload from
  /// [ReportDisclosure.build] to hand over the per-message key; pass null to
  /// file a metadata-only report.
  Future<void> report({
    required String messageId,
    required String reason,
    Map<String, dynamic>? disclosurePayload,
    String? turnstileToken,
  }) async {
    await _postJson('/api/crypto/report', {
      'messageId': messageId,
      'reason': reason,
      if (disclosurePayload != null)
        'contentKey': disclosurePayload['contentKey'],
      if (turnstileToken != null && turnstileToken.isNotEmpty)
        'turnstileToken': turnstileToken,
    }, auth: true);
  }

  // ---- plumbing (mirrors ApiClient's conventions without touching it) ----

  Future<Map<String, dynamic>> _getJson(String path) async {
    final headers = <String, String>{};
    final uri = Uri.parse('$baseUrl$path');
    final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
    return _decode(res);
  }

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await Session.getToken();
      if (token == null || token.isEmpty) throw UnauthorizedError();
      headers['Authorization'] = 'Bearer $token';
    }
    final uri = Uri.parse('$baseUrl$path');
    final res = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = <String, dynamic>{};
    }
    if (res.statusCode == 401) {
      throw UnauthorizedError(
        data['error']?.toString() ?? 'Session expired. Please log in again.',
      );
    }
    if (res.statusCode >= 400) {
      throw ApiException(
        data['error']?.toString() ?? 'Request failed (${res.statusCode})',
        statusCode: res.statusCode,
        body: data,
      );
    }
    return data;
  }

  static List<int> _decode32(String value) {
    final bytes = base64Url.decode(
      value.replaceAll('-', '+').replaceAll('_', '/') + ('=' * ((4 - value.length % 4) % 4)),
    );
    if (bytes.length != 32) {
      throw const FormatException('Key is not 32 bytes');
    }
    return bytes;
  }
}
