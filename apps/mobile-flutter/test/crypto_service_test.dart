// NOT CRYPTOGRAPHICALLY REVIEWED. The code under test implements an unaudited
// protocol; passing these tests does not make it secure.
//
// Tests for the orchestration layer: key lifecycle, send preparation,
// inbox decryption states (including honest key-loss), claim-key storage,
// and report disclosure. No device and no network: the transport and both
// secret stores are in-memory fakes.

import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/crypto/crypto_service.dart';
import 'package:secretmsg_mobile/crypto/device_key_store.dart';
import 'package:secretmsg_mobile/crypto/message_crypto.dart';
import 'package:secretmsg_mobile/crypto/reinstall_policy.dart';
import 'package:secretmsg_mobile/crypto/report_disclosure.dart';

class MemorySecretStore implements DeviceSecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class FakeTransport implements CryptoTransport {
  RecipientCrypto recipient = const RecipientCrypto(e2e: false);
  int registrations = 0;
  String? lastRegisteredPublicKey;

  @override
  Future<void> registerDeviceKey({
    required String deviceId,
    required String publicKeyB64,
  }) async {
    registrations += 1;
    lastRegisteredPublicKey = publicKeyB64;
  }

  @override
  Future<RecipientCrypto> fetchRecipientCrypto(String username) async => recipient;
}

