import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';
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

  static Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse('$kApiBaseUrl$path');
    final res = await http.get(uri).timeout(_timeout);
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
  }) async {
    final data = await _postJson(
      '/api/message/${Uri.encodeComponent(username)}',
      {
        'content': content,
        'turnstileToken': turnstileToken,
        'allowClue': allowClue,
      },
    );
    return data['replyToken']?.toString();
  }

  // ---- OTP auth ----
  static Future<void> requestOtp(String email) async {
    await _postJson('/api/auth/otp-request', {'email': email});
  }

  static Future<({UserProfile user, String token})> verifyOtp(
    String email,
    String otp, {
    String? username,
  }) async {
    final data = await _postJson('/api/auth/otp-verify', {
      'email': email,
      'otp': otp,
      'username': username,
    });
    final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    final token = data['token']?.toString() ?? '';
    await Session.setToken(token);
    await Session.saveUser(user);
    return (user: user, token: token);
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
    final data = await _getJson('/api/me');
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

  // ---- Inbox ----
  static Future<List<AnonymousMessage>> getInbox() async {
    final data = await _getJson('/api/inbox');
    final list = (data['messages'] as List?)
            ?.map((e) => AnonymousMessage.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return list;
  }

  static Future<void> replyMessage(String messageId, String reply) async {
    await _postJson('/api/inbox/$messageId/reply', {'reply': reply}, auth: true);
  }

  // ---- Blind reply check ----
  static Future<ReplyThread> checkReply(String token) async {
    final data = await _getJson('/api/reply/${Uri.encodeComponent(token)}');
    return ReplyThread.fromJson(data['thread'] as Map<String, dynamic>);
  }

  // ---- Account deletion ----
  static Future<void> deleteAccount() async {
    await _deleteJson('/api/account');
    await Session.clear();
  }

  // ---- Abuse report ----
  static Future<void> reportMessage(String messageId, String reason) async {
    await _postJson('/api/report', {'messageId': messageId, 'reason': reason});
  }

  // ---- Supporters ----
  static Future<SupportersData> getSupporters() async {
    try {
      final data = await _getJson('/api/supporters');
      return SupportersData.fromJson(data);
    } catch (_) {
      return _seedSupporters();
    }
  }

  static SupportersData _seedSupporters() {
    final now = DateTime.now();
    final seed = [
      Supporter(
        id: 'demo-1',
        alias: 'Anonymous Guardian',
        tier: 'Golden Guardian',
        note: 'Love the true zero-tracking privacy on SecretMsg. Keep it open!',
        createdAt: now.subtract(const Duration(hours: 4)).toIso8601String(),
      ),
      Supporter(
        id: 'demo-2',
        alias: 'Coffee Lover #42',
        tier: 'Coffee Backer',
        note: 'Super smooth UI. Coffee on me for server hosting.',
        createdAt: now.subtract(const Duration(hours: 26)).toIso8601String(),
      ),
      Supporter(
        id: 'demo-3',
        alias: 'Secret Admirer',
        tier: 'Silver Patron',
        note: 'Sent this to my crush and they replied! Thank you!',
        createdAt: now.subtract(const Duration(hours: 48)).toIso8601String(),
      ),
      Supporter(
        id: 'demo-4',
        alias: 'Anonymous Supporter',
        tier: 'Bronze Supporter',
        note: 'Supporting independent open-source web platforms.',
        createdAt: now.subtract(const Duration(hours: 72)).toIso8601String(),
      ),
    ];
    return SupportersData(
      supporters: seed,
      stats: const {
        'totalSupporters': 4,
        'monthlyServerGoalPercent': 100,
        'currentMonth': 'September 2026',
      },
    );
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