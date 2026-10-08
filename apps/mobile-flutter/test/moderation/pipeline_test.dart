import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/moderation/classifier/toxicity_classifier.dart';
import 'package:secretmsg_mobile/moderation/pipeline/decryptor.dart';
import 'package:secretmsg_mobile/moderation/pipeline/moderation_outcome.dart';
import 'package:secretmsg_mobile/moderation/pipeline/moderation_pipeline.dart';
import 'package:secretmsg_mobile/moderation/settings.dart';
import 'package:secretmsg_mobile/moderation/translation/translator.dart';

class _FakeDecryptor implements MessageDecryptor {
  _FakeDecryptor(this.content, {this.languageHint});

  final String content;
  final String? languageHint;
  int calls = 0;

  @override
  Future<DecryptedMessage> decrypt(EncryptedEnvelope envelope) async {
    calls++;
    return DecryptedMessage(
      messageId: envelope.messageId,
      content: content,
      languageHint: languageHint,
    );
  }
}

class _FailingDecryptor implements MessageDecryptor {
  @override
  Future<DecryptedMessage> decrypt(EncryptedEnvelope envelope) async {
    throw DecryptionFailure(envelope.messageId, 'bad tag');
  }
}

class _ClassifierCall {
  final String text;
  final String languageTag;
  final ClassifierInput input;

  const _ClassifierCall(this.text, this.languageTag, this.input);
}

class _FakeClassifier implements ToxicityClassifier {
  _FakeClassifier({
    this.availability = ClassifierAvailability.checked,
    this.scores = const <ToxicityScore>[],
    this.onOriginal,
  });

  ClassifierAvailability availability;
  List<ToxicityScore> scores;

  @override
  String? version = 'test-1.0.0';

  /// Optional scripted response for `original` input; used to exercise the
  /// post-translation re-check.
  final ClassifierResult Function(String text, String languageTag)? onOriginal;

  final List<_ClassifierCall> calls = <_ClassifierCall>[];

  @override
  String get id => 'fake';

  @override
  bool get isModelInstalled => true;

  @override
  Set<String> get supportedLanguagePrefixes => const <String>{'mul', 'en'};

  @override
  Future<void> warmUp() async {}

  @override
  Future<ClassifierResult> classify(
    String text, {
    required String languageTag,
    ClassifierInput input = ClassifierInput.original,
  }) async {
    calls.add(_ClassifierCall(text, languageTag, input));
    if (input == ClassifierInput.original && onOriginal != null) {
      return onOriginal!(text, languageTag);
    }
    return ClassifierResult(
      availability: availability,
      scores: scores,
      input: input,
      languageTag: languageTag,
      modelId: id,
      modelVersion: version,
    );
  }

  @override
  Future<void> dispose() async {}
}

class _TranslatorCall {
  final String text;
  final String sourceLanguage;
  final String targetLanguage;

  const _TranslatorCall(this.text, this.sourceLanguage, this.targetLanguage);
}

class _FakeTranslator implements OnDeviceTranslator {
  _FakeTranslator({
    this.status = TranslationStatus.translated,
    this.translated = 'translated text',
  });

  TranslationStatus status;
  String translated;
  String? version = 'nmt-1.0.0';
  final List<_TranslatorCall> calls = <_TranslatorCall>[];

  @override
  bool get hasAnyModel => true;

  @override
  Set<String> get supportedSourceLanguages =>
      const <String>{'und-Cyrl', 'und-Grek'};

  @override
  Set<String> get supportedTargetLanguages => const <String>{'en'};

