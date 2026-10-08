import 'package:flutter_test/flutter_test.dart';
import 'package:secretmsg_mobile/moderation/translation/language_id.dart';
import 'package:secretmsg_mobile/moderation/translation/translator.dart';

void main() {
  const identifier = ScriptHeuristicLanguageIdentifier();

  group('ScriptHeuristicLanguageIdentifier', () {
    test('detects the dominant script', () {
      expect(identifier.detect('hello world').tag, 'und-Latn');
      expect(identifier.detect('привет мир').tag, 'und-Cyrl');
      expect(identifier.detect('日本語です').script, 'Hani');
      expect(identifier.detect('こんにちは').script, 'Hira');
      expect(identifier.detect('مرحبا').script, 'Arab');
    });

    test('reports unknown for mixed or letterless text', () {
      expect(identifier.detect('').isUnknown, isTrue);
      expect(identifier.detect('👍💀').isUnknown, isTrue);
      expect(identifier.detect('hello привет').isUnknown, isTrue,
          reason: 'no dominant script at ~50/50');
    });

    test('confidence is the dominant-script share', () {
      final result = identifier.detect('abcdefghij при');
      expect(result.script, 'Latn');
      expect(result.confidence, closeTo(10 / 13, 0.0001));
    });
  });

  group('scriptOfLanguage', () {
    test('maps common languages to scripts', () {
      expect(scriptOfLanguage('en-US'), 'Latn');
      expect(scriptOfLanguage('de'), 'Latn');
      expect(scriptOfLanguage('ru'), 'Cyrl');
      expect(scriptOfLanguage('el'), 'Grek');
      expect(scriptOfLanguage('ar'), 'Arab');
      expect(scriptOfLanguage('ja-JP'), 'Hira');
      expect(scriptOfLanguage('ko'), 'Hang');
      expect(scriptOfLanguage('zh-CN'), 'Hani');
    });

    test('returns null for unknown or absent languages', () {
      expect(scriptOfLanguage('xx'), isNull);
      expect(scriptOfLanguage(null), isNull);
      expect(scriptOfLanguage('  '), isNull);
    });
  });

  group('UnavailableTranslator', () {
    test('is honest: no model, original returned unchanged', () async {
      const translator = UnavailableTranslator();
      expect(translator.hasAnyModel, isFalse);
      expect(translator.supportedSourceLanguages, isEmpty);
      expect(translator.supportedTargetLanguages, isEmpty);

      final result = await translator.translate(
        'привет',
        sourceLanguage: 'und-Cyrl',
        targetLanguage: 'en',
      );
      expect(result.status, TranslationStatus.modelUnavailable);
      expect(result.didTranslate, isFalse);
      expect(result.originalText, 'привет');
      expect(result.translatedText, isNull);
    });

    test('dispose is safe to call', () async {
      const translator = UnavailableTranslator();
      await translator.dispose();
    });
  });
}
