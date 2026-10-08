/// Toxicity categories, matching the taxonomy in the design brief. A result
/// carries a score per category; there is deliberately no single "bad"
/// boolean.
enum ToxicityLabel {
  harassment,
  hate,
  sexual,
  violentThreat,
  selfHarm,
  spamScam;

  /// Stable identifier used in local storage and in future content-free
  /// feedback. Never sent anywhere automatically.
  String get id => name;
}

class ToxicityScore {
  final ToxicityLabel label;
  final double score;

  const ToxicityScore(this.label, this.score);
}

/// What happened when the classifier was asked about a message.
enum ClassifierAvailability {
  /// The model ran and produced scores.
  checked,

  /// No usable model is installed (first run, de-Googled device before a
  /// download, storage pressure). The message is *not* checked and the UI must
  /// say so.
  modelUnavailable,

  /// A model is installed but does not claim the message's language. The
  /// message is *not* checked for that language and must not be presented as
  /// clean.
  languageUnsupported,
}

/// Which text the scores are about.
enum ClassifierInput {
  /// The decrypted original (the normal order: classifier before translation).
  original,

  /// The on-device translation, used only when the original language is not
  /// supported and a translation is available. The UI must label this.
  translation,
}

/// One classifier run.
class ClassifierResult {
  final ClassifierAvailability availability;
  final List<ToxicityScore> scores;
  final ClassifierInput input;
  final String? languageTag;
  final String? modelId;
  final String? modelVersion;

  const ClassifierResult({
    required this.availability,
    this.scores = const [],
    this.input = ClassifierInput.original,
    this.languageTag,
    this.modelId,
    this.modelVersion,
  });

  bool get wasChecked => availability == ClassifierAvailability.checked;

  /// Categories at or above the supplied per-category thresholds.
  List<ToxicityLabel> flaggedLabels(ToxicityThresholds thresholds) => scores
      .where((score) => score.score >= thresholds.forLabel(score.label))
      .map((score) => score.label)
      .toList(growable: false);
}

/// Per-category thresholds. Release gates in the design brief require these to
/// be tuned per category and per language, never globally; the defaults here
/// are placeholders until a trained model and its eval report exist.
class ToxicityThresholds {
  final double harassment;
  final double hate;
  final double sexual;
  final double violentThreat;
  final double selfHarm;
  final double spamScam;

  const ToxicityThresholds({
    this.harassment = 0.5,
    this.hate = 0.5,
    this.sexual = 0.5,
    this.violentThreat = 0.5,
    this.selfHarm = 0.5,
    this.spamScam = 0.5,
  });

  double forLabel(ToxicityLabel label) => switch (label) {
        ToxicityLabel.harassment => harassment,
        ToxicityLabel.hate => hate,
        ToxicityLabel.sexual => sexual,
        ToxicityLabel.violentThreat => violentThreat,
        ToxicityLabel.selfHarm => selfHarm,
        ToxicityLabel.spamScam => spamScam,
      };
}

/// The classifier seam.
///
/// The production plan (see `docs/on-device-moderation.md`) is an int8
/// quantized multilingual transformer-style text classifier executed in a
/// background isolate through the platform ML runtime, shipped as a signed
/// bundle. No trained weights ship in this change;
/// [UnavailableToxicityClassifier] is the honest default and the pipeline
/// treats its output as "not checked", never as "clean".
abstract interface class ToxicityClassifier {
  /// Stable model identifier written next to any local flag.
  String get id;

  /// Installed model version, or `null` when no model is loaded.
  String? get version;

  /// Language prefixes (`en`, `de`, `mul`, ...) the loaded model claims.
  Set<String> get supportedLanguagePrefixes;

  bool get isModelInstalled;

  /// Loads/validates the model. Safe to call repeatedly.
  Future<void> warmUp();

  Future<ClassifierResult> classify(
    String text, {
    required String languageTag,
    ClassifierInput input = ClassifierInput.original,
  });

  Future<void> dispose();
}

/// Ships in the APK and is wired by default until a signed classifier bundle
/// is installed. It never guesses: every call reports `modelUnavailable`, the
/// pipeline holds in `strict` and shows an "AI check unavailable" badge in
/// `standard`.
///
/// **This is not a working ML model.** Treating it as one would be dishonest.
class UnavailableToxicityClassifier implements ToxicityClassifier {
  const UnavailableToxicityClassifier();

  @override
  String get id => 'unavailable';

  @override
  String? get version => null;

  @override
  Set<String> get supportedLanguagePrefixes => const <String>{};

  @override
  bool get isModelInstalled => false;

  @override
  Future<void> warmUp() async {}

  @override
  Future<ClassifierResult> classify(
    String text, {
    required String languageTag,
    ClassifierInput input = ClassifierInput.original,
  }) async =>
      ClassifierResult(
        availability: ClassifierAvailability.modelUnavailable,
        input: input,
        languageTag: languageTag,
      );

  @override
  Future<void> dispose() async {}
}
