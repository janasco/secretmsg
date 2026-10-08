import 'dart:convert';

import 'package:http/http.dart' as http;

import 'model_manifest.dart';

class FetchedBundle {
  final List<int> manifestBytes;
  final String signature;
  final List<int> payload;
  final Uri manifestUri;

  const FetchedBundle({
    required this.manifestBytes,
    required this.signature,
    required this.payload,
    required this.manifestUri,
  });
}

class BundleFetchException implements Exception {
  final String message;

  const BundleFetchException(this.message);

  @override
  String toString() => 'BundleFetchException: $message';
}

/// Fetches signed model bundles over plain HTTPS from first-party storage.
///
/// De-Googled / sideload requirement: this path uses `package:http` directly,
/// sends no auth token, no account identifier and no message content, and has
/// no Play Services or Firebase dependency. The same bundles are served to the
/// Play track (optionally through Play Feature Delivery) and to sideload users.
///
/// Not implemented in this change, and required before shipping a large pack:
/// resumable transfer, Wi-Fi-only preference, and streaming the payload to
/// disk with an incremental digest instead of buffering it in memory. The
/// primitive here buffers with a hard cap so the verification and install
/// behavior can be exercised end to end in tests.
abstract interface class ModelBundleSource {
  Future<FetchedBundle> fetch({
    required Uri baseUrl,
    required String kind,
    required String modelId,
    required String version,
  });

  void close();
}

class HttpModelBundleSource implements ModelBundleSource {
  HttpModelBundleSource({
    http.Client? client,
    this.maxManifestBytes = 64 * 1024,
    this.maxPayloadBytes = 35 * 1024 * 1024,
    this.timeout = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final int maxManifestBytes;
  final int maxPayloadBytes;
  final Duration timeout;

  static final RegExp _safeSegment = RegExp(r'^[a-z0-9][a-z0-9._-]{0,63}$');

  @override
  Future<FetchedBundle> fetch({
    required Uri baseUrl,
    required String kind,
    required String modelId,
    required String version,
  }) async {
    if (!_safeSegment.hasMatch(kind) ||
        !_safeSegment.hasMatch(modelId) ||
        !_safeSegment.hasMatch(version)) {
      throw const BundleFetchException('unsafe bundle coordinates');
    }
    final manifestUri = _bundleUri(baseUrl, kind, modelId, version, 'manifest.json');
    final manifestBytes = await _getBytes(manifestUri, maxManifestBytes);

    final BundleManifest manifest;
    try {
      final decoded = jsonDecode(utf8.decode(manifestBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('manifest is not an object');
      }
      manifest = BundleManifest.fromJson(decoded);
    } on FormatException catch (error) {
      throw BundleFetchException('manifest rejected before download: ${error.message}');
    }
    if (!manifest.hasSafePayloadFileName) {
      throw const BundleFetchException('unsafe payload file name in manifest');
    }

    final payloadUri = _bundleUri(
      baseUrl,
      kind,
      modelId,
      version,
      manifest.payloadFile,
    );
    final signatureUri = _bundleUri(baseUrl, kind, modelId, version, 'manifest.sig');
    final payload = await _getBytes(payloadUri, maxPayloadBytes);
    if (payload.length != manifest.payloadSize) {
      throw BundleFetchException(
        'payload size mismatch: expected ${manifest.payloadSize}, got ${payload.length}',
      );
    }
    final signatureBytes = await _getBytes(signatureUri, 256);
    final signature = utf8.decode(signatureBytes).trim();

    return FetchedBundle(
      manifestBytes: manifestBytes,
      signature: signature,
      payload: payload,
      manifestUri: manifestUri,
    );
  }

  Future<List<int>> _getBytes(Uri uri, int maxBytes) async {
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on Exception catch (error) {
      throw BundleFetchException('GET $uri failed: $error');
    }
    if (response.statusCode != 200) {
      throw BundleFetchException('GET $uri returned ${response.statusCode}');
    }
    final declared = response.headers['content-length'];
    if (declared != null) {
      final length = int.tryParse(declared);
      if (length != null && length > maxBytes) {
        throw BundleFetchException('GET $uri exceeds $maxBytes bytes');
      }
    }
    if (response.bodyBytes.length > maxBytes) {
      throw BundleFetchException('GET $uri exceeds $maxBytes bytes');
    }
    return response.bodyBytes;
  }

  static Uri _bundleUri(
    Uri baseUrl,
    String kind,
    String modelId,
    String version,
    String file,
  ) {
    final segments = <String>[
      ...baseUrl.pathSegments.where((s) => s.isNotEmpty),
      kind,
      modelId,
      version,
      file,
    ];
    return baseUrl.replace(pathSegments: segments);
  }

  @override
  void close() {
    if (_ownsClient) _client.close();
  }
}
