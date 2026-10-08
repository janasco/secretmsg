import '../../ritual/update_check.dart' show compareVersions;

/// Server-published rollout policy for one model kind.
///
/// * [preferredVersion] controls staged rollout. When it is newer than the
///   installed version, the client should download and install it. When it is
///   *older* than an installed valid version, the client keeps the newer
///   version — a rollback of the preferred version never uninstalls or
///   downgrades a model that already passed verification.
/// * [minimumSupportedVersion] controls compatibility. An installed model
///   older than the minimum is no longer acceptable to run; the client uses
///   no model until it updates (or, for classifier kinds, shows the
///   "unavailable" state rather than presenting unchecked content as clean).
class ModelRolloutPolicy {
  final String kind;
  final String? preferredVersion;
  final String? minimumSupportedVersion;

  const ModelRolloutPolicy({
    required this.kind,
    this.preferredVersion,
    this.minimumSupportedVersion,
  });

  factory ModelRolloutPolicy.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    if (kind is! String || kind.isEmpty) {
      throw const FormatException('rollout policy needs a kind');
    }
    return ModelRolloutPolicy(
      kind: kind,
      preferredVersion: _stringOrNull(json['preferred_version']),
      minimumSupportedVersion: _stringOrNull(json['minimum_supported_version']),
    );
  }

  static String? _stringOrNull(Object? value) {
    if (value == null) return null;
    if (value is! String) throw const FormatException('version must be a string');
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum RolloutAction {
  /// Nothing to do.
  upToDate,

  /// Download and install [ModelRolloutDecision.targetVersion].
  install,

  /// Installed version is newer than preferred; keep it.
  keepNewerInstalled,

  /// Installed model is below the minimum supported version; do not run it.
  clientUpdateRequired,
}

class ModelRolloutDecision {
  final RolloutAction action;
  final String? targetVersion;
  final String? reason;

  const ModelRolloutDecision(this.action, {this.targetVersion, this.reason});
}

/// Pure decision function so rollout/rollback behavior is testable without
/// network or disk.
ModelRolloutDecision decideModelRollout({
  required ModelRolloutPolicy policy,
  required String? installedVersion,
}) {
  final minimum = policy.minimumSupportedVersion;
  if (installedVersion != null &&
      minimum != null &&
      compareVersions(installedVersion, minimum) < 0) {
    return ModelRolloutDecision(
      RolloutAction.clientUpdateRequired,
      reason: 'installed $installedVersion is below minimum $minimum',
    );
  }

  final preferred = policy.preferredVersion;
  if (preferred == null) {
    return const ModelRolloutDecision(RolloutAction.upToDate);
  }
  if (installedVersion == null) {
    return ModelRolloutDecision(
      RolloutAction.install,
      targetVersion: preferred,
      reason: 'no installed version',
    );
  }
  final comparison = compareVersions(installedVersion, preferred);
  if (comparison < 0) {
    return ModelRolloutDecision(
      RolloutAction.install,
      targetVersion: preferred,
      reason: 'preferred $preferred is newer than installed $installedVersion',
    );
  }
  if (comparison > 0) {
    return ModelRolloutDecision(
      RolloutAction.keepNewerInstalled,
      targetVersion: installedVersion,
      reason: 'installed $installedVersion is newer than preferred $preferred',
    );
  }
  return const ModelRolloutDecision(RolloutAction.upToDate);
}
