/// User-facing copy for moderation surfaces.
///
/// Every string here is written to be literally true on a device where the
/// pipeline is not wired yet and no classifier/translation model ships:
/// nothing may claim a message was checked clean when no model ran, and the
/// on-device, bypassable nature of client-side filtering is stated in the
/// privacy-relevant places rather than buried.
library;

class ModerationCopy {
  const ModerationCopy._();

  // --- Hold reasons -------------------------------------------------------

  static const String holdHiddenWord =
      'Held: matches a word you filter on this device';

  static const String holdClassifierFlag =
      'Held: possible harmful content (on-device check)';

  static const String holdClassifierUnavailable =
      'Held: this device has no AI content check installed yet';

  static const String holdLanguageNotChecked =
      'Held: not checked for this language';

  // --- Badges -------------------------------------------------------------

  static const String badgeAiCheckUnavailable =
      'AI check unavailable on this device';

  static const String badgeLanguageNotChecked =
      'Not checked for this language';

  static const String badgeTranslationUnavailable =
      'Translation unavailable: no language pack installed';

  static const String badgeTranslationSkippedUnknownLanguage =
      'Language not identified, so this message was not translated';

  static const String badgeTranslationFailed =
      'Translation failed; showing the original';

  static const String badgeTranslated = 'Translated on this device';

  static const String badgeFormattingNeutralized =
      'Hidden formatting was removed';

  // --- Reveal and translation controls -------------------------------------

  static const String revealStandard = 'Show anyway';
  static const String revealStrictFirstStep = 'Show anyway';
  static const String revealStrictConfirm = 'Reveal anyway';
  static const String showOriginal = 'Show original';
  static const String showTranslation = 'Show translation';

  // --- Honesty footer ------------------------------------------------------
  //
  // These two lines are the ones the privacy/disclosure surfaces must show
  // wherever on-device moderation is described.

  static const String bypassNotice =
      'Filtering and translation run on this device, after your message '
      'decrypts. A modified app could skip them, so this is a protection for '
      'you, not an enforcement boundary.';

  static const String probabilisticNotice =
      'On-device checks are probabilistic and do not catch everything, and '
      'not every language can be checked or translated.';
}
