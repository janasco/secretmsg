import '../classifier/toxicity_classifier.dart';
import '../settings.dart';

/// The fixed pipeline order. Nothing may be inserted, reordered or skipped:
///
/// 1. [decrypt] — moderation only ever runs on recipient-side plaintext.
/// 2. [normalize] — one pass produces the display form and the matching
///    skeleton; bidi controls are neutralized before anything renders.
/// 3. [hiddenWords] — deterministic, evasion-resistant matches. Always
///    executed (even at sensitivity `off`) so a later stage can never run
///    before it and so the outcome records what the check saw.
/// 4. [classifier] — probabilistic labels on the original text.
/// 5. [translation] — only for text that is not held; a translation is never
///    produced for content that will be hidden.
/// 6. [render] — the outcome model the UI draws from.
enum ModerationStage { decrypt, normalize, hiddenWords, classifier, translation, render }

extension ModerationStageLabel on ModerationStage {
  String get label => switch (this) {
        ModerationStage.decrypt => 'decrypt',
        ModerationStage.normalize => 'normalize',
        ModerationStage.hiddenWords => 'hidden-words',
        ModerationStage.classifier => 'classifier',
        ModerationStage.translation => 'translation',
        ModerationStage.render => 'render',
      };
}

/// Why a message was held. `code` is stable and local-only.
class ModerationReason {
  final ModerationStage stage;
  final String code;

  /// Hidden-word entry that matched, when [code] is `hidden_word`.
  final String? word;

  /// Toxicity label that crossed its threshold, when [code] is `classifier`.
  final String? label;

  const ModerationReason({
    required this.stage,
    required this.code,
    this.word,
    this.label,
  });

  static const String codeHiddenWord = 'hidden_word';
  static const String codeClassifierFlag = 'classifier_flag';
  static const String codeClassifierUnavailable = 'classifier_unavailable';
  static const String codeLanguageNotChecked = 'language_not_checked';
}

/// Non-blocking facts the UI should surface. None of these are ever sent
/// anywhere automatically.
enum ModerationBadge {
  /// No classifier model is installed; the message was not checked by the
  /// probabilistic stage. Must never be presented as "clean".
  aiCheckUnavailable,

  /// A model is installed but does not claim this message's language.
  languageNotChecked,

  /// Translation was requested but no pack covers this pair.
  translationUnavailable,

  /// The model ran and failed; the original is shown unchanged. Distinct from
  /// [translationUnavailable] in user-facing copy.
  translationFailed,

  /// Same-script language could not be identified, so no translation was
  /// attempted. Distinct from failure.
  translationSkippedUnknownLanguage,

  /// The displayed text is an on-device translation; the original is kept.
  translated,

  /// Bidi or invisible formatting characters were neutralized before render.
  formattingNeutralized,
}

enum ModerationAction { allow, hold }

/// The data-only render model produced by the pipeline.
///
/// [displayText] is what a revealed message shows (the translation when one
/// happened, otherwise the control-neutralized original). While [held] is
/// true the UI must render the hold stub and must not draw [displayText]
/// until the user completes [revealSteps] deliberate actions.
class ModerationOutcome {
  final String messageId;
  final ModerationSensitivity sensitivity;
  final ModerationAction action;
  final int revealSteps;
  final List<ModerationReason> reasons;
  final Set<ModerationBadge> badges;
  final List<ModerationStage> executedStages;
  final String originalText;
  final String displayText;
  final bool translated;
  final String? translatedFrom;
  final String? translationModelVersion;
  final bool classifierChecked;
  final List<ToxicityScore> classifierScores;
  final String? classifierModelVersion;

  const ModerationOutcome({
    required this.messageId,
    required this.sensitivity,
    required this.action,
    required this.revealSteps,
    required this.reasons,
    required this.badges,
    required this.executedStages,
    required this.originalText,
    required this.displayText,
    required this.translated,
    this.translatedFrom,
    this.translationModelVersion,
    required this.classifierChecked,
    this.classifierScores = const [],
    this.classifierModelVersion,
  });

  bool get held => action == ModerationAction.hold;

  bool get wasClassifierRun => classifierChecked;

  ModerationReason? get primaryReason => reasons.isEmpty ? null : reasons.first;
}
