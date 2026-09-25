import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/api/api_client.dart';
import 'package:secretmsg_mobile/sync/cache.dart';
import 'package:secretmsg_mobile/sync/outbox.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Outbox.clearAll();
  });

  group('newClientMsgId', () {
    test('matches the server shape and is unique', () {
      final a = newClientMsgId();
      final b = newClientMsgId();
      expect(a.length, 24);
      expect(RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(a), true);
      expect(a == b, false);
    });
  });

  group('OutboxOp', () {
    test('JSON round-trips', () {
      const op = OutboxOp(
        id: 'x1',
        kind: OutboxKind.reply,
        params: {'messageId': 'm1', 'reply': 'hi'},
        queuedAt: 123,
      );
      final back = OutboxOp.fromJson(op.toJson());
      expect(back.id, 'x1');
      expect(back.kind, OutboxKind.reply);
      expect(back.params['reply'], 'hi');
      expect(back.attempts, 0);
      expect(back.needsVerification, false);
      expect(back.failed, false);
      expect(back.error, isNull);
    });

    test('bumped increments attempts and can flag', () {
      const op = OutboxOp(
        id: 'x1',
        kind: OutboxKind.send,
        params: {'a': 'b'},
        queuedAt: 1,
      );
      final bumped = op.bumped(needsVerification: true);
      expect(bumped.attempts, 1);
      expect(bumped.needsVerification, true);
      expect(bumped.params['a'], 'b');
    });

    test('unknown kinds fall back to send', () {
      final op = OutboxOp.fromJson({
        'id': 'x',
        'kind': 'teleport',
        'params': <String, String>{},
        'queuedAt': 0,
      });
      expect(op.kind, OutboxKind.send);
    });
  });

  group('failed operations', () {
    test('preserves server rejection and surfaces its safe message', () async {
      final op = await Outbox.enqueue(
        OutboxKind.report,
        {'messageId': 'm1', 'reason': 'bad'},
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async {
          throw ApiException(
            'That report reason is not allowed.',
            statusCode: 400,
            body: const {},
          );
        },
      );

      expect(drained, false);
      expect(await Outbox.depth(), 1);
      expect(Outbox.status.value.failed?.id, op.id);
      expect(Outbox.status.value.error, 'That report reason is not allowed.');

      await Outbox.discard(op.id);
      expect(await Outbox.depth(), 0);
    });

    test('preserves unknown failure without exposing exception text', () async {
      final op = await Outbox.enqueue(
        OutboxKind.reply,
        {'messageId': 'm1', 'reply': 'hello'},
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async {
          throw StateError('sensitive internal detail');
        },
      );

      expect(drained, false);
      expect(await Outbox.depth(), 1);
      expect(Outbox.status.value.failed?.id, op.id);
      expect(Outbox.status.value.error, 'Queued action failed unexpectedly.');

      await Outbox.discard(op.id);
      expect(await Outbox.depth(), 0);
    });
  });

  group('stalenessLabel', () {
    test('tiers minutes, hours, days', () {
      final now = DateTime(2026, 9, 17, 12, 0);
      expect(InboxCache.stalenessLabel(now, now), 'just now');
      expect(
          InboxCache.stalenessLabel(
              now.subtract(const Duration(minutes: 5)), now),
          '5m ago');
      expect(
          InboxCache.stalenessLabel(
              now.subtract(const Duration(hours: 3)), now),
          '3h ago');
      expect(
          InboxCache.stalenessLabel(
              now.subtract(const Duration(days: 2)), now),
          '2d ago');
    });
  });
}
