/// Offline outbox: persisted FIFO queue of mutating ops with an idempotent
/// drain engine.
///
/// Every op carries a client-generated id where the server supports dedup
/// (sends via `client_msg_id`); other ops are naturally idempotent
/// (approve/discard/report/sensitivity converge on retry). Drain stops at
/// the first *network* error and resumes on the next connectivity event.
/// A send whose Turnstile token expired parks as `needsVerification` while
/// the rest of the queue keeps flowing.
///
/// Queue mutations are serialized and always re-read the persisted list
/// immediately before writing. A network call never holds a stale snapshot
/// across an await, so an operation enqueued (or a sign-out that clears the
/// queue) during a drain cannot be overwritten or resurrected.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import 'sent_links.dart';

const String _kOutboxKey = 'outbox_ops_v1';

enum OutboxKind { send, reply, approve, discard, report, sensitivity }

OutboxKind _kindFrom(String name) =>
    OutboxKind.values.firstWhere((k) => k.name == name, orElse: () => OutboxKind.send);

class OutboxOp {
  final String id;
  final OutboxKind kind;
  final Map<String, String> params;
  final int queuedAt;
  final int attempts;
  final bool needsVerification;
  final bool failed;
  final String? error;

  /// Set once the server has confirmed a send. If the app dies between that
  /// confirmation and removing the op, the next drain saves the link and
  /// removes the op without re-posting the message.
  final String? replyToken;

  const OutboxOp({
    required this.id,
    required this.kind,
    required this.params,
    required this.queuedAt,
    this.attempts = 0,
    this.needsVerification = false,
    this.failed = false,
    this.error,
    this.replyToken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'params': params,
        'queuedAt': queuedAt,
        'attempts': attempts,
        'needsVerification': needsVerification,
        'failed': failed,
        'error': error,
        'replyToken': replyToken,
      };

  factory OutboxOp.fromJson(Map<String, dynamic> json) => OutboxOp(
        id: json['id']?.toString() ?? '',
        kind: _kindFrom(json['kind']?.toString() ?? 'send'),
        params: ((json['params'] as Map?) ?? {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
        queuedAt: (json['queuedAt'] as num?)?.toInt() ?? 0,
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        needsVerification: json['needsVerification'] == true,
        failed: json['failed'] == true,
        error: json['error']?.toString(),
        replyToken: json['replyToken']?.toString(),
      );

  OutboxOp bumped({bool? needsVerification}) => OutboxOp(
        id: id,
        kind: kind,
        params: params,
        queuedAt: queuedAt,
        attempts: attempts + 1,
        needsVerification: needsVerification ?? this.needsVerification,
        failed: failed,
        error: error,
        replyToken: replyToken,
      );

  OutboxOp withFailure(String error) => OutboxOp(
        id: id,
        kind: kind,
        params: params,
        queuedAt: queuedAt,
        attempts: attempts + 1,
        needsVerification: needsVerification,
        failed: true,
        error: error,
        replyToken: replyToken,
      );

  OutboxOp withReplyToken(String token) => OutboxOp(
        id: id,
        kind: kind,
        params: params,
        queuedAt: queuedAt,
        attempts: attempts,
        needsVerification: needsVerification,
        failed: failed,
        error: error,
        replyToken: token,
      );
}

class OutboxStatus {
  final int pending;
  final OutboxOp? blocked;
  final OutboxOp? failed;
  final String? error;
  final bool draining;
  const OutboxStatus({
    required this.pending,
    required this.blocked,
    required this.draining,
    this.failed,
    this.error,
  });
}

String newClientMsgId() {
  final r = Random.secure();
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-';
  return List.generate(24, (_) => chars[r.nextInt(chars.length)]).join();
}

class Outbox {
  Outbox._();
  static final ValueNotifier<OutboxStatus> status =
      ValueNotifier(const OutboxStatus(pending: 0, blocked: null, draining: false));
  static bool _draining = false;

  /// Serializes every read-modify-write of the persisted queue. Network
  /// calls run outside this lock, so enqueue/clearAll never wait on a drain.
  static Future<void> _queueTail = Future<void>.value();

  static Future<T> _locked<T>(Future<T> Function() action) {
    final previous = _queueTail;
    final done = Completer<void>();
    _queueTail = done.future;
    return previous
        .then((_) => action())
        .whenComplete(() => done.complete());
  }

  static Future<List<OutboxOp>> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kOutboxKey);
      if (raw == null || raw.isEmpty) return [];
      return (jsonDecode(raw) as List)
          .whereType<Map<String, dynamic>>()
          .map(OutboxOp.fromJson)
          .where((o) => o.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _write(List<OutboxOp> ops) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kOutboxKey, jsonEncode(ops.map((o) => o.toJson()).toList()));
    } catch (_) {}
    _emit(ops, draining: _draining);
  }

