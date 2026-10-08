import 'dart:convert';
import 'dart:io';

import '../../ritual/update_check.dart' show compareVersions;
import 'bundle_verifier.dart';
import 'model_manifest.dart';

class BundleInstallResult {
  final bool installed;
  final BundleFailureReason? failure;
  final String? detail;
  final String? directory;

  const BundleInstallResult.installed(this.directory)
      : installed = true,
        failure = null,
        detail = null;

  const BundleInstallResult.rejected(this.failure, {this.detail})
      : installed = false,
        directory = null;
}

/// A verified, activated model on disk.
class ActiveModelRecord {
  final String kind;
  final String modelId;
  final String version;
  final String language;
  final Directory directory;
  final String payloadFileName;

  const ActiveModelRecord({
    required this.kind,
    required this.modelId,
    required this.version,
    required this.language,
    required this.directory,
    required this.payloadFileName,
  });

  File get manifestFile => File('${directory.path}/manifest.json');
  File get signatureFile => File('${directory.path}/manifest.sig');
  File get payloadFile => File('${directory.path}/$payloadFileName');
}

/// App-private bundle storage with atomic activation and rollback.
///
/// Layout (under [root], usually `<app-support>/models`):
///
/// ```
/// <kind>/active.json                     {"model_id": ..., "version": ...}
/// <kind>/<model_id>/<version>/manifest.json
/// <kind>/<model_id>/<version>/manifest.sig
/// <kind>/<model_id>/<version>/<payload_file>
/// ```
///
/// The active pointer is written last, via a temp file rename, so a crash or
/// partial download can only leave an inert version directory behind, never a
/// half-active model. Versions are immutable: installing an existing version
/// is idempotent, and rollback only moves the pointer — it never deletes the
/// newer version, so a server that rolls its preferred version backward does
/// not remove a valid newer model.
class BundleStore {
  BundleStore({required this.root, required this.verifier});

  final Directory root;
  final BundleVerifier verifier;

  Directory kindDirectory(String kind) {
    if (!RegExp(r'^[a-z_]{1,32}$').hasMatch(kind)) {
      throw ArgumentError.value(kind, 'kind', 'unsafe kind directory name');
    }
    return Directory('${root.path}/$kind');
  }

  Directory versionDirectory(BundleManifest manifest) => Directory(
        '${kindDirectory(manifest.kind).path}/${manifest.modelId}/${manifest.version}',
      );

  File activePointer(String kind) =>
      File('${kindDirectory(kind).path}/active.json');

  /// Verifies and installs a downloaded bundle. Nothing is written before
  /// verification succeeds. [freeBytes] is an optional pre-flight probe
  /// (`StatFs`-style) so a low-storage device refuses politely instead of
  /// failing midway; pass null to skip.
  Future<BundleInstallResult> installBytes({
    required List<int> manifestBytes,
    required String signature,
    required List<int> payload,
    int? freeBytes,
    int reserveBytes = 64 * 1024 * 1024,
    bool activate = true,
  }) async {
    final verification = verifier.verifyBytes(
      manifestBytes: manifestBytes,
      signature: signature,
      payload: payload,
    );
    if (!verification.ok) {
      return BundleInstallResult.rejected(
        verification.failure,
        detail: verification.detail,
      );
    }
    final manifest = verification.manifest!;

    if (freeBytes != null && payload.length + reserveBytes > freeBytes) {
      return const BundleInstallResult.rejected(
        BundleFailureReason.insufficientStorage,
        detail: 'not enough free space for the model and reserve',
      );
    }

    final finalDirectory = versionDirectory(manifest);
    if (!await finalDirectory.exists()) {
      final staging = Directory(
        '${kindDirectory(manifest.kind).path}/.staging-'
        '${manifest.modelId}-${manifest.version}-'
        '${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        await staging.create(recursive: true);
        await File('${staging.path}/${manifest.payloadFile}')
            .writeAsBytes(payload, flush: true);
        await File('${staging.path}/manifest.json')
            .writeAsBytes(manifestBytes, flush: true);
        await File('${staging.path}/manifest.sig')
            .writeAsString(signature, flush: true);
        await finalDirectory.parent.create(recursive: true);
        await staging.rename(finalDirectory.path);
      } on FileSystemException catch (error) {
        await _quietDelete(staging);
        return BundleInstallResult.rejected(
          BundleFailureReason.unknown,
          detail: error.osError?.message ?? error.message,
        );
      }
    }

    if (activate) {
      await _writeActivePointer(manifest);
    }
    return BundleInstallResult.installed(finalDirectory.path);
  }