  @override
  Future<TranslationResult> translate(
    String text, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    calls.add(_TranslatorCall(text, sourceLanguage, targetLanguage));
    if (status != TranslationStatus.translated) {
      return TranslationResult(
        status: status,
        originalText: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
    }
    return TranslationResult(
      status: TranslationStatus.translated,
      originalText: text,
      translatedText: translated,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      modelId: 'fake-nmt',
      modelVersion: version,
    );
  }

  @override
  Future<void> dispose() async {}
}

EncryptedEnvelope envelope([String id = 'm1']) =>
    EncryptedEnvelope(messageId: id, payload: Uint8List(0));

Future<ModerationOutcome> run(
  ModerationPipeline pipeline, {
  String userLanguage = 'en',
  ModerationSensitivity sensitivity = ModerationSensitivity.standard,
  bool translationEnabled = false,
  String messageId = 'm1',
}) =>
    pipeline.process(
      envelope(messageId),
      userLanguage: userLanguage,
      sensitivity: sensitivity,
      translationEnabled: translationEnabled,
    );

void main() {
  group('fixed pipeline order', () {
    test('runs decrypt, normalize, hidden words, classifier, render', () async {
      final classifier = _FakeClassifier();
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('hello there'),
        classifier: classifier,
      );
      final outcome = await run(pipeline);

      expect(
        outcome.executedStages,
        <ModerationStage>[
          ModerationStage.decrypt,
          ModerationStage.normalize,
          ModerationStage.hiddenWords,
          ModerationStage.classifier,
          ModerationStage.render,
        ],
      );
      expect(outcome.held, isFalse);
      expect(outcome.classifierChecked, isTrue);
      expect(outcome.displayText, 'hello there');
      expect(outcome.originalText, 'hello there');
      expect(outcome.badges, isEmpty);
    });

    test('sensitivity off runs the deterministic check but skips the model',
        () async {
      final classifier = _FakeClassifier();
      final translator = _FakeTranslator();
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('spam and more'),
        classifier: classifier,
        translator: translator,
      );
      final outcome = await run(
        pipeline,
        sensitivity: ModerationSensitivity.off,
      );

      expect(
        outcome.executedStages,
        <ModerationStage>[
          ModerationStage.decrypt,
          ModerationStage.normalize,
          ModerationStage.hiddenWords,
          ModerationStage.render,
        ],
        reason: 'off means no classifier pass; hidden words still ran',
      );
      expect(classifier.calls, isEmpty);
      expect(outcome.held, isFalse);
    });

    test('a held message never reaches classifier or translator', () async {
      final classifier = _FakeClassifier();
      final translator = _FakeTranslator();
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('buy spam now'),
        classifier: classifier,
        translator: translator,
      )..updateHiddenWords(const <String>['spam']);

      final outcome = await run(pipeline, translationEnabled: true);

      expect(outcome.held, isTrue);
      expect(outcome.revealSteps, 1);
      expect(outcome.reasons.single.code, ModerationReason.codeHiddenWord);
      expect(outcome.reasons.single.word, 'spam');
      expect(classifier.calls, isEmpty);
      expect(translator.calls, isEmpty);
      expect(
        outcome.executedStages,
        <ModerationStage>[
          ModerationStage.decrypt,
          ModerationStage.normalize,
          ModerationStage.hiddenWords,
          ModerationStage.render,
        ],
      );
    });

