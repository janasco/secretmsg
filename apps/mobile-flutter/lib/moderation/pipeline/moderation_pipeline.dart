import '../classifier/toxicity_classifier.dart';
import '../settings.dart';
import '../text/hidden_words.dart';
import '../text/text_normalizer.dart';
import '../translation/language_id.dart';
import '../translation/translator.dart';
import 'decryptor.dart';
import 'moderation_outcome.dart';

/// The fixed, ordered on-device moderation pipeline:
///
/// ```
/// decrypt -> normalize -> deterministic hidden-words -> classifier
///         -> translation -> render
/// ```
///
/// Order rationale (mirrored in `docs/on-device-moderation.md`):
///
/// * The deterministic stage always runs before any model and cannot be
///   skipped. Sensitivity `off` disables *enforcement* (no holds), not the
///   check itself; a probabilistic model must never be the first line of
///   defence, because it is slower, costlier and independently fallible.
/// * A held message never reaches the classifier or the translator. That
///   saves the expensive stages and guarantees no translation is produced for
///   text that will be blocked.
/// * The classifier runs on the original text before translation. It may run
///   a second time on the translation only when the original language is not
///   supported and a translation exists; the outcome records that the check
///   was on the translation.
/// * Render always happens last and only from the outcome; it never re-reads
///   the raw envelope.
class ModerationPipeline {
  ModerationPipeline({
    required MessageDecryptor decryptor,
    ToxicityClassifier? classifier,
    OnDeviceTranslator? translator,
    LanguageIdentifier? languageIdentifier,
    TextNormalizer normalizer = const TextNormalizer(),
    HiddenWordsFilter? hiddenWords,
    ToxicityThresholds thresholds = const ToxicityThresholds(),
  })  : _decryptor = decryptor,
        _classifier = classifier ?? const UnavailableToxicityClassifier(),
        _translator = translator ?? const UnavailableTranslator(),
        _languageIdentifier =
            languageIdentifier ?? const ScriptHeuristicLanguageIdentifier(),
        _normalizer = normalizer,
        _hiddenWords = hiddenWords ??
            HiddenWordsFilter(words: const <String>[], normalizer: normalizer),
        _thresholds = thresholds;

  final MessageDecryptor _decryptor;
  final ToxicityClassifier _classifier;
  final OnDeviceTranslator _translator;
  final LanguageIdentifier _languageIdentifier;
  final TextNormalizer _normalizer;
  final ToxicityThresholds _thresholds;
  HiddenWordsFilter _hiddenWords;

  /// Recompiles the recipient's blocklist. Cheap relative to a message, and
  /// the pipeline keeps the compiled filter so matching is deterministic and
  /// stable for the session.
  void updateHiddenWords(List<String> words) {
    _hiddenWords = HiddenWordsFilter(words: words, normalizer: _normalizer);
  }