void main() {
  late MemorySecretStore deviceStore;
  late MemorySecretStore claimStore;
  late FakeTransport transport;
  late CryptoService service;

  setUp(() {
    deviceStore = MemorySecretStore();
    claimStore = MemorySecretStore();
    transport = FakeTransport();
    service = CryptoService(
      keyStore: DeviceKeyStore(store: deviceStore),
      transport: transport,
      claimKeyStore: claimStore,
    );
  });

  group('device key lifecycle', () {
    test('creates, persists, and registers a key on first use', () async {
      final key = await service.ensureDeviceKey();
      expect(key.publicKeyBytes.length, 32);
      expect(key.privateKeyBytes.length, 32);
      expect(transport.registrations, 1);
      expect(transport.lastRegisteredPublicKey, key.publicKeyB64);

      final again = await service.ensureDeviceKey();
      expect(again.deviceId, key.deviceId);
      expect(again.publicKeyB64, key.publicKeyB64);
      expect(transport.registrations, 2);
    });

    test('load returns null after the key is cleared (reinstall)', () async {
      await service.ensureDeviceKey();
      await service.wipeKeys(const []);
      expect(await DeviceKeyStore(store: deviceStore).load(), isNull);
    });

    test('a half-present keypair is treated as absent, not repaired', () async {
      final store = DeviceKeyStore(store: deviceStore);
      await store.loadOrCreate();
      deviceStore.values.remove(kDevicePrivateKeyKey);
      expect(await store.load(), isNull);
      final fresh = await store.loadOrCreate();
      expect(deviceStore.values.containsKey(kDevicePrivateKeyKey), isTrue);
      expect(fresh.privateKeyBytes.length, 32);
    });
  });

  group('send preparation', () {
    test('legacy lane when the recipient has no key', () async {
      final prep = await service.prepareSend(
        username: 'nokeys',
        plaintext: 'plain old message',
      );
      expect(prep.e2e, isFalse);
      expect(prep.content, 'plain old message');
      expect(prep.preview, 'plain old message');
      expect(prep.contentKey, isNull);
      expect(prep.shouldReject, isFalse);
    });

    test('e2e lane wraps to the registered device key', () async {
      final recipientKey = await service.ensureDeviceKey();
      transport.recipient = RecipientCrypto(
        e2e: true,
        keys: [
          RecipientDeviceKey(
            kid: 'device-a',
            publicKey: recipientKey.publicKeyBytes,
          )
        ],
      );

      final prep = await service.prepareSend(
        username: 'haskeys',
        plaintext: 'a secret worth keeping',
      );
      expect(prep.e2e, isTrue);
      expect(prep.contentKey, isNotNull);
      expect(MessageCrypto.isEncrypted(prep.content), isTrue);
      expect(prep.preview, 'a secret worth keeping');
      expect(prep.content, isNot(contains('secret worth keeping')));

      // The same device can read what it prepared (sender is also the owner
      // in this test), proving the wrap is bound to the store key.
      final decrypted = await service.decryptStoredBody(prep.content);
      expect(decrypted.readability, HistoryReadability.readable);
      expect(decrypted.text, 'a secret worth keeping');
    });

    test('strict filter rejects before any key is spent', () async {
      final recipientKey = await service.ensureDeviceKey();
      transport.recipient = RecipientCrypto(
        e2e: true,
        keys: [
          RecipientDeviceKey(
              kid: 'device-a', publicKey: recipientKey.publicKeyBytes)
        ],
        filterMode: 'strict',
        hiddenWords: ['forbidden'],
      );
      final prep = await service.prepareSend(
        username: 'strict',
        plaintext: 'this is FORBIDDEN stuff',
      );
      expect(prep.shouldReject, isTrue);
      expect(prep.content, isEmpty);
      expect(prep.contentKey, isNull);
    });

    test('standard filter marks a match as quarantine-worthy', () async {
      final recipientKey = await service.ensureDeviceKey();
      transport.recipient = RecipientCrypto(
        e2e: true,
        keys: [
          RecipientDeviceKey(
              kid: 'device-a', publicKey: recipientKey.publicKeyBytes)
        ],
        filterMode: 'standard',
        hiddenWords: ['forbidden'],
      );
      final prep = await service.prepareSend(
        username: 'standard',
        plaintext: 'this is forbidden stuff',
      );
      expect(prep.shouldReject, isFalse);
      expect(prep.filterMatched, isTrue);
      expect(prep.e2e, isTrue);
    });
  });

  group('inbox decryption states', () {
    test('legacy plaintext is labelled, not hidden', () async {
      final result = await service.decryptStoredBody('a legacy message');
      expect(result.readability, HistoryReadability.legacyPlaintext);
      expect(result.text, 'a legacy message');
    });

    test('encrypted history after key loss is unreadable, not fake', () async {
      // Encrypt to one install's key...
      final prep = await _prepareEncryptedFor(service, transport);
      // ...then lose the key (reinstall).
      await service.wipeKeys(const []);
      final result = await service.decryptStoredBody(prep);
      expect(result.readability,
          HistoryReadability.unreadableAfterReinstallKeyLoss);
      expect(result.text, isNull);
    });

    test('tampered ciphertext is not rendered', () async {
      final recipientKey = await service.ensureDeviceKey();
      transport.recipient = RecipientCrypto(
        e2e: true,
        keys: [
          RecipientDeviceKey(
              kid: 'device-a', publicKey: recipientKey.publicKeyBytes)
        ],
      );
      final prep = await service.prepareSend(
          username: 'x', plaintext: 'tamper me');
      final tampered = '${prep.content.substring(0, prep.content.length - 4)}AAAA';
      final result = await service.decryptStoredBody(tampered);
      expect(result.readability,
          HistoryReadability.unreadableAfterReinstallKeyLoss);
      expect(result.text, isNull);
    });
  });

  group('claim links', () {
    test('stored content key rebuilds the link; unknown tokens do not', () async {
      final key = List<int>.generate(32, (i) => i);
      await service.rememberClaimKey('rep_1', key);
      final link = await service.claimLinkFor(
          baseUrl: 'https://secretmsg.net', replyToken: 'rep_1');
      expect(link, isNotNull);
      expect(link, contains('/reply/rep_1#k='));
      expect(
        await service.claimLinkFor(
            baseUrl: 'https://secretmsg.net', replyToken: 'rep_missing'),
        isNull,
      );
    });

    test('wipeKeys removes stored claim keys', () async {
      await service.rememberClaimKey('rep_1', List<int>.filled(32, 9));
      await service.wipeKeys(const ['rep_1']);
      expect(
        await service.claimLinkFor(
            baseUrl: 'https://secretmsg.net', replyToken: 'rep_1'),
        isNull,
      );
    });
  });

  group('report disclosure', () {
    test('builds a payload only when the key decrypts the envelope', () async {
      final key = await MessageCrypto.generateContentKey();
      final envelope = await MessageCrypto.encryptReply(
          plaintext: 'report me', contentKey: key);
      final result = await ReportDisclosure.build(
        messageId: 'msg_1234567890',
        reason: 'harassment',
        contentKey: key,
        bodyEnvelope: envelope,
      );
      expect(result.verified, isTrue);
      expect(result.payload!['messageId'], 'msg_1234567890');
      expect(result.payload!['contentKey'], isA<String>());
      expect(result.payload!.containsKey('turnstileToken'), isFalse);
    });

    test('refuses to disclose with the wrong key or a legacy body', () async {
      final key = await MessageCrypto.generateContentKey();
      final wrong = await MessageCrypto.generateContentKey();
      final envelope = await MessageCrypto.encryptReply(
          plaintext: 'report me', contentKey: key);
      final wrongKey = await ReportDisclosure.build(
        messageId: 'msg_1234567890',
        reason: 'harassment',
        contentKey: wrong,
        bodyEnvelope: envelope,
      );
      expect(wrongKey.verified, isFalse);
      expect(wrongKey.payload, isNull);

      final legacy = await ReportDisclosure.build(
        messageId: 'msg_1234567890',
        reason: 'harassment',
        contentKey: key,
        bodyEnvelope: 'plain old message',
      );
      expect(legacy.verified, isFalse);
    });
  });

  group('reinstall copy', () {
    test('states the loss and the absence of escrow without overclaiming',
        () {
      expect(ReinstallPolicy.keyEscrowEnabled, isFalse);
      expect(ReinstallPolicy.keyLossBody.toLowerCase(),
          contains('cannot be recovered'));
      expect(ReinstallPolicy.keyLossBody.toLowerCase(),
          contains('do not keep a copy'));
      expect(ReinstallPolicy.explainerBullets.join(' ').toLowerCase(),
          contains('no key escrow'));
      expect(
        ReinstallPolicy.explanation(
            HistoryReadability.unreadableAfterReinstallKeyLoss),
        contains('cannot be recovered'),
      );
      // The copy must not promise a recovery action that does not exist.
      expect(ReinstallPolicy.noRecoveryAction.toLowerCase(),
          contains('cannot restore'));
    });
  });
}

/// Encrypts a message to the service's own device key and returns the
/// envelope, reusing the production send preparation path.
Future<String> _prepareEncryptedFor(
  CryptoService service,
  FakeTransport transport,
) async {
  final key = await service.ensureDeviceKey();
  transport.recipient = RecipientCrypto(
    e2e: true,
    keys: [
      RecipientDeviceKey(kid: 'device-a', publicKey: key.publicKeyBytes)
    ],
  );
  final prep = await service.prepareSend(
      username: 'self', plaintext: 'history that will be lost');
  return prep.content;
}
