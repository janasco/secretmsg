/// On-device moderation and auto-translation for SecretMsg.
///
/// Message bodies are end-to-end encrypted; the server cannot read them.
/// Everything in this library runs on the recipient's device, after envelope
/// verification and decryption, against plaintext:
///
/// ```
/// decrypt -> normalize -> deterministic hidden-words -> classifier
///         -> translation -> render
/// ```
///
/// Hard limits, stated plainly:
/// * Client-side filtering is bypassable by a modified client. It is weaker
///   than the server-side enforcement it replaces; it protects the ordinary
///   user, it is not an enforcement boundary.
/// * No trained classifier or translation weights ship in this change. The
///   default classifier reports "not checked" and the default translator
///   reports "unavailable"; deterministic hidden-word matching is the only
///   fully working moderation stage here.
/// * Nothing in this library sends message text, translations or labels to
///   any network service. Model downloads are signed assets with no user data.
///
/// See `docs/on-device-moderation.md` for the design, budgets and the
/// operational checklist.
library;

export 'classifier/toxicity_classifier.dart';
export 'crypto/p256_ecdsa.dart';
export 'crypto/sha256.dart';
export 'delivery/bundle_source.dart';
export 'delivery/bundle_store.dart';
export 'delivery/bundle_verifier.dart';
export 'delivery/model_manifest.dart';
export 'delivery/rollout_policy.dart';
export 'pipeline/decryptor.dart';
export 'pipeline/moderation_outcome.dart';
export 'pipeline/moderation_pipeline.dart';
export 'settings.dart';
export 'text/confusables.dart';
export 'text/hidden_words.dart';
export 'text/text_normalizer.dart';
export 'translation/language_id.dart';
export 'translation/translator.dart';
export 'user_copy.dart';