  /// Applies [change] to the freshest persisted queue and writes the result.
  static Future<List<OutboxOp>> _mutate(
      List<OutboxOp> Function(List<OutboxOp> ops) change) {
    return _locked(() async {
      final ops = await _read();
      final next = change(ops);
      await _write(next);
      return next;
    });
  }

  static Future<void> _removeById(String id) =>
      _mutate((ops) => ops..removeWhere((o) => o.id == id));

  static Future<void> _replaceById(
    String id,
    OutboxOp Function(OutboxOp op) change,
  ) =>
      _mutate((ops) {
        final i = ops.indexWhere((o) => o.id == id);
        if (i >= 0) ops[i] = change(ops[i]);
        return ops;
      });

  static void _emit(List<OutboxOp> ops, {required bool draining}) {
    final blocked = ops.where((o) => o.needsVerification).firstOrNull;
    final failed = ops.where((o) => o.failed).firstOrNull;
    status.value = OutboxStatus(
      pending: ops.length,
      blocked: blocked,
      failed: failed,
      error: failed?.error,
      draining: draining,
    );
  }

  /// Current depth without triggering listeners (for badges).
  static Future<int> depth() async => (await _read()).length;

  static Future<void> refresh() async {
    final ops = await _read();
    _emit(ops, draining: _draining);
  }