  Future<ModerationOutcome> process(
    EncryptedEnvelope envelope, {
    required String userLanguage,
    ModerationSensitivity sensitivity = ModerationSensitivity.standard,
    bool translationEnabled = false,
  }) async {
    final stages = <ModerationStage>[ModerationStage.decrypt];
    final decrypted = await _decryptor.decrypt(envelope);

    stages.add(ModerationStage.normalize);
    final normalized = _normalizer.normalize(decrypted.content);

    // Deterministic stage: always executed, first model-free check.
    stages.add(ModerationStage.hiddenWords);
    final hiddenMatch = _hiddenWords.firstMatch(normalized);

    final reasons = <ModerationReason>[];
    final badges = <ModerationBadge>{};
    if (normalized.flags.hasBidiControls ||
        normalized.flags.hasInvisibleCharacters) {
      badges.add(ModerationBadge.formattingNeutralized);
    }

    var action = ModerationAction.allow;
    var revealSteps = 0;
    void hold(int steps, ModerationReason reason) {
      action = ModerationAction.hold;
      if (steps > revealSteps) revealSteps = steps;
      reasons.add(reason);
    }

    if (hiddenMatch != null && sensitivity.enforcesHiddenWords) {
      hold(
        sensitivity.revealSteps,
        ModerationReason(
          stage: ModerationStage.hiddenWords,
          code: ModerationReason.codeHiddenWord,
          word: hiddenMatch.word,
        ),
      );
    }

    final detected = _detectLanguage(decrypted, normalized);

    var classifierChecked = false;
    var classifierScores = const <ToxicityScore>[];
    String? classifierVersion;
    var classifierLanguageUnsupported = false;

    if (action == ModerationAction.allow && sensitivity.runsClassifier) {
      stages.add(ModerationStage.classifier);
      final result = await _classifier.classify(
        normalized.display,
        languageTag: detected.tag,
      );
      classifierChecked = result.wasChecked;
      classifierScores = result.scores;
      classifierVersion = result.modelVersion;

      switch (result.availability) {
        case ClassifierAvailability.checked:
          final flagged = result.flaggedLabels(_thresholds);
          if (flagged.isNotEmpty) {
            hold(
              sensitivity.revealSteps,
              ModerationReason(
                stage: ModerationStage.classifier,
                code: ModerationReason.codeClassifierFlag,
                label: flagged.first.id,
              ),
            );
          }
        case ClassifierAvailability.modelUnavailable:
          badges.add(ModerationBadge.aiCheckUnavailable);
          if (sensitivity == ModerationSensitivity.strict) {
            hold(
              2,
              const ModerationReason(
                stage: ModerationStage.classifier,
                code: ModerationReason.codeClassifierUnavailable,
              ),
            );
          }
        case ClassifierAvailability.languageUnsupported:
          classifierLanguageUnsupported = true;
          badges.add(ModerationBadge.languageNotChecked);
          if (sensitivity == ModerationSensitivity.strict) {
            hold(
              2,
              const ModerationReason(
                stage: ModerationStage.classifier,
                code: ModerationReason.codeLanguageNotChecked,
              ),
            );
          }
      }
    }

    var displayText = normalized.display;
    var translated = false;
    String? translatedFrom;
    String? translationModelVersion;

    if (action == ModerationAction.allow && translationEnabled) {
      stages.add(ModerationStage.translation);

      if (displayText.trim().isEmpty) {
        // nothing to translate
      } else if (detected.isUnknown) {
        badges.add(ModerationBadge.translationSkippedUnknownLanguage);
      } else if (scriptOfLanguage(userLanguage) == detected.script) {
        // Same script as the user's language; without a real language-ID
        // model we do not guess that it is a different language, and we do
        // not call anything off-device to find out.
      } else {
        final result = await _translator.translate(
          displayText,
          sourceLanguage: detected.tag,
          targetLanguage: userLanguage,
        );
        switch (result.status) {
          case TranslationStatus.translated:
            displayText = result.translatedText!;
            translated = true;
            translatedFrom = detected.tag;
            translationModelVersion = result.modelVersion;
            badges.add(ModerationBadge.translated);

            // Criterion: when the classifier did not support the original
            // language, it may classify the translation instead, and the
            // result is labelled as a check of the translation. This is the
            // only classifier run that happens after translation, and it
            // exists because the original was unclassifiable, not because
            // order is flexible.
            if (classifierLanguageUnsupported) {
              stages.add(ModerationStage.classifier);
              final recheck = await _classifier.classify(
                displayText,
                languageTag: userLanguage,
                input: ClassifierInput.translation,
              );
              if (recheck.wasChecked) {
                classifierChecked = true;
                classifierScores = recheck.scores;
                classifierVersion = recheck.modelVersion;
                badges.remove(ModerationBadge.languageNotChecked);
                final flagged = recheck.flaggedLabels(_thresholds);
                if (flagged.isNotEmpty) {
                  hold(
                    sensitivity.revealSteps,
                    ModerationReason(
                      stage: ModerationStage.classifier,
                      code: ModerationReason.codeClassifierFlag,
                      label: flagged.first.id,
                    ),
                  );
                }
              }
            }
          case TranslationStatus.notNeeded:
            break;
          case TranslationStatus.modelUnavailable:
          case TranslationStatus.unsupportedPair:
            badges.add(ModerationBadge.translationUnavailable);
          case TranslationStatus.failed:
            badges.add(ModerationBadge.translationFailed);
        }
      }
    }

    stages.add(ModerationStage.render);

    return ModerationOutcome(
      messageId: decrypted.messageId,
      sensitivity: sensitivity,
      action: action,
      revealSteps: revealSteps,
      reasons: reasons,
      badges: badges,
      executedStages: stages,
      originalText: normalized.display,
      displayText: displayText,
      translated: translated,
      translatedFrom: translatedFrom,
      translationModelVersion: translationModelVersion,
      classifierChecked: classifierChecked,
      classifierScores: classifierScores,
      classifierModelVersion: classifierVersion,
    );
  }

  DetectedLanguage _detectLanguage(
    DecryptedMessage decrypted,
    NormalizedText normalized,
  ) {
    final hint = decrypted.languageHint;
    if (hint != null && hint.trim().isNotEmpty) {
      return DetectedLanguage(
        tag: hint.trim(),
        script: scriptOfLanguage(hint) ?? 'Zyyy',
        confidence: 1,
        method: DetectionMethod.hint,
      );
    }
    return _languageIdentifier.detect(normalized.display);
  }
}
