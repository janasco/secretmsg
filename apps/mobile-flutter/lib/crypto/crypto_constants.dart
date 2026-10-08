// NOT CRYPTOGRAPHICALLY REVIEWED. This code has not been reviewed by any
// cryptographer and no third party has audited the protocol it implements.
// Crypto bugs fail silently: a flaw here would not throw, it would simply
// fail to protect. Do not treat the existence of this file as evidence that
// SecretMsg messages are secure. See lib/crypto/README.md for the full list
// of unverified properties (protocol design, key-exchange authenticity,
// forward secrecy, replay resistance).
//
// Shared constants for the SecretMsg end-to-end message format.
//
// The envelope is the only thing the server ever stores for an encrypted
// message. It is transported inside the existing `content` / `reply_content`
// text columns, prefixed with [kEnvelopePrefix], so that legacy readers and
// the existing inbox route keep working without schema changes:
//
//   enc:v1:<base64url(no padding) of a JSON object>
//
// Message envelope JSON (recipient-bound):
//   {
//     "v": 1,
//     "alg": "A256GCM",
//     "iv": "<b64url, 12 bytes>",
//     "ct": "<b64url, ciphertext || 16-byte GCM tag>",
//     "wraps": [
//       {
//         "kid": "<device key id>",
//         "epk": "<b64url, 32-byte X25519 ephemeral public key>",
//         "iv":  "<b64url, 12 bytes>",
//         "ct":  "<b64url, wrapped 32-byte content key || 16-byte GCM tag>"
//       }
//     ]
//   }
//
// Reply envelope JSON (same content key as the original message, no wraps):
//   { "v": 1, "alg": "A256GCM", "iv": "...", "ct": "..." }
//
// Key schedule (v1):
//   content key K       = 32 random bytes, one per message
//   body                = AES-256-GCM(K, iv, plaintext, aad = "secretmsg-body-v1")
//   wrap shared secret  = X25519(ephemeral private, recipient device public)
//   wrap key            = HKDF-SHA256(shared, salt = "secretmsg-e2e-v1",
//                          info = "secretmsg-wrap-v1:" + kid), 32 bytes
//   wrapped key         = AES-256-GCM(wrap key, iv, K,
//                          aad = "secretmsg-wrap-v1:" + kid)
//
// The server can never derive K: it holds only the ephemeral public key and
// the AES-GCM ciphertext. A report disclosure is the one path where a client
// hands K to the server on purpose (see report_disclosure.dart).
library;

/// Prefix that marks a stored body as an end-to-end encrypted envelope.
const String kEnvelopePrefix = 'enc:v1:';

/// Version number written into new envelopes.
const int kEnvelopeVersion = 1;

/// AEAD algorithm name written into new envelopes. AES-256-GCM is chosen
/// because Cloudflare Workers' WebCrypto can decrypt it for opt-in report
/// verification without shipping a third-party cipher to the Worker.
const String kEnvelopeAlg = 'A256GCM';

/// AES-GCM nonce length, in bytes.
const int kNonceLength = 12;

/// AES-GCM authentication tag length, in bytes.
const int kTagLength = 16;

/// Length of a content key / wrap key, in bytes (AES-256).
const int kContentKeyLength = 32;

/// Length of an X25519 private key, public key, and shared secret, in bytes.
const int kX25519KeyLength = 32;

/// HKDF salt for wrap-key derivation. Constant is fine: the input keying
/// material (the X25519 shared secret) is already unique per (ephemeral key,
/// recipient key) pair.
const String kWrapSalt = 'secretmsg-e2e-v1';

/// HKDF info prefix and AES-GCM AAD for wrap-key derivation. Binding the
/// device key id stops a wrap from being transplanted onto a different
/// recipient device entry.
const String kWrapInfoPrefix = 'secretmsg-wrap-v1:';

/// AES-GCM AAD for the message body.
const String kBodyAad = 'secretmsg-body-v1';

/// Maximum accepted envelope size, in characters. A 500-character message is
/// ~700 bytes of ciphertext, so this is generous while still bounding abuse.
const int kMaxEnvelopeLength = 16384;

/// Maximum number of recipient device wraps accepted in one envelope.
const int kMaxWraps = 8;

/// Maximum push-preview length, matching the server's historical truncation
/// (api/src/fcm.ts). The preview is generated on the sending device now; the
/// server no longer derives it from the body because it cannot read the body.
const int kPushPreviewLength = 140;

/// Human-readable marker used by clients to tell the user, in plain words,
/// that this build's encryption has not been independently reviewed.
const String kUnreviewedCryptoNotice =
    'End-to-end encryption in this build has not been independently '
    'reviewed. Treat it as an extra layer, not as a guarantee.';