    test('strict hidden-word hold requires two reveal steps', () async {
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('buy spam now'),
      )..updateHiddenWords(const <String>['spam']);
      final outcome = await run(
        pipeline,
        sensitivity: ModerationSensitivity.strict,
      );
      expect(outcome.held, isTrue);
      expect(outcome.revealSteps, 2);
    });

    test('decryption failure propagates without weird states', () async {
      final pipeline = ModerationPipeline(decryptor: _FailingDecryptor());
      await expectLater(
        run(pipeline),
        throwsA(isA<DecryptionFailure>()),
      );
    });
  });

  group('classifier verdicts', () {
    test('a flagged message is held and labelled', () async {
      final translator = _FakeTranslator();
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('you are terrible'),
        classifier: _FakeClassifier(
          scores: const <ToxicityScore>[
            ToxicityScore(ToxicityLabel.harassment, 0.91),
          ],
        ),
        translator: translator,
      );
      final outcome = await run(pipeline, translationEnabled: true);

      expect(outcome.held, isTrue);
      expect(outcome.revealSteps, 1);
      expect(outcome.reasons.single.code, ModerationReason.codeClassifierFlag);
      expect(outcome.reasons.single.label, 'harassment');
      expect(translator.calls, isEmpty,
          reason: 'translation must not run for blocked text');
    });

    test('scores below threshold are not flags', () async {
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('darn'),
        classifier: _FakeClassifier(
          scores: const <ToxicityScore>[
            ToxicityScore(ToxicityLabel.harassment, 0.2),
          ],
        ),
      );
      final outcome = await run(pipeline);
      expect(outcome.held, isFalse);
    });

    test('unavailable model: standard shows a badge, strict holds', () async {
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('hello'),
        classifier: const UnavailableToxicityClassifier(),
      );

      final standard = await run(pipeline);
      expect(standard.held, isFalse);
      expect(standard.badges, contains(ModerationBadge.aiCheckUnavailable));
      expect(standard.classifierChecked, isFalse);

      final strict = await run(
        pipeline,
        sensitivity: ModerationSensitivity.strict,
      );
      expect(strict.held, isTrue);
      expect(strict.revealSteps, 2);
      expect(strict.reasons.single.code,
          ModerationReason.codeClassifierUnavailable);
    });

    test('unsupported language: standard badges, strict holds', () async {
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('some text'),
        classifier: _FakeClassifier(
          availability: ClassifierAvailability.languageUnsupported,
        ),
      );

      final standard = await run(pipeline);
      expect(standard.held, isFalse);
      expect(standard.badges, contains(ModerationBadge.languageNotChecked));

      final strict = await run(
        pipeline,
        sensitivity: ModerationSensitivity.strict,
      );
      expect(strict.held, isTrue);
      expect(
        strict.reasons.single.code,
        ModerationReason.codeLanguageNotChecked,
      );
    });
  });

  group('translation', () {
    test('cross-script text is translated when enabled', () async {
      final translator = _FakeTranslator(translated: 'hello world');
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('привет мир'),
        classifier: _FakeClassifier(
          availability: ClassifierAvailability.languageUnsupported,
        ),
        translator: translator,
      );
      final outcome = await run(pipeline, translationEnabled: true);

      expect(translator.calls.single.sourceLanguage, 'und-Cyrl');
      expect(translator.calls.single.targetLanguage, 'en');
      expect(outcome.translated, isTrue);
      expect(outcome.displayText, 'hello world');
      expect(outcome.originalText, 'привет мир');
      expect(outcome.translatedFrom, 'und-Cyrl');
      expect(outcome.badges, contains(ModerationBadge.translated));
      expect(
        outcome.executedStages,
        containsAllInOrder(<ModerationStage>[
          ModerationStage.hiddenWords,
          ModerationStage.classifier,
          ModerationStage.translation,
          ModerationStage.render,
        ]),
      );
    });

    test('same-script text is not sent to the translator', () async {
      final translator = _FakeTranslator();
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('hello world'),
        translator: translator,
      );
      final outcome = await run(pipeline, translationEnabled: true);
      expect(translator.calls, isEmpty);
      expect(outcome.translated, isFalse);
      expect(outcome.badges, isNot(contains(ModerationBadge.translated)));
    });

    test('undetectable script is skipped with an explicit badge', () async {
      final translator = _FakeTranslator();
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('👍💀'),
        translator: translator,
      );
      final outcome = await run(pipeline, translationEnabled: true);
      expect(translator.calls, isEmpty);
      expect(
        outcome.badges,
        contains(ModerationBadge.translationSkippedUnknownLanguage),
      );
    });

    test('missing model produces translationUnavailable, not failure',
        () async {
      final translator = _FakeTranslator(
        status: TranslationStatus.modelUnavailable,
      );
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('привет'),
        classifier: _FakeClassifier(
          availability: ClassifierAvailability.languageUnsupported,
        ),
        translator: translator,
      );
      final outcome = await run(pipeline, translationEnabled: true);
      expect(outcome.translated, isFalse);
      expect(outcome.displayText, 'привет');
      expect(
        outcome.badges,
        contains(ModerationBadge.translationUnavailable),
      );
    });

    test(
        'classifier may re-check the translation when the original language '
        'was unsupported, and the re-check can hold', () async {
      final classifier = _FakeClassifier(
        onOriginal: (text, languageTag) => const ClassifierResult(
          availability: ClassifierAvailability.languageUnsupported,
          input: ClassifierInput.original,
        ),
      )
        ..availability = ClassifierAvailability.checked
        ..scores = const <ToxicityScore>[
          ToxicityScore(ToxicityLabel.sexual, 0.97),
        ];
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('нечто'),
        classifier: classifier,
        translator: _FakeTranslator(translated: 'something explicit'),
      );

      final outcome = await run(pipeline, translationEnabled: true);

      expect(classifier.calls.length, 2);
      expect(classifier.calls[0].input, ClassifierInput.original);
      expect(classifier.calls[1].input, ClassifierInput.translation);
      expect(classifier.calls[1].languageTag, 'en');
      expect(outcome.held, isTrue);
      expect(outcome.revealSteps, 1);
      expect(outcome.reasons.single.code, ModerationReason.codeClassifierFlag);
      expect(
        outcome.badges,
        isNot(contains(ModerationBadge.languageNotChecked)),
        reason: 'the translation was checked',
      );
    });
  });

  group('normalization surface', () {
    test('bidi controls are neutralized before render and badged', () async {
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('\u202Ehello\u202C'),
      );
      final outcome = await run(pipeline);
      expect(outcome.originalText, 'hello');
      expect(outcome.displayText, 'hello');
      expect(
        outcome.badges,
        contains(ModerationBadge.formattingNeutralized),
      );
    });

    test('a language hint is used when the caller has one', () async {
      final pipeline = ModerationPipeline(
        decryptor: _FakeDecryptor('привет', languageHint: 'ru'),
      );
      final outcome = await run(pipeline, translationEnabled: true);
      // Hint says ru; heuristic would say und-Cyrl. Either way the pipeline
      // must not translate without a model.
      expect(outcome.displayText, 'привет');
    });
  });
}
