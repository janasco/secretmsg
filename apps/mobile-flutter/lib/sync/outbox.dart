/// Offline outbox: persisted FIFO queue of mutating ops with an idempotent
/// drain engine.
///
/// Every op carries a client-generated id where the server supports dedup
/// (sends via `client_msg_id`); other ops are naturally idempotent
/// (approve/discard/report/sensitivity converge on retry). Drain stops at
/// the first *network* error and resumes on the next connectivity event.
/// A send whose Turnstile token expired parks as `needsVerification` while
/// the rest of the queue keeps flowing.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

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

  const OutboxOp({
    required this.id,
    required this.kind,
    required this.params,
    required this.queuedAt,
    this.attempts = 0,
    this.needsVerification = false,
    this.failed = false,
    this.error,
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
    final op = OutboxOp(
      id: '${DateTime.now().microsecondsSinceEpoch}_${Random.secure().nextInt(1 << 32)}',
      kind: kind,
      params: Map.of(params),
      queuedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final ops = await _read();
    ops.add(op);
    await _write(ops);
    if (autoDrain) unawaited(drain());
    return op;
  }

  static bool _isNetworkError(Object e) =>
      e is SocketException ||
      e is TimeoutException ||
      e is HttpException ||
      e is http.ClientException ||
      e is TlsException;

  /// Drains the queue in order. Returns true when fully drained.
  /// [onChanged] fires when server state may have moved (caller refreshes).
  static Future<bool> drain({
    Future<void> Function()? onChanged,
    Future<void> Function(OutboxOp op)? execute,
  }) async {
    if (_draining) return false;
    _draining = true;
    var changed = false;
    try {
      var ops = await _read();
      _emit(ops, draining: true);
      var i = 0;
      while (i < ops.length) {
        final op = ops[i];
        if (op.needsVerification || op.failed) {
          i++;
          continue;
        }
        try {
          await (execute?.call(op) ?? _execute(op));
          ops.removeAt(i);
          changed = true;
          await _write(ops);
        } on ApiException catch (e) {
          if (op.kind == OutboxKind.send &&
              (e.statusCode == 403 || e.statusCode == 400)) {
            ops[i] = op.bumped(needsVerification: true);
            await _write(ops);
            i++;
            continue;
          }
          ops[i] = op.withFailure(e.message);
          await _write(ops);
          i++;
        } on UnauthorizedError {
          ops.removeAt(i);
          await _write(ops);
        } catch (e) {
          if (_isNetworkError(e)) {
            ops[i] = op.bumped();
            await _write(ops);
            break;
          }
          ops[i] = op.withFailure('Queued action failed unexpectedly.');
          await _write(ops);
          i++;
        }
      }
      if (changed) {
        try {
          await onChanged?.call();
        } catch (_) {}
      }
      return ops.isEmpty;
    } finally {
      _draining = false;
      await refresh();
    }
  }

  static Future<void> _execute(OutboxOp op) {
    final p = op.params;
    switch (op.kind) {
      case OutboxKind.send:
        return ApiClient.sendAnonymousMessage(
          username: p['username'] ?? '',
          content: p['content'] ?? '',
          turnstileToken: p['turnstileToken'],
          allowClue: p['allowClue'] == '1',
          clientMsgId: p['clientMsgId'],
        ).then((_) {});
      case OutboxKind.reply:
        return ApiClient.replyMessage(p['messageId'] ?? '', p['reply'] ?? '');
      case OutboxKind.approve:
        return ApiClient.approveMessage(p['messageId'] ?? '');
      case OutboxKind.discard:
        return ApiClient.discardMessage(p['messageId'] ?? '');
      case OutboxKind.report:
        return ApiClient.reportMessage(p['messageId'] ?? '', p['reason'] ?? '');
      case OutboxKind.sensitivity:
        return ApiClient.setSensitivity(p['level'] ?? 'standard');
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
  static Future<void> clearAll() async {
    await _write([]);
  }

  /// Removes a parked op (user chose the manual composer handoff instead).
  static Future<void> remove(String id) async {
    final ops = await _read();
    ops.removeWhere((o) => o.id == id);
    await _write(ops);
  }

  static Future<void> discard(String id) => remove(id);

  static Future<bool> retry(String id) async {
    final ops = await _read();
    final i = ops.indexWhere((o) => o.id == id);
    if (i < 0) return false;
    final op = ops[i];
    ops[i] = OutboxOp(
      id: op.id,
      kind: op.kind,
      params: op.params,
      queuedAt: op.queuedAt,
      needsVerification: false,
    );
    await _write(ops);
    return drain();
  }

  static Future<void> unpark(String id) async {
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
    );
    await _write(ops);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
