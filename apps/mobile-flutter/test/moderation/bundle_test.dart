import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:secretmsg_mobile/moderation/crypto/p256_ecdsa.dart';
import 'package:secretmsg_mobile/moderation/delivery/bundle_source.dart';
import 'package:secretmsg_mobile/moderation/delivery/bundle_store.dart';
import 'package:secretmsg_mobile/moderation/delivery/bundle_verifier.dart';
import 'package:secretmsg_mobile/moderation/delivery/rollout_policy.dart';

import 'fixtures.dart';

BundleVerifier buildVerifier({
  String appVersion = '1.8.0',
  int maxPayloadBytes = 35 * 1024 * 1024,
}) =>
    BundleVerifier(
      trustedSigningKeys: <String, P256PublicKey>{
        kFixtureKeyId: fixtureKey(),
      },
      appVersion: appVersion,
      maxPayloadBytes: maxPayloadBytes,
    );

void main() {
  group('BundleVerifier', () {
    test('accepts a correctly signed manifest and payload', () {
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV120),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.ok, isTrue);
      expect(result.manifest?.modelId, 'toxicity-multilingual-tiny');
      expect(result.manifest?.version, '1.2.0');
      expect(result.manifest?.kind, 'toxicity_classifier');
      expect(result.manifest?.payloadSize, 5);
    });

    test('rejects a tampered payload (digest mismatch)', () {
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV120),
        signature: kFixtureSigV120,
        payload: utf8.encode('hellp'),
      );
      expect(result.ok, isFalse);
      expect(result.failure, BundleFailureReason.payloadDigestMismatch);
    });

    test('rejects a payload whose size differs before hashing', () {
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV120),
        signature: kFixtureSigV120,
        payload: utf8.encode('hello!'),
      );
      expect(result.failure, BundleFailureReason.payloadSizeMismatch);
    });

    test('rejects a tampered manifest (signature mismatch)', () {
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode('$kFixtureManifestV120 '),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.failure, BundleFailureReason.invalidSignature);
    });

    test('rejects an unknown signing key', () {
      final manifest =
          kFixtureManifestV120.replaceAll(kFixtureKeyId, 'key-not-pinned');
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(manifest),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.failure, BundleFailureReason.unknownSigningKey);
    });

    test('rejects an unsupported schema or kind before signature', () {
      final schema = buildVerifier().verifyBytes(
        manifestBytes:
            utf8.encode(kFixtureManifestV120.replaceAll('"schema":1', '"schema":2')),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(schema.failure, BundleFailureReason.unsupportedSchema);

      final kind = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV120
            .replaceAll('toxicity_classifier', 'something_else')),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(kind.failure, BundleFailureReason.unsupportedKind);
    });

    test('rejects an unsafe payload file name before signature', () {
      final manifest = kFixtureManifestV120.replaceAll(
        '"payload_file":"payload.bin"',
        '"payload_file":"../evil.bin"',
      );
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(manifest),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.failure, BundleFailureReason.unsafePayloadFileName);
    });

    test('rejects malformed manifests', () {
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode('not json'),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.failure, BundleFailureReason.manifestMalformed);
    });

    test('rejects a missing or malformed signature', () {
      final result = buildVerifier().verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV120),
        signature: 'AAAA',
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.failure, BundleFailureReason.malformedSignature);
    });

    test('honours min_app_version', () {
      final tooOld = buildVerifier(appVersion: '1.8.0').verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV300MinApp),
        signature: kFixtureSigV300MinApp,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(tooOld.failure, BundleFailureReason.appVersionTooOld);

      final newEnough = buildVerifier(appVersion: '99.1.0').verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV300MinApp),
        signature: kFixtureSigV300MinApp,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(newEnough.ok, isTrue);
    });

    test('enforces the payload size cap', () {
      final result = buildVerifier(maxPayloadBytes: 4).verifyBytes(
        manifestBytes: utf8.encode(kFixtureManifestV120),
        signature: kFixtureSigV120,
        payload: utf8.encode(kFixturePayloadHello),
      );
      expect(result.failure, BundleFailureReason.payloadTooLarge);
    });

    test('verifyFiles streams the payload digest', () async {
      final dir = Directory.systemTemp.createTempSync('bundle_verify_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      final manifestFile = File('${dir.path}/manifest.json')
        ..writeAsBytesSync(utf8.encode(kFixtureManifestV120));
      final signatureFile = File('${dir.path}/manifest.sig')
        ..writeAsStringSync(kFixtureSigV120);
      final payloadFile = File('${dir.path}/payload.bin')
        ..writeAsBytesSync(utf8.encode(kFixturePayloadHello));

      final ok = await buildVerifier().verifyFiles(
        manifestFile: manifestFile,
        signatureFile: signatureFile,
        payloadFile: payloadFile,
      );
      expect(ok.ok, isTrue);

      payloadFile.writeAsStringSync('hellp');
      final bad = await buildVerifier().verifyFiles(
        manifestFile: manifestFile,
        signatureFile: signatureFile,
        payloadFile: payloadFile,
      );
      expect(bad.failure, BundleFailureReason.payloadDigestMismatch);
    });
  });

  group('rollout policy', () {
    const policy = ModelRolloutPolicy(
      kind: 'toxicity_classifier',
      preferredVersion: '1.2.0',
      minimumSupportedVersion: '1.0.0',
    );

    test('no installed model installs the preferred version', () {
      final decision = decideModelRollout(policy: policy, installedVersion: null);
      expect(decision.action, RolloutAction.install);
      expect(decision.targetVersion, '1.2.0');
    });

    test('older installed model upgrades to preferred', () {
      final decision =
          decideModelRollout(policy: policy, installedVersion: '1.0.0');
      expect(decision.action, RolloutAction.install);
      expect(decision.targetVersion, '1.2.0');
    });

    test('equal version is up to date', () {
      final decision =
          decideModelRollout(policy: policy, installedVersion: '1.2.0');
      expect(decision.action, RolloutAction.upToDate);
    });

    test('rolling preferred backward does not downgrade a newer install', () {
      final decision =
          decideModelRollout(policy: policy, installedVersion: '2.0.0');
      expect(decision.action, RolloutAction.keepNewerInstalled);
      expect(decision.targetVersion, '2.0.0');
    });

    test('below minimum requires a client update', () {
      const strict = ModelRolloutPolicy(
        kind: 'toxicity_classifier',
        preferredVersion: '2.0.0',
        minimumSupportedVersion: '1.2.0',
      );
      final decision =
          decideModelRollout(policy: strict, installedVersion: '1.0.0');
      expect(decision.action, RolloutAction.clientUpdateRequired);
    });

    test('a policy without a preferred version is inert', () {
      const empty = ModelRolloutPolicy(kind: 'translation');
      final decision =
          decideModelRollout(policy: empty, installedVersion: '1.0.0');
      expect(decision.action, RolloutAction.upToDate);
    });

    test('parses the server JSON shape', () {
      final parsed = ModelRolloutPolicy.fromJson(const <String, dynamic>{
        'kind': 'toxicity_classifier',
        'preferred_version': '1.2.0',
        'minimum_supported_version': '1.0.0',
      });
      expect(parsed.kind, 'toxicity_classifier');
      expect(parsed.preferredVersion, '1.2.0');
      expect(parsed.minimumSupportedVersion, '1.0.0');
    });
  });

  group('BundleStore', () {
    late Directory temp;
    late BundleStore store;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('bundle_store_test');
      store = BundleStore(
        root: Directory('${temp.path}/models'),
        verifier: buildVerifier(),
      );
    });

    tearDown(() {
      if (temp.existsSync()) temp.deleteSync(recursive: true);
    });

    Future<BundleInstallResult> install(
      String manifest,
      String signature,
      String payload, {
      int? freeBytes,
    }) =>
        store.installBytes(
          manifestBytes: utf8.encode(manifest),
          signature: signature,
          payload: utf8.encode(payload),
          freeBytes: freeBytes,
          reserveBytes: 0,
        );

    test('installs a verified bundle and activates it', () async {
      final result = await install(
        kFixtureManifestV120,
        kFixtureSigV120,
        kFixturePayloadHello,
      );
      expect(result.installed, isTrue);

      final active = await store.activeModel('toxicity_classifier');
      expect(active, isNotNull);
      expect(active!.version, '1.2.0');
      expect(active.payloadFile.existsSync(), isTrue);
      expect(active.signatureFile.existsSync(), isTrue);
      expect(
        await store.installedVersions(
          kind: 'toxicity_classifier',
          modelId: 'toxicity-multilingual-tiny',
        ),
        <String>['1.2.0'],
      );
    });

    test('reinstalling the same version is idempotent', () async {
      await install(kFixtureManifestV120, kFixtureSigV120, kFixturePayloadHello);
      await install(kFixtureManifestV120, kFixtureSigV120, kFixturePayloadHello);
      final versions = await store.installedVersions(
        kind: 'toxicity_classifier',
        modelId: 'toxicity-multilingual-tiny',
      );
      expect(versions, <String>['1.2.0']);
    });

    test('rejects a corrupt bundle without touching the active model',
        () async {
      final result = await install(
        kFixtureManifestV120,
        kFixtureSigV120,
        'hellp',
      );
      expect(result.installed, isFalse);
      expect(result.failure, BundleFailureReason.payloadDigestMismatch);
      expect(await store.activeModel('toxicity_classifier'), isNull);
      expect(store.kindDirectory('toxicity_classifier').existsSync(), isFalse);
    });

    test('refuses installs when storage is insufficient', () async {
      final result = await install(
        kFixtureManifestV120,
        kFixtureSigV120,
        kFixturePayloadHello,
        freeBytes: 4,
      );
      expect(result.failure, BundleFailureReason.insufficientStorage);
      expect(await store.activeModel('toxicity_classifier'), isNull);
    });

    test('rollback activates the previous version and never deletes newer',
        () async {
      await install(kFixtureManifestV100, kFixtureSigV100, kFixturePayloadAbc);
      await install(kFixtureManifestV120, kFixtureSigV120, kFixturePayloadHello);
      await install(kFixtureManifestV200, kFixtureSigV200, kFixturePayloadWorld);

      var active = await store.activeModel('toxicity_classifier');
      expect(active!.version, '2.0.0');

      expect(await store.rollback('toxicity_classifier'), isTrue);
      active = await store.activeModel('toxicity_classifier');
      expect(active!.version, '1.2.0');
      // The newer 2.0.0 install is still present, not uninstalled.
      expect(
        Directory(
          '${store.kindDirectory('toxicity_classifier').path}'
          '/toxicity-multilingual-tiny/2.0.0',
        ).existsSync(),
        isTrue,
      );

      expect(await store.rollback('toxicity_classifier'), isTrue);
      active = await store.activeModel('toxicity_classifier');
      expect(active!.version, '2.0.0');
    });

    test('prune keeps the active version and the newest N non-active versions',
        () async {
      await install(kFixtureManifestV100, kFixtureSigV100, kFixturePayloadAbc);
      await install(kFixtureManifestV120, kFixtureSigV120, kFixturePayloadHello);
      await install(kFixtureManifestV200, kFixtureSigV200, kFixturePayloadWorld);
      await store.rollback('toxicity_classifier'); // active 1.2.0

      await store.pruneOldVersions(
        kind: 'toxicity_classifier',
        modelId: 'toxicity-multilingual-tiny',
        keep: 1,
      );

      final base = '${store.kindDirectory('toxicity_classifier').path}'
          '/toxicity-multilingual-tiny';
      expect(Directory('$base/2.0.0').existsSync(), isTrue);
      expect(Directory('$base/1.2.0').existsSync(), isTrue,
          reason: 'active is never pruned');
      expect(Directory('$base/1.0.0').existsSync(), isFalse);
    });

    test('installs from a verified staging directory', () async {
      final staging = Directory('${temp.path}/staging')
        ..createSync(recursive: true);
      File('${staging.path}/manifest.json')
          .writeAsBytesSync(utf8.encode(kFixtureManifestV120));
      File('${staging.path}/manifest.sig')
          .writeAsStringSync(kFixtureSigV120);
      File('${staging.path}/payload.bin')
          .writeAsStringSync(kFixturePayloadHello);

      final result = await store.installDirectory(staging);
      expect(result.installed, isTrue);
      expect(staging.existsSync(), isFalse, reason: 'renamed, not copied');
      final active = await store.activeModel('toxicity_classifier');
      expect(active!.version, '1.2.0');
    });

    test('translation bundles are a separate kind with their own pointer',
        () async {
      final result = await install(
        kFixtureManifestTranslation,
        kFixtureSigTranslation,
        kFixturePayloadX,
      );
      expect(result.installed, isTrue);
      final activation = await store.activeModel('translation');
      expect(activation!.modelId, 'nmt-en-de');
      expect(await store.activeModel('toxicity_classifier'), isNull);
    });
  });

  group('HttpModelBundleSource', () {
    final baseUrl = Uri.parse('https://cdn.example.test/models');
    const manifestPath =
        '/models/toxicity_classifier/toxicity-multilingual-tiny/1.2.0/manifest.json';

    HttpModelBundleSource sourceWith(
      Map<String, List<int>> routes, {
      int maxPayloadBytes = 35 * 1024 * 1024,
      List<String>? requestedPaths,
    }) {
      final client = MockClient((request) async {
        requestedPaths?.add(request.url.path);
        final body = routes[request.url.path];
        if (body == null) return http.Response('not found', 404);
        return http.Response.bytes(body, 200);
      });
      return HttpModelBundleSource(
        client: client,
        maxPayloadBytes: maxPayloadBytes,
      );
    }

    test('fetches manifest, signature and payload without auth', () async {
      final requested = <String>[];
      final source = sourceWith(
        <String, List<int>>{
          manifestPath: utf8.encode(kFixtureManifestV120),
          '/models/toxicity_classifier/toxicity-multilingual-tiny/1.2.0/manifest.sig':
              utf8.encode(kFixtureSigV120),
          '/models/toxicity_classifier/toxicity-multilingual-tiny/1.2.0/payload.bin':
              utf8.encode(kFixturePayloadHello),
        },
        requestedPaths: requested,
      );

      final fetched = await source.fetch(
        baseUrl: baseUrl,
        kind: 'toxicity_classifier',
        modelId: 'toxicity-multilingual-tiny',
        version: '1.2.0',
      );
      expect(utf8.decode(fetched.payload), kFixturePayloadHello);
      expect(fetched.signature.trim(), kFixtureSigV120);
      expect(requested, hasLength(3));

      final verified = buildVerifier().verifyBytes(
        manifestBytes: fetched.manifestBytes,
        signature: fetched.signature,
        payload: fetched.payload,
      );
      expect(verified.ok, isTrue);
    });

    test('rejects an unsafe payload name before requesting it', () async {
      final requested = <String>[];
      final manifest = kFixtureManifestV120.replaceAll(
        '"payload_file":"payload.bin"',
        '"payload_file":"../evil.bin"',
      );
      final source = sourceWith(
        <String, List<int>>{manifestPath: utf8.encode(manifest)},
        requestedPaths: requested,
      );
      await expectLater(
        source.fetch(
          baseUrl: baseUrl,
          kind: 'toxicity_classifier',
          modelId: 'toxicity-multilingual-tiny',
          version: '1.2.0',
        ),
        throwsA(isA<BundleFetchException>()),
      );
      expect(requested, <String>[manifestPath]);
    });

    test('surfaces HTTP failures', () async {
      final source = sourceWith(<String, List<int>>{});
      await expectLater(
        source.fetch(
          baseUrl: baseUrl,
          kind: 'toxicity_classifier',
          modelId: 'toxicity-multilingual-tiny',
          version: '1.2.0',
        ),
        throwsA(isA<BundleFetchException>()),
      );
    });

    test('enforces the payload cap', () async {
      final source = sourceWith(
        <String, List<int>>{
          manifestPath: utf8.encode(kFixtureManifestV120),
          '/models/toxicity_classifier/toxicity-multilingual-tiny/1.2.0/payload.bin':
              utf8.encode(kFixturePayloadHello),
        },
        maxPayloadBytes: 2,
      );
      await expectLater(
        source.fetch(
          baseUrl: baseUrl,
          kind: 'toxicity_classifier',
          modelId: 'toxicity-multilingual-tiny',
          version: '1.2.0',
        ),
        throwsA(isA<BundleFetchException>()),
      );
    });

    test('rejects unsafe coordinates without a request', () async {
      final requested = <String>[];
      final source = sourceWith(<String, List<int>>{}, requestedPaths: requested);
      await expectLater(
        source.fetch(
          baseUrl: baseUrl,
          kind: 'toxicity_classifier',
          modelId: '../escape',
          version: '1.2.0',
        ),
        throwsA(isA<BundleFetchException>()),
      );
      expect(requested, isEmpty);
    });
  });
}
