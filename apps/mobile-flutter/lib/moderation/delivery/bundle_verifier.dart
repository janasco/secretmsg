import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../ritual/update_check.dart' show compareVersions;
import '../crypto/p256_ecdsa.dart';
import '../crypto/sha256.dart';
import 'model_manifest.dart';

/// Why a bundle was rejected. Failure is always closed: the previous active
/// model stays in place and the UI reports "model update postponed".
enum BundleFailureReason {
  manifestMalformed,
  unsupportedSchema,
  unsupportedKind,
  unsafePayloadFileName,
  missingSignature,
  malformedSignature,
  unknownSigningKey,
  invalidSignature,
  payloadEmpty,
  payloadTooLarge,
  payloadSizeMismatch,
  payloadDigestMismatch,
  appVersionTooOld,
  insufficientStorage,
  unknown,
}

class BundleVerification {
  final BundleManifest? manifest;
  final BundleFailureReason? failure;
  final String? detail;

  const BundleVerification.ok(this.manifest)
      : failure = null,
        detail = null;

  const BundleVerification.rejected(this.failure, {this.detail})
      : manifest = null;

  bool get ok => failure == null && manifest != null;
}

/// Verifies model bundles end to end before anything is installed:
///
/// 1. manifest parses (schema 1), kind is supported, payload file name is a
///    safe bare name;
/// 2. `min_app_version`, when present, is not newer than the running app;
/// 3. the manifest signature verifies under a pinning key from
///    [trustedSigningKeys] (keyed by `signing_key_id`);
/// 4. payload size equals `payload_size` and is within [maxPayloadBytes];
/// 5. SHA-256(payload) equals `payload_sha256`.
///
/// Signature is checked before hashing so a hostile 35 MB payload cannot burn
/// CPU on digesting before being rejected.
///
/// Signing keys are compiled into the app (pinned). An empty key map rejects
/// every bundle, which is the correct fail-closed default until production
/// signing keys are provisioned. Key rotation is a client release.
class BundleVerifier {
  BundleVerifier({
    required Map<String, P256PublicKey> trustedSigningKeys,
    required String appVersion,
    Set<String> supportedKinds = kSupportedModelKinds,
    this.maxPayloadBytes = 35 * 1024 * 1024,
  })  : _trustedSigningKeys = Map.unmodifiable(trustedSigningKeys),
        _appVersion = appVersion,
        _supportedKinds = supportedKinds;

  final Map<String, P256PublicKey> _trustedSigningKeys;
  final String _appVersion;
  final Set<String> _supportedKinds;

  /// Per the design budget: one shipped classifier file is ≤ 35 MB.
  final int maxPayloadBytes;

  Set<String> get trustedKeyIds => _trustedSigningKeys.keys.toSet();

  BundleVerification verifyBytes({
    required List<int> manifestBytes,
    required String signature,
    required List<int> payload,
  }) {
    final manifestResult = _parseManifest(manifestBytes);
    if (!manifestResult.ok) return manifestResult;
    final manifest = manifestResult.manifest!;

    if (manifest.payloadSize <= 0) {
      return const BundleVerification.rejected(
        BundleFailureReason.payloadEmpty,
        detail: 'payload_size must be positive',
      );
    }
    if (manifest.payloadSize > maxPayloadBytes ||
        payload.length > maxPayloadBytes) {
      return BundleVerification.rejected(
        BundleFailureReason.payloadTooLarge,
        detail: 'payload exceeds $maxPayloadBytes bytes',
      );
    }
    if (manifest.minAppVersion != null &&
        compareVersions(_appVersion, manifest.minAppVersion!) < 0) {
      return BundleVerification.rejected(
        BundleFailureReason.appVersionTooOld,
        detail: 'bundle needs app ${manifest.minAppVersion}, running $_appVersion',
      );
    }

    final signatureBytes = _decodeSignature(signature);
    if (signatureBytes == null) {
      return const BundleVerification.rejected(
        BundleFailureReason.malformedSignature,
        detail: 'signature must be base64url 64 raw bytes',
      );
    }
    final key = _trustedSigningKeys[manifest.signingKeyId];
    if (key == null) {
      return BundleVerification.rejected(
        BundleFailureReason.unknownSigningKey,
        detail: 'signing_key_id ${manifest.signingKeyId} is not pinned',
      );
    }
    final digest = Sha256.hash(manifestBytes);
    if (!P256Ecdsa.verify(
      publicKey: key,
      digest: digest,
      signature: signatureBytes,
    )) {
      return const BundleVerification.rejected(
        BundleFailureReason.invalidSignature,
      );
    }

    if (payload.length != manifest.payloadSize) {
      return BundleVerification.rejected(
        BundleFailureReason.payloadSizeMismatch,
        detail: 'expected ${manifest.payloadSize} bytes, got ${payload.length}',
      );
    }
    final payloadDigest = Sha256.hex(payload);
    if (payloadDigest != manifest.payloadSha256.toLowerCase()) {
      return const BundleVerification.rejected(
        BundleFailureReason.payloadDigestMismatch,
      );
    }

    return BundleVerification.ok(manifest);
  }

