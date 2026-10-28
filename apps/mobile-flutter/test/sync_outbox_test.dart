import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/api/api_client.dart';
import 'package:secretmsg_mobile/sync/cache.dart';
import 'package:secretmsg_mobile/sync/outbox.dart';
import 'package:secretmsg_mobile/sync/sent_links.dart';

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
        OutboxKind.reply,
        {'messageId': 'm1', 'reply': 'bad'},
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

  group('drain failure semantics', () {
    test('retains a network-failed operation for retry', () async {
      final op = await Outbox.enqueue(
        OutboxKind.reply,
        {'messageId': 'm1', 'reply': 'hello'},
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async {
          throw const SocketException('offline');
        },
      );

      expect(drained, false);
      expect(await Outbox.depth(), 1);
      expect(Outbox.status.value.pending, 1);
      expect(Outbox.status.value.failed, isNull);
      expect(await Outbox.drain(execute: (_) async => null), true);
      expect(await Outbox.depth(), 0);
      expect(op.id, isNotEmpty);
    });

    test('parks a send rejected with a verification status', () async {
      final op = await Outbox.enqueue(
        OutboxKind.send,
        {'username': 'u1', 'content': 'hello'},
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async {
          throw ApiException('Verification required', statusCode: 403, body: const {});
        },
      );

      expect(drained, false);
      expect(await Outbox.depth(), 1);
      expect(Outbox.status.value.blocked?.id, op.id);
      expect(Outbox.status.value.failed, isNull);
    });

    test('removes an operation rejected as unauthorized', () async {
      final op = await Outbox.enqueue(
        OutboxKind.reply,
        {'messageId': 'm1', 'reply': 'hello'},
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async {
          throw UnauthorizedError('expired');
        },
      );

      expect(drained, true);
      expect(await Outbox.depth(), 0);
      expect(Outbox.status.value.failed, isNull);
      expect(op.id, isNotEmpty);
    });
  });

  test('round-trips every serialized operation state', () {
    const op = OutboxOp(
      id: 'serialized',
      kind: OutboxKind.send,
      params: {'username': 'u1', 'content': 'hello'},
      queuedAt: 42,
      attempts: 2,
      needsVerification: true,
      failed: true,
      error: 'needs attention',
      replyToken: 'rep_serialized',
    );

    expect(OutboxOp.fromJson(op.toJson()).toJson(), op.toJson());
  });

  test('drains enqueued operations in insertion order', () async {
    final labels = ['first', 'second', 'third'];
    for (final label in labels) {
      await Outbox.enqueue(
        OutboxKind.reply,
        {'label': label},
        autoDrain: false,
      );
    }

    final seen = <String>[];
    final drained = await Outbox.drain(
      execute: (op) async {
        seen.add(op.params['label']!);
        return null;
      },
    );

    expect(drained, true);
    expect(seen, labels);
  });

  test('refuses to queue an abuse report that cannot carry verification', () async {
    await expectLater(
      Outbox.enqueue(
        OutboxKind.report,
        {'messageId': 'm1', 'reason': 'bad'},
        autoDrain: false,
      ),
      throwsA(isA<UnsupportedError>()),
    );
    expect(await Outbox.depth(), 0);
  });

  group('drain concurrency', () {
    test('keeps an operation enqueued while a request is in flight', () async {
      await Outbox.enqueue(
        OutboxKind.reply,
        {'label': 'first'},
        autoDrain: false,
      );

      var enqueued = false;
      final drained = await Outbox.drain(
        execute: (op) async {
          if (!enqueued) {
            enqueued = true;
            // Exactly what runOrEnqueue does when a second action happens
            // while the previous request is still awaiting the network.
            await Outbox.enqueue(
              OutboxKind.reply,
              {'label': 'second'},
            );
          }
          return null;
        },
      );

      expect(enqueued, true);
      expect(drained, false, reason: 'the second op is still queued');
      expect(await Outbox.depth(), 1);
      expect(Outbox.status.value.pending, 1);

      final seen = <String>[];
      final second = await Outbox.drain(
        execute: (op) async {
          seen.add(op.params['label']!);
          return null;
        },
      );
      expect(second, true);
      expect(seen, ['second']);
      expect(await Outbox.depth(), 0);
    });

    test('clearAll during a drain is not undone by the stale snapshot', () async {
      await Outbox.enqueue(
        OutboxKind.reply,
        {'label': 'first'},
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async {
          await Outbox.clearAll();
          return null;
        },
      );

      expect(drained, true);
      expect(await Outbox.depth(), 0);
      expect(Outbox.status.value.pending, 0);
    });
  });

  group('reply links', () {
    test('persists the token returned by a queued send', () async {
      const clientMsgId = 'queued-send-01';
      await Outbox.enqueue(
        OutboxKind.send,
        {
          'username': 'u1',
          'content': 'hello',
          'clientMsgId': clientMsgId,
        },
        autoDrain: false,
      );

      final drained = await Outbox.drain(
        execute: (_) async => 'rep_queued_token',
      );

      expect(drained, true);
      expect(await Outbox.depth(), 0);
      final link = await SentLinks.find(clientMsgId);
      expect(link, isNotNull);
      expect(link!.token, 'rep_queued_token');
      expect(link.username, 'u1');
    });

    test('does not resend a send already recorded as delivered', () async {
      const clientMsgId = 'queued-send-02';
      await SentLinks.add(
        clientMsgId: clientMsgId,
        token: 'rep_already_there',
        username: 'u1',
      );
      await Outbox.enqueue(
        OutboxKind.send,
        {
          'username': 'u1',
          'content': 'hello',
          'clientMsgId': clientMsgId,
        },
        autoDrain: false,
      );

      var calls = 0;
      final drained = await Outbox.drain(
        execute: (_) async {
          calls++;
          return null;
        },
      );

      expect(drained, true);
      expect(calls, 0, reason: 'a delivered client_msg_id must never repost');
      expect(await Outbox.depth(), 0);
      expect((await SentLinks.find(clientMsgId))!.token, 'rep_already_there');
    });

    test('recovers a token written just before an interrupted drain', () async {
      const clientMsgId = 'queued-send-03';
      final op = await Outbox.enqueue(
        OutboxKind.send,
        {
          'username': 'u1',
          'content': 'hello',
          'clientMsgId': clientMsgId,
        },
        autoDrain: false,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'outbox_ops_v1',
        '[{"id":"${op.id}","kind":"send","params":'
        '{"username":"u1","content":"hello","clientMsgId":"$clientMsgId"},'
        '"queuedAt":${op.queuedAt},"replyToken":"rep_survived_restart"}]',
      );

      var calls = 0;
      final drained = await Outbox.drain(
        execute: (_) async {
          calls++;
          return null;
        },
      );

      expect(drained, true);
      expect(calls, 0, reason: 'the server already accepted this send');
      expect((await SentLinks.find(clientMsgId))!.token, 'rep_survived_restart');
      expect(await Outbox.depth(), 0);
    });
  });
}
