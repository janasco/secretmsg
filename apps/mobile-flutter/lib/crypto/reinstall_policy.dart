// NOT CRYPTOGRAPHICALLY REVIEWED. See lib/crypto/README.md and the header of
// crypto_constants.dart. Crypto bugs fail silently.
//
// Reinstall behaviour and the copy that tells the truth about it.
//
// History is encrypted to the per-install device key. There is no key escrow:
// the server never receives the private key, so it cannot help a reinstalled
// app decrypt old messages even if it wanted to. The honest behaviour is:
//
//   * After a reinstall (secure-storage wipe, app data clear, new device):
//     the device key is gone. Envelopes wrapped to the old key are
//     cryptographically unreadable on the new install, permanently.
//   * The app does not show a lock or a spinner forever; it labels those
//     messages as no longer readable on this device and keeps the metadata
//     (sender hint, timestamp, quarantined state) visible.
//   * New messages sent after the new key is registered are readable again.
//   * Account recovery (backup codes) recovers the *account*, not the keys.
//     That is a deliberate product decision, not an oversight.
//
// We could "fix" this with key escrow. Escrow means the operator holds a copy
// of (or a path to) the keys, which converts end-to-end encryption into
// "encrypted except for us" — a backdoor by another name. This build does not
// implement escrow and must never claim recoverable history.
library;

import 'crypto_constants.dart';

/// Where a message's readability stands on this device.
enum HistoryReadability {
  /// Decrypted and shown normally.
  readable,

  /// Legacy pre-encryption row, shown as plaintext with a clear label.
  legacyPlaintext,

  /// Encrypted to a device key this install no longer has. Not recoverable.
  unreadableAfterReinstallKeyLoss,

  /// Encrypted, key present, but authentication failed (tampered or corrupt).
  decryptionFailed,
}

class ReinstallPolicy {
  ReinstallPolicy._();

  /// There is no escrow and there will not be one silently.
  static const bool keyEscrowEnabled = false;

  /// Inbox banner headline when [DeviceKeyStore.load] returns null but the
  /// inbox contains encrypted rows.
  static const String keyLossHeadline = 'Encrypted history is not available';

  /// Inbox banner body. Names the cause, the scope, and the non-solution.
  static const String keyLossBody =
      'Messages sent to this app installation were encrypted to a key that '
      'was stored only on this device. After a reinstall, a new device, or '
      'clearing app data, that key is gone and those messages cannot be '
      'recovered — by us or by anyone. New messages will be readable again. '
      'We do not keep a copy of your keys: a copy would mean the service '
      'could read every message, which is the exact thing this protects '
      'against.';

  /// One-line label for a single unreadable row.
  static const String unreadableRowLabel = 'Not readable on this device';

  /// One-line label for a legacy row that predates encryption.
  static const String legacyRowLabel = 'Legacy message (not end-to-end encrypted)';

  /// Shown in settings next to "reinstall / new device".
  static const String settingsNote =
      'Your keys live only on this device. Reinstalling or moving to a new '
      'device starts a fresh key and old encrypted messages stay unreadable. '
      'Account recovery codes restore the account, not the message keys.';

  /// Bullets for a help/FAQ screen.
  static const List<String> explainerBullets = <String>[
    'Message text is encrypted on the sender\'s device and decrypted on yours.',
    'The decryption key for this installation never reaches the server.',
    'A reinstall generates a new key. Old encrypted messages cannot be read again.',
    'Account backup codes restore your login, not your message keys.',
    'There is no key escrow. Escrow would give the service a way to read messages.',
  ];

  /// Copy for the confirmation shown when someone asks us to "restore my
  /// messages" — there is no such action and the UI must not pretend there is.
  static const String noRecoveryAction =
      'We cannot restore encrypted messages to a reinstalled app. There is '
      'no recovery action that can do this.';

  /// The one-sentence version used under a message that failed to decrypt.
  static String explanation(HistoryReadability state) {
    switch (state) {
      case HistoryReadability.readable:
        return 'Decrypted on this device.';
      case HistoryReadability.legacyPlaintext:
        return 'Sent before end-to-end encryption existed. It was stored '
            'without encryption and is shown as-is.';
      case HistoryReadability.unreadableAfterReinstallKeyLoss:
        return 'This message was encrypted to a key that is no longer on '
            'this device. It cannot be recovered.$kUnreviewedCryptoNotice';
      case HistoryReadability.decryptionFailed:
        return 'This message could not be authenticated and may be damaged '
            'or altered. It has not been shown.';
    }
  }
}