  /// Verifies files on disk. The payload is streamed through SHA-256 rather
  /// than loaded into memory.
  Future<BundleVerification> verifyFiles({
    required File manifestFile,
    required File signatureFile,
    required File payloadFile,
  }) async {
    if (!await manifestFile.exists() ||
        !await signatureFile.exists() ||
        !await payloadFile.exists()) {
      return const BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'bundle file missing',
      );
    }
    final Uint8List manifestBytes;
    final String signature;
    try {
      manifestBytes = await manifestFile.readAsBytes();
      signature = await signatureFile.readAsString();
    } on FileSystemException catch (error) {
      return BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: error.osError?.message,
      );
    }

    final manifestResult = _parseManifest(manifestBytes);
    if (!manifestResult.ok) return manifestResult;
    final manifest = manifestResult.manifest!;

    final payloadLength = await payloadFile.length();
    if (payloadLength <= 0) {
      return const BundleVerification.rejected(BundleFailureReason.payloadEmpty);
    }
    if (payloadLength > maxPayloadBytes) {
      return BundleVerification.rejected(
        BundleFailureReason.payloadTooLarge,
        detail: 'payload exceeds $maxPayloadBytes bytes',
      );
    }
    if (manifest.minAppVersion != null &&
        compareVersions(_appVersion, manifest.minAppVersion!) < 0) {
      return BundleVerification.rejected(
        BundleFailureReason.appVersionTooOld,
        detail: 'bundle needs app ${manifest.minAppVersion}, running $_appVersion',
      );
    }

    final signatureBytes = _decodeSignature(signature);
    if (signatureBytes == null) {
      return const BundleVerification.rejected(
        BundleFailureReason.malformedSignature,
      );
    }
    final key = _trustedSigningKeys[manifest.signingKeyId];
    if (key == null) {
      return BundleVerification.rejected(
        BundleFailureReason.unknownSigningKey,
        detail: 'signing_key_id ${manifest.signingKeyId} is not pinned',
      );
    }
    if (!P256Ecdsa.verify(
      publicKey: key,
      digest: Sha256.hash(manifestBytes),
      signature: signatureBytes,
    )) {
      return const BundleVerification.rejected(
        BundleFailureReason.invalidSignature,
      );
    }

    if (payloadLength != manifest.payloadSize) {
      return BundleVerification.rejected(
        BundleFailureReason.payloadSizeMismatch,
        detail: 'expected ${manifest.payloadSize} bytes, got $payloadLength',
      );
    }
    final digest = await sha256File(payloadFile);
    if (digest != manifest.payloadSha256.toLowerCase()) {
      return const BundleVerification.rejected(
        BundleFailureReason.payloadDigestMismatch,
      );
    }
    return BundleVerification.ok(manifest);
  }

  BundleVerification _parseManifest(List<int> manifestBytes) {
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(manifestBytes));
    } on FormatException catch (error) {
      return BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: error.message,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return const BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'manifest must be a JSON object',
      );
    }
    final BundleManifest manifest;
    try {
      manifest = BundleManifest.fromJson(decoded);
    } on FormatException catch (error) {
      return BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: error.message,
      );
    }
    if (manifest.schema != kCurrentBundleSchema) {
      return BundleVerification.rejected(
        BundleFailureReason.unsupportedSchema,
        detail: 'schema ${manifest.schema}',
      );
    }
    if (!_supportedKinds.contains(manifest.kind)) {
      return BundleVerification.rejected(
        BundleFailureReason.unsupportedKind,
        detail: manifest.kind,
      );
    }
    if (!manifest.hasSafePayloadFileName) {
      return BundleVerification.rejected(
        BundleFailureReason.unsafePayloadFileName,
        detail: manifest.payloadFile,
      );
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(manifest.payloadSha256)) {
      return const BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'payload_sha256 must be 64 lowercase hex chars',
      );
    }
    if (!RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$').hasMatch(manifest.modelId)) {
      return const BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'model_id must be a safe path segment',
      );
    }
    if (!RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$').hasMatch(manifest.version)) {
      return const BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'version must be numeric x.y.z',
      );
    }
    if (!RegExp(r'^[A-Za-z0-9-]{1,16}$').hasMatch(manifest.language)) {
      return const BundleVerification.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'language must be a short BCP-47 tag',
      );
    }
    return BundleVerification.ok(manifest);
  }

  static Uint8List? _decodeSignature(String signature) {
    try {
      return P256Ecdsa.parseSignature(signature);
    } on FormatException {
      return null;
    }
  }

  /// Streaming SHA-256 of a file.
  static Future<String> sha256File(File file) async {
    final sha = Sha256();
    await for (final chunk in file.openRead()) {
      sha.update(chunk);
    }
    return Sha256.toHex(sha.digest());
  }
}