  /// Verifies and installs a bundle already written to [stagingDirectory]
  /// (the download-to-disk path). Files must be `manifest.json`,
  /// `manifest.sig` and the payload named by the manifest.
  Future<BundleInstallResult> installDirectory(
    Directory stagingDirectory, {
    int? freeBytes,
    int reserveBytes = 64 * 1024 * 1024,
    bool activate = true,
  }) async {
    final payloadName = await _payloadNameFromManifest(stagingDirectory);
    if (payloadName == null) {
      return const BundleInstallResult.rejected(
        BundleFailureReason.manifestMalformed,
        detail: 'staging manifest is unreadable or unsafe',
      );
    }
    final verification = await verifier.verifyFiles(
      manifestFile: File('${stagingDirectory.path}/manifest.json'),
      signatureFile: File('${stagingDirectory.path}/manifest.sig'),
      payloadFile: File('${stagingDirectory.path}/$payloadName'),
    );
    if (!verification.ok) {
      return BundleInstallResult.rejected(
        verification.failure,
        detail: verification.detail,
      );
    }
    final manifest = verification.manifest!;
    final payloadFile = File('${stagingDirectory.path}/$payloadName');
    final payloadLength = await payloadFile.length();
    if (freeBytes != null && payloadLength + reserveBytes > freeBytes) {
      return const BundleInstallResult.rejected(
        BundleFailureReason.insufficientStorage,
        detail: 'not enough free space for the model and reserve',
      );
    }
    final finalDirectory = versionDirectory(manifest);
    try {
      if (!await finalDirectory.exists()) {
        await finalDirectory.parent.create(recursive: true);
        await stagingDirectory.rename(finalDirectory.path);
      } else {
        await _quietDelete(stagingDirectory);
      }
    } on FileSystemException catch (error) {
      await _quietDelete(stagingDirectory);
      return BundleInstallResult.rejected(
        BundleFailureReason.unknown,
        detail: error.osError?.message ?? error.message,
      );
    }
    if (activate) {
      await _writeActivePointer(manifest);
    }
    return BundleInstallResult.installed(finalDirectory.path);
  }

  Future<ActiveModelRecord?> activeModel(String kind) async {
    final pointer = activePointer(kind);
    if (!await pointer.exists()) return null;
    try {
      final decoded = jsonDecode(await pointer.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final modelId = decoded['model_id'];
      final version = decoded['version'];
      if (modelId is! String || version is! String) return null;
      final directory = Directory(
        '${kindDirectory(kind).path}/$modelId/$version',
      );
      final manifestFile = File('${directory.path}/manifest.json');
      if (!await manifestFile.exists()) return null;
      final decodedManifest =
          jsonDecode(await manifestFile.readAsString());
      if (decodedManifest is! Map<String, dynamic>) return null;
      final manifest = BundleManifest.fromJson(decodedManifest);
      return ActiveModelRecord(
        kind: kind,
        modelId: manifest.modelId,
        version: manifest.version,
        language: manifest.language,
        directory: directory,
        payloadFileName: manifest.payloadFile,
      );
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  /// Installed versions for one model, newest first.
  Future<List<String>> installedVersions({
    required String kind,
    required String modelId,
  }) async {
    final directory = Directory('${kindDirectory(kind).path}/$modelId');
    if (!await directory.exists()) return const <String>[];
    final versions = <String>[];
    await for (final entity in directory.list()) {
      if (entity is! Directory) continue;
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (name.startsWith('.staging-')) continue;
      if (!RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$').hasMatch(name)) continue;
      if (!await File('${entity.path}/manifest.json').exists()) continue;
      versions.add(name);
    }
    versions.sort((a, b) => compareVersions(b, a));
    return versions;
  }

  /// Activates the newest installed version that is not currently active.
  /// Returns false when there is nothing to roll back to. Never deletes the
  /// newer version.
  Future<bool> rollback(String kind) async {
    final active = await activeModel(kind);
    if (active == null) return false;
    final versions = await installedVersions(
      kind: kind,
      modelId: active.modelId,
    );
    final target = versions.where((v) => v != active.version).toList();
    if (target.isEmpty) return false;
    await _writePointer(kind, modelId: active.modelId, version: target.first);
    return true;
  }

  /// Deletes old versions for one model, keeping the newest [keep] versions
  /// plus whatever version is active.
  Future<void> pruneOldVersions({
    required String kind,
    required String modelId,
    int keep = 2,
  }) async {
    final active = await activeModel(kind);
    final versions = await installedVersions(kind: kind, modelId: modelId);
    for (var i = 0; i < versions.length; i++) {
      final version = versions[i];
      final isActive =
          active != null && active.modelId == modelId && active.version == version;
      if (isActive) continue;
      if (i < keep) continue; // newest `keep` non-active are retained
      await _quietDelete(Directory(
        '${kindDirectory(kind).path}/$modelId/$version',
      ));
    }
  }

  Future<void> deleteEverything() => _quietDelete(root);

  Future<void> _writeActivePointer(BundleManifest manifest) => _writePointer(
        manifest.kind,
        modelId: manifest.modelId,
        version: manifest.version,
      );

  Future<void> _writePointer(
    String kind, {
    required String modelId,
    required String version,
  }) async {
    final directory = kindDirectory(kind);
    await directory.create(recursive: true);
    final temp = File('${directory.path}/active.json.tmp');
    await temp.writeAsString(
      jsonEncode(<String, String>{'model_id': modelId, 'version': version}),
      flush: true,
    );
    await temp.rename(activePointer(kind).path);
  }

  Future<String?> _payloadNameFromManifest(Directory staging) async {
    try {
      final decoded =
          jsonDecode(await File('${staging.path}/manifest.json').readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      final manifest = BundleManifest.fromJson(decoded);
      if (!manifest.hasSafePayloadFileName) return null;
      return manifest.payloadFile;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  static Future<void> _quietDelete(FileSystemEntity entity) async {
    try {
      if (await entity.exists()) {
        await entity.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup; a leftover staging directory is inert.
    }
  }
}
