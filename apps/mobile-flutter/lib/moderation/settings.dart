/// User-facing moderation sensitivity, wire-compatible with the existing
/// server-side `mod_sensitivity` column (`off`, `standard`, `strict`).
///
/// Semantics on device, per the design brief:
/// * [off] — no hidden-word holds and no classifier pass. The deterministic
///   stage still *runs* and its result is recorded (enforcement is a policy,
///   the check is not skippable), but nothing is held and translation may run.
/// * [standard] — a hidden-word hit or classifier flag is held in the local
///   filtered view with one-tap reveal; a missing classifier model or an
///   unclassified language shows the message with an explicit badge.
/// * [strict] — a hit is hidden from the main list and reveal takes a
///   deliberate two-step action; a message the classifier could not check is
///   held until it can be checked (documented trade-off on de-Googled devices
///   that never download a model).
enum ModerationSensitivity {
  off,
  standard,
  strict;

  /// Forgiving parse; unknown or absent values keep the current default.
  static ModerationSensitivity parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'off':
        return ModerationSensitivity.off;
      case 'strict':
        return ModerationSensitivity.strict;
      case 'standard':
      default:
        return ModerationSensitivity.standard;
    }
  }

  /// Exact wire value; matches [name] and the server's enum.
  String get wireValue => name;

  bool get enforcesHiddenWords => this != ModerationSensitivity.off;

  bool get runsClassifier => this != ModerationSensitivity.off;

  /// Number of deliberate taps required to reveal held content.
  int get revealSteps => switch (this) {
        ModerationSensitivity.off => 0,
        ModerationSensitivity.standard => 1,
        ModerationSensitivity.strict => 2,
      };
}
