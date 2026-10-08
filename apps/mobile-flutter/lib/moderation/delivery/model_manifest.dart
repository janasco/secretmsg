/// Canonical model-bundle manifest (schema 1).
///
/// ```json
/// {
///   "schema": 1,
///   "kind": "toxicity_classifier",
///   "model_id": "toxicity-multilingual-tiny",
///   "version": "1.2.0",
///   "language": "mul",
///   "payload_file": "model.tflite",
///   "payload_size": 1234567,
///   "payload_sha256": "<64 lowercase hex chars>",
///   "min_app_version": "1.8.0",
///   "signing_key_id": "secretmsg-model-signing-2026-1",
///   "description": "optional human-readable text"
/// }
/// ```
///
/// `manifest.sig` is a detached ES256 signature (NIST P-256 / SHA-256) over
/// the exact `manifest.json` bytes, encoded base64url as 64 raw bytes
/// `r || s`. The signature must be verified before any field in this manifest
/// is trusted; the SHA-256 digest of the payload is then checked against
/// [payloadSha256].
///
/// The manifest contains no content and no user data, so it is safe to cache
/// and log. The payload is the model weights and belongs in app-private
/// storage only.
library;

const Set<String> kSupportedModelKinds = <String>{
  'toxicity_classifier',
  'translation',
  'language_id',
};

const int kCurrentBundleSchema = 1;

class BundleManifest {
  final int schema;
  final String kind;
  final String modelId;
  final String version;
  final String language;
  final String payloadFile;
  final int payloadSize;
  final String payloadSha256;
  final String? minAppVersion;
  final String signingKeyId;
  final String? description;

  const BundleManifest({
    required this.schema,
    required this.kind,
    required this.modelId,
    required this.version,
    required this.language,
    required this.payloadFile,
    required this.payloadSize,
    required this.payloadSha256,
    required this.signingKeyId,
    this.minAppVersion,
    this.description,
  });

  factory BundleManifest.fromJson(Map<String, dynamic> json) =>
      BundleManifest(
        schema: _requireInt(json, 'schema'),
        kind: _requireString(json, 'kind'),
        modelId: _requireString(json, 'model_id'),
        version: _requireString(json, 'version'),
        language: _requireString(json, 'language'),
        payloadFile: _requireString(json, 'payload_file'),
        payloadSize: _requireInt(json, 'payload_size'),
        payloadSha256: _requireString(json, 'payload_sha256'),
        signingKeyId: _requireString(json, 'signing_key_id'),
        minAppVersion: _optionalString(json, 'min_app_version'),
        description: _optionalString(json, 'description'),
      );

  /// True when [payloadFile] is a bare file name that cannot escape the model
  /// directory.
  bool get hasSafePayloadFileName {
    if (payloadFile.isEmpty || payloadFile.length > 64) return false;
    if (payloadFile == '.' || payloadFile == '..') return false;
    if (payloadFile.contains('/') || payloadFile.contains(r'\')) return false;
    return true;
  }

  @override
  String toString() => 'BundleManifest($kind/$modelId@$version)';
}

String _requireString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('manifest.$key must be a non-empty string');
  }
  return value;
}

String? _optionalString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('manifest.$key must be a string when present');
  }
  return value;
}

int _requireInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  if (value is num && value == value.truncate()) return value.toInt();
  throw FormatException('manifest.$key must be an integer');
}
