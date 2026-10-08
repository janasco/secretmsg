// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Filtered Words, moved to the sending client.
//
// Before end-to-end encryption the server read every body and enforced the
// recipient's hidden-word list (api/src/index.ts, the `sensitivity` block).
// Once the body is encrypted the server cannot run that check, so the sending
// client fetches the recipient's filter manifest from the API and applies the
// exact same normalization locally, before encryption.
//
// Honesty about what that means:
//   * A stock client still quarantines (standard) or refuses (strict) matches,
//     and reports the match to the server as an advisory flag so the filtered
//     tray still works.
//   * A modified client can simply omit the flag. Client-side enforcement is
//     weaker than server-side enforcement was. The recipient's ability to
//     review the filtered tray is preserved; the guarantee that nothing
//     matching ever reaches the tray is not.
//   * The recipient's word list is fetched by the sender's client, so the
//     list is no longer private from senders. This is a deliberate trade:
//     encrypting bodies and filtering by a secret list are mutually
//     exclusive without private-set-intersection machinery that this build
//     does not implement.
library;

/// Result of evaluating a body against one recipient's filter manifest.
class FilterDecision {
  /// Whether the (normalized) body contains a (normalized) hidden word.
  final bool matched;

  /// The mode the recipient configured: 'off', 'standard', or 'strict'.
  final String mode;

  const FilterDecision({required this.matched, required this.mode});

  /// Strict mode refuses the send in the original implementation. The sending
  /// client reproduces that refusal locally.
  bool get shouldReject => matched && mode == 'strict';

  /// Standard and strict mode both store the row quarantined for the
  /// recipient's filtered tray.
  bool get shouldQuarantine => matched && (mode == 'standard' || mode == 'strict');

  /// No check applies when the recipient turned filtering off.
  bool get shouldSend => !shouldReject;
}

class FilteredWords {
  FilteredWords._();

  /// Evaluates [content] against [words] under [mode].
  ///
  /// Normalization mirrors the server implementation exactly:
  ///   standard: lowercase only
  ///   strict:   lowercase, then keep only [a-z0-9 ] (ASCII)
  /// The server compared whole-body containment, not word boundaries; so does
  /// this.
  static FilterDecision evaluate({
    required String content,
    required String mode,
    required List<String> words,
  }) {
    final normalizedMode = mode == 'strict' ? 'strict' : (mode == 'off' ? 'off' : 'standard');
    if (normalizedMode == 'off' || words.isEmpty) {
      return FilterDecision(matched: false, mode: normalizedMode);
    }
    final haystack = normalize(content, mode: normalizedMode);
    final matched = words.any((word) {
      if (word.isEmpty) return false;
      return haystack.contains(normalize(word, mode: normalizedMode));
    });
    return FilterDecision(matched: matched, mode: normalizedMode);
  }

  /// The exact normalization used by the server at api/src/index.ts:341.
  static String normalize(String input, {required String mode}) {
    if (mode == 'strict') {
      return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    }
    return input.toLowerCase();
  }
}
