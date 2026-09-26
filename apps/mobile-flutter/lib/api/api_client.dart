import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
import 'local_data_wipe.dart';
import 'models.dart';
import 'session.dart';

class UnauthorizedError implements Exception {
  final String message;
  UnauthorizedError([this.message = 'Session expired. Please log in again.']);
  @override
  String toString() => message;
}

class ApiClient {
  static const _timeout = Duration(seconds: 30);

  static Future<Map<String, dynamic>> _getJson(String path,
      {bool auth = false, Duration? timeout}) async {
    final headers = <String, String>{};
    if (auth) {
      final token = await Session.getToken();
      if (token == null) throw UnauthorizedError();
      headers['Authorization'] = 'Bearer $token';
    }
    final uri = Uri.parse('$kApiBaseUrl$path');
    final res =
        await http.get(uri, headers: headers).timeout(timeout ?? _timeout);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await Session.getToken();
      if (token == null) throw UnauthorizedError();
      headers['Authorization'] = 'Bearer $token';
    }
    final uri = Uri.parse('$kApiBaseUrl$path');
    final res = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> _patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final token = await Session.getToken();
    if (token == null) throw UnauthorizedError();
    final uri = Uri.parse('$kApiBaseUrl$path');
    final res = await http
        .patch(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decode(res);
  }

  static Future<Map<String, dynamic>> _deleteJson(String path) async {
    final token = await Session.getToken();
    if (token == null) throw UnauthorizedError();
    final uri = Uri.parse('$kApiBaseUrl$path');
    final res = await http
        .delete(uri, headers: {'Authorization': 'Bearer $token'})
        .timeout(_timeout);
    return _decode(res);
  }

