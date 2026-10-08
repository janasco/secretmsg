/// Auto-translation seam.
///
/// Hard rule, stated in the product copy and in the docs: no network
/// translation API may ever receive message text. Message bodies are
/// end-to-end encrypted, and sending plaintext to a third-party translation
/// service would defeat that promise. Translation therefore happens only on
/// device, only after decryption, and only from locally installed model packs
/// delivered as signed bundles.
///
/// What is achievable and what is not (restated from
/// `docs/on-device-moderation.md`):
/// * Achievable: per-language pair NMT models of roughly 30-90 MB (int8) that
///   translate short common-language messages on a mid-range device within a
///   sub-second budget, once downloaded and installed.
/// * Not achievable here: universal coverage. Model packs are per language
///   pair; low-resource languages will not be available at launch, and
///   same-script language identification needs its own model. Until a pack is
///   installed, the honest answer is "translation unavailable", never a
///   silent call to a server.
enum TranslationStatus {
  /// Text was translated on device.
  translated,

  /// No translation was needed (same language/script or empty text).
  notNeeded,

  /// No suitable model pack is installed.
  modelUnavailable,

  /// The installed packs do not cover this language pair.
  unsupportedPair,

  /// The model ran and failed; the original is returned unchanged.
  failed,
}

class TranslationResult {
  final TranslationStatus status;
  final String originalText;
  final String? translatedText;
  final String? sourceLanguage;
  final String? targetLanguage;
  final String? modelId;
  final String? modelVersion;

  /// Content-free failure reason for logs; never includes message text.
  final String? failureDetail;

  const TranslationResult({
    required this.status,
    required this.originalText,
    this.translatedText,
    this.sourceLanguage,
    this.targetLanguage,
    this.modelId,
    this.modelVersion,
    this.failureDetail,
  });

  bool get didTranslate =>
      status == TranslationStatus.translated && translatedText != null;
}

/// Metadata for one downloadable translation pack, used by the download UI
/// before anything is fetched. Size is shown up front; downloads prefer Wi-Fi
/// and are resumable in the production implementation.
class TranslationPack {
  final String id;
  final String sourceLanguage;
  final String targetLanguage;
  final int downloadBytes;
  final String version;

  const TranslationPack({
    required this.id,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.downloadBytes,
    required this.version,
  });
}

abstract interface class OnDeviceTranslator {
  /// Primary language prefixes with an installed source side.
  Set<String> get supportedSourceLanguages;

  /// Primary language prefixes with an installed target side.
  Set<String> get supportedTargetLanguages;

  bool get hasAnyModel;

  Future<TranslationResult> translate(
    String text, {
    required String sourceLanguage,
    required String targetLanguage,
  });

  Future<void> dispose();
}

/// Shipped default until signed translation packs are installed. Returns
/// [TranslationStatus.modelUnavailable] and the original text, so the UI can
/// show "translation unavailable" distinctly from a translation failure.
class UnavailableTranslator implements OnDeviceTranslator {
  const UnavailableTranslator();

  @override
  Set<String> get supportedSourceLanguages => const <String>{};

  @override
  Set<String> get supportedTargetLanguages => const <String>{};

  @override
  bool get hasAnyModel => false;

  @override
  Future<TranslationResult> translate(
    String text, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async =>
      TranslationResult(
        status: TranslationStatus.modelUnavailable,
        originalText: text,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );

  @override
  Future<void> dispose() async {}
}