  static Future<OutboxOp> enqueue(
    OutboxKind kind,
    Map<String, String> params, {
    bool autoDrain = true,
  }) async {
    // The API requires a fresh Turnstile token, which cannot be obtained
    // headlessly at drain time. Queuing a report would promise delivery and
    // then fail with 403 forever, so callers must submit it while online.
    if (kind == OutboxKind.report) {
      throw UnsupportedError(
          'Abuse reports need a connection and a fresh verification.');
    }
    final op = OutboxOp(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      kind: kind,
      params: Map.of(params),
      queuedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _mutate((ops) {
      ops.add(op);
      return ops;
    });
    if (autoDrain) unawaited(drain());
    return op;
  }

  static bool _isNetworkError(Object e) =>
      e is SocketException ||
      e is TimeoutException ||
      e is HttpException ||
      e is http.ClientException ||
      e is TlsException;

  static String _clientMsgId(OutboxOp op) =>
      (op.params['clientMsgId'] ?? '').trim();

  static Future<void> _saveSendLink(OutboxOp op) async {
    final token = (op.replyToken ?? '').trim();
    if (token.isEmpty) return;
    final id = _clientMsgId(op);
    await SentLinks.add(
      clientMsgId: id.isEmpty ? op.id : id,
      token: token,
      username: op.params['username'] ?? '',
    );
  }

  /// Drains the queue in order. Returns true when fully drained.
  /// [onChanged] fires when server state may have moved (caller refreshes).
  static Future<bool> drain({
    Future<void> Function()? onChanged,
    Future<String?> Function(OutboxOp op)? execute,
  }) async {
    if (_draining) return false;
    _draining = true;
    var changed = false;
    try {
      final snapshot = await _read();
      _emit(snapshot, draining: true);
      for (final op in snapshot) {
        if (op.needsVerification || op.failed) continue;

        // The server already accepted this send; keep the reply link instead
        // of posting it again.
        if (op.kind == OutboxKind.send &&
            (op.replyToken?.isNotEmpty ?? false)) {
          try {
            await _saveSendLink(op);
            await _removeById(op.id);
            changed = true;
          } catch (e) {
            await _replaceById(op.id,
                (cur) => cur.withFailure('Could not save your reply link. Tap Retry.'));
          }
          continue;
        }

        // A send recorded as delivered must never be posted a second time,
        // even if its queue entry outlived the first drain.
        if (op.kind == OutboxKind.send) {
          final id = _clientMsgId(op);
          if (id.isNotEmpty && await SentLinks.find(id) != null) {
            await _removeById(op.id);
            changed = true;
            continue;
          }
        }

        try {
          final replyToken = execute != null
              ? await execute(op)
              : await _execute(op);
          if (op.kind == OutboxKind.send &&
              replyToken != null &&
              replyToken.isNotEmpty) {
            await _replaceById(op.id, (cur) => cur.withReplyToken(replyToken));
            await SentLinks.add(
              clientMsgId: _clientMsgId(op).isEmpty ? op.id : _clientMsgId(op),
              token: replyToken,
              username: op.params['username'] ?? '',
            );
          }
          await _removeById(op.id);
          changed = true;
        } on ApiException catch (e) {
          if (op.kind == OutboxKind.send &&
              (e.statusCode == 403 || e.statusCode == 400)) {
            await _replaceById(
                op.id, (cur) => cur.bumped(needsVerification: true));
          } else {
            await _replaceById(op.id, (cur) => cur.withFailure(e.message));
          }
        } on UnauthorizedError {
          await _removeById(op.id);
        } catch (e) {
          if (_isNetworkError(e)) {
            await _replaceById(op.id, (cur) => cur.bumped());
            break;
          }
          await _replaceById(op.id,
              (cur) => cur.withFailure('Queued action failed unexpectedly.'));
        }
      }
      if (changed) {
        try {
          await onChanged?.call();
        } catch (_) {}
      }
      return (await _read()).isEmpty;
    } finally {
      _draining = false;
      await refresh();
    }
  }

  static Future<String?> _execute(OutboxOp op) async {
    final p = op.params;
    switch (op.kind) {
      case OutboxKind.send:
        final token = await ApiClient.sendAnonymousMessage(
          username: p['username'] ?? '',
          content: p['content'] ?? '',
          turnstileToken: p['turnstileToken'],
          allowClue: p['allowClue'] == '1',
          clientMsgId: p['clientMsgId'],
        );
        return token;
      case OutboxKind.reply:
        await ApiClient.replyMessage(p['messageId'] ?? '', p['reply'] ?? '');
        return null;
      case OutboxKind.approve:
        await ApiClient.approveMessage(p['messageId'] ?? '');
        return null;
      case OutboxKind.discard:
        await ApiClient.discardMessage(p['messageId'] ?? '');
        return null;
      case OutboxKind.report:
        throw ApiException(
          'Reports need a connection and a fresh verification. Open the message and report it again.',
          statusCode: 403,
          body: const {},
        );
      case OutboxKind.sensitivity:
        await ApiClient.setSensitivity(p['level'] ?? 'standard');
        return null;
    }
  }

  /// Runs [fn] immediately; on network failure, enqueues [kind]/[params]
  /// instead and returns false. Server rejections propagate to the caller.
  /// Returns true when the op completed online.
  static Future<bool> runOrEnqueue(
    OutboxKind kind,
    Map<String, String> params,
    Future<void> Function() fn,
  ) async {
    try {
      await fn();
      return true;
    } on ApiException {
      rethrow;
    } on UnauthorizedError {
      rethrow;
    } catch (e) {
      if (_isNetworkError(e)) {
        await enqueue(kind, params);
        return false;
      }
      rethrow;
    }
  }
  /// Drops the whole queue (logout: parked ops are authed as the previous
  /// owner and could never succeed — the drain drops them on 401 anyway).
  static Future<void> clearAll() {
    return _locked(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kOutboxKey);
        _emit([], draining: _draining);
      } catch (_) {
        final ops = await _read();
        _emit(ops, draining: _draining);
      }
    });
  }

  /// Removes a parked op (user chose the manual composer handoff instead).
  static Future<void> remove(String id) => _removeById(id);

  static Future<void> discard(String id) => remove(id);

  static Future<bool> retry(String id) async {
    final updated = await _locked<OutboxOp?>(() async {
      final ops = await _read();
      final i = ops.indexWhere((o) => o.id == id);
      if (i < 0) return null;
      final op = ops[i];
      ops[i] = OutboxOp(
        id: op.id,
        kind: op.kind,
        params: op.params,
        queuedAt: op.queuedAt,
        needsVerification: false,
        replyToken: op.replyToken,
      );
      await _write(ops);
      return ops[i];
    });
    if (updated == null) return false;
    return drain();
  }

  static Future<void> unpark(String id) async {
    await _locked(() async {
      final ops = await _read();
      final i = ops.indexWhere((o) => o.id == id);
      if (i < 0) return;
      final op = ops[i];
      ops[i] = OutboxOp(
        id: op.id,
        kind: op.kind,
        params: op.params,
        queuedAt: op.queuedAt,
        attempts: op.attempts,
        needsVerification: false,
        failed: op.failed,
        error: op.error,
        replyToken: op.replyToken,
      );
      await _write(ops);
    });
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