  static Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      data = <String, dynamic>{};
    }
    if (res.statusCode == 401) {
      // Dead session (expired, revoked, or account gone): drop it now so a
      // stale token can't loop the user back into authed screens.
      unawaited(Session.clear());
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

  // ---- Public profile lookup ----
  static Future<UserProfile> getRecipientProfile(String username) async {
    final data =
        await _getJson('/api/user/${Uri.encodeComponent(username)}');
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  // ---- Anonymous message send ----
  static Future<String?> sendAnonymousMessage({
    required String username,
    required String content,
    String? turnstileToken,
    bool allowClue = false,
    String? clientMsgId,
  }) async {
    final data = await _postJson(
      '/api/message/${Uri.encodeComponent(username)}',
      {
        'content': content,
        'turnstileToken': turnstileToken,
        'allowClue': allowClue,
        'deviceFp': await Session.getDeviceFingerprint(),
        if (clientMsgId != null && clientMsgId.isNotEmpty) 'client_msg_id': clientMsgId,
      },
    );
    return data['replyToken']?.toString();
  }

  // ---- Auth V2: Handle + PIN + Backup Codes ----
  static Future<({String handle, List<String> backupCodes, String token})> authSignup({
    String? handle,
    required String pin,
    String? turnstileToken,
  }) async {
    final data = await _postJson('/api/auth/signup', {
      if (handle != null && handle.isNotEmpty) 'handle': handle,
      'pin': pin,
      if (turnstileToken != null && turnstileToken.isNotEmpty) 'turnstileToken': turnstileToken,
    });
    final codes = (data['backupCodes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final token = data['token']?.toString() ?? '';
    // Persist immediately: without this the new account is signed out on the
    // next screen (account exists server-side, app holds nothing).
    await Session.setToken(token);
    try {
      await getMe();
    } catch (_) {
      // Profile fetch is best-effort; the token alone keeps the session.
    }
    return (
      handle: data['handle']?.toString() ?? '',
      backupCodes: codes,
      token: token,
    );
  }

  static Future<({UserProfile user, String token})> authLogin({
    required String handle,
    required String pin,
  }) async {
    final data = await _postJson('/api/auth/login', {
      'handle': handle,
      'pin': pin,
    });
    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token']?.toString() ?? '';
    await Session.setToken(token);
    await Session.saveUser(user);
    return (user: user, token: token);
  }

  static Future<({String handle, List<String> backupCodes, String token})> authRecover({
    required String handle,
    required String backupCode,
    required String newPin,
  }) async {
    final data = await _postJson('/api/auth/recover', {
      'handle': handle,
      'backup_code': backupCode,
      'new_pin': newPin,
    });
    final codes = (data['backupCodes'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final recoverToken = data['token']?.toString() ?? '';
    // Same session bug as signup once had: persist before navigating, or the
    // recovered account lands signed out on the next screen.
    await Session.setToken(recoverToken);
    try {
      await getMe();
    } catch (_) {}
    return (
      handle: data['user']?['username']?.toString() ?? handle,
      backupCodes: codes,
      token: recoverToken,
    );
  }

  static Future<void> authChangePin({required String currentPin, required String newPin}) async {
    // Rotation: the server bumps the session epoch, so it returns a fresh
    // token — save it or every later call 401s.
    final data = await _postJson('/api/auth/change-pin', {
      'current_pin': currentPin,
      'new_pin': newPin,
    }, auth: true);
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await Session.setToken(token);
    }
  }

  static Future<List<String>> authRefreshBackupCodes({required String currentPin}) async {
    final data = await _postJson('/api/auth/refresh-backup-codes', {
      'current_pin': currentPin,
    }, auth: true);
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await Session.setToken(token);
    }
    return (data['backupCodes'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  // ---- Google Play billing (POST /api/billing/google/verify) ----
  /// Hands the Play purchase token to the API, which verifies it with Google
  /// before unlocking anything. Throws if verification fails so the caller can
  /// leave the purchase pending and retry on the next launch.
  static Future<void> verifyGooglePurchase({
    required String purchaseToken,
    required String productId,
  }) async {
    await _postJson('/api/billing/google/verify', {
      'purchase_token': purchaseToken,
      'product_id': productId,
    }, auth: true);
  }

  // ---- Web pairing (POST /api/auth/pair/create) ----
  /// Requests a short-lived, single-use code the owner types into
  /// secretmsg.net to open a view-only session in a browser.
  static Future<({String code, int expiresIn})> createPairCode() async {
    final data = await _postJson('/api/auth/pair/create', const {}, auth: true);
    return (
      code: data['code']?.toString() ?? '',
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 300,
    );
  }

  // ---- Authenticated profile (GET /api/me) ----
  static Future<UserProfile> getMe() async {
    final data = await _getJson('/api/me', auth: true);
    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    await Session.saveUser(user);
    return user;
  }

  // ---- PATCH /api/me (pause + filtered words) ----
  static Future<void> updateMe({
    int? pausedUntil,
    bool clearPause = false,
    List<String>? hiddenWords,
  }) async {
    final body = <String, dynamic>{};
    if (hiddenWords != null) body['hidden_words'] = hiddenWords;
    if (pausedUntil != null) body['paused_until'] = pausedUntil;
    if (clearPause) body['paused_until'] = null;
    if (body.isEmpty) return;
    await _patchJson('/api/me', body);
  }

  // ---- Avatar seed (generative multiavatar, PATCH /api/me) ----
  static Future<void> updateAvatarSeed(String seed) async {
    await _patchJson('/api/me', {'avatar_seed': seed});
  }

  // ---- Display name (PATCH /api/me) ----
  static Future<void> updateDisplayName(String name) async {
    await _patchJson('/api/me', {'display_name': name});
  }

  // ---- Claim Custom Username (Supporter Perk, POST /api/me/username) ----
  static Future<void> setUsername(String username) async {
    await _postJson('/api/me/username', {'username': username}, auth: true);
  }

  // ---- Inbox ----
  static Future<List<AnonymousMessage>> getInbox() async {
    final page = await getInboxPage();
    return page.messages;
  }

  /// Keyset page: pass [cursor] from the previous page's `nextCursor`.
  /// Empty cursor starts at head. `nextCursor == null` means end.
  static Future<({List<AnonymousMessage> messages, String? nextCursor})> getInboxPage({String? cursor}) async {
    final uri = cursor == null || cursor.isEmpty
        ? '/api/inbox'
        : '/api/inbox?cursor=${Uri.encodeComponent(cursor)}';
    final data = await _getJson(uri, auth: true);
    final list = (data['messages'] as List?)
            ?.map((e) => AnonymousMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return (messages: list, nextCursor: data['next_cursor']?.toString());
  }

  // ---- Filtered tray (quarantined moderation holds) ----
  static Future<List<AnonymousMessage>> getFilteredTray() async {
    final page = await getFilteredTrayPage();
    return page.messages;
  }

  static Future<({List<AnonymousMessage> messages, String? nextCursor})> getFilteredTrayPage({String? cursor}) async {
    final uri = cursor == null || cursor.isEmpty
        ? '/api/inbox?filter=quarantined'
        : '/api/inbox?filter=quarantined&cursor=${Uri.encodeComponent(cursor)}';
    final data = await _getJson(uri, auth: true);
    final list = (data['messages'] as List?)
            ?.map((e) => AnonymousMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return (messages: list, nextCursor: data['next_cursor']?.toString());
  }

  static Future<void> approveMessage(String messageId) async {
    await _postJson('/api/inbox/$messageId/approve', const {}, auth: true);
  }

  static Future<void> discardMessage(String messageId) async {
    await _deleteJson('/api/inbox/$messageId');
  }

  static Future<void> setSensitivity(String level) async {
    await _patchJson('/api/me', {'mod_sensitivity': level});
  }

  // ---- My reports + outcomes ----
  static Future<List<FiledReport>> getMyReports() async {
    final data = await _getJson('/api/reports/mine', auth: true);
    final list = (data['reports'] as List?)
            ?.map((e) => FiledReport.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return list;
  }

  static Future<void> replyMessage(String messageId, String reply) async {
    await _postJson('/api/inbox/$messageId/reply', {'reply': reply}, auth: true);
  }

  // ---- Push registration (FCM token, best-effort) ----
  static Future<void> registerPushToken(String fcmToken) async {
    await _postJson('/api/push/register', {'fcm_token': fcmToken}, auth: true);
  }

  static Future<void> unregisterPushToken() async {
    await _postJson('/api/push/register', {'fcm_token': ''}, auth: true);
  }

  // ---- Account deletion ----
  static Future<void> deleteAccount() async {
    await _deleteJson('/api/account');
    await AccountDataWipe.wipeAllLocalAccountData();
  }

  // ---- Abuse report ----
  static Future<void> reportMessage(String messageId, String reason, {String? turnstileToken}) async {
    await _postJson('/api/report', {
      'messageId': messageId,
      'reason': reason,
      if (turnstileToken != null && turnstileToken.isNotEmpty) 'turnstileToken': turnstileToken,
    });
  }

  // ---- Blocked Senders (anonymous device fingerprints) ----
  static Future<List<BlockedSender>> getBlockedSenders() async {
    final data = await _getJson('/api/me/blocked', auth: true);
    final list = (data['blocked'] as List?)
            ?.map((e) => BlockedSender.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return list;
  }

  static Future<void> unblockSender(String fpHash) async {
    await _deleteJson('/api/me/blocked/${Uri.encodeComponent(fpHash)}');
  }

  static Future<void> blockSender(String messageId) async {
    await _postJson('/api/inbox/$messageId/block', const {}, auth: true);
  }

  // ---- Supporters ----
  static Future<SupportersData> getSupporters() async {
    final data = await _getJson('/api/supporters');
    return SupportersData.fromJson(data);
  }

  // ---- Remote ad kill-switch (GET /api/config/ads) ----
  static Future<bool?> getAdsEnabled() async {
    final data =
        await _getJson(kAdsFlagsPath, timeout: const Duration(seconds: 5));
    final raw = data['ads_enabled'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) return raw == 'true' || raw == '1';
    return null;
  }

}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic> body;

  ApiException(this.message, {required this.statusCode, required this.body});

  @override
  String toString() => message;
}