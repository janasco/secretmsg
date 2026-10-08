# SecretMsg end-to-end message encryption (client library)

> **NOT CRYPTOGRAPHICALLY REVIEWED.** No cryptographer and no third party has
> reviewed this design or this code. Crypto bugs fail silently: nothing here
> throws when the security property is weaker than the documentation claims.
> Do not read this directory as evidence that messages are secure.
>
> **Unverified properties, stated explicitly:**
>
> - The protocol design below has not been reviewed. It is not HPKE or any
>   other standardized construction; it is bespoke, and bespoke constructions
>   are where mistakes live.
> - Key-exchange authenticity: a sender encrypts to the recipient's public key
>   as served by the SecretMsg API. There is no key transparency, no safety
>   number, and no out-of-band verification. **A malicious or compromised
>   server can substitute its own public key and read messages as they are
>   sent.** This is not protection against a malicious server at send time.
> - Forward secrecy: there is none. The per-message content key is wrapped to
>   the device's long-lived X25519 key, not to an ephemeral ratchet. If the
>   device private key is compromised later, stored envelopes can be decrypted.
> - Replay resistance: there is none beyond the existing client-generated
>   `client_msg_id` dedup window. A malicious server can re-present an old
>   envelope.
> - Sender authentication and deniability: the envelope is anonymous by
>   construction. The recipient learns nothing cryptographically about who
>   sent it (the legacy device fingerprint remains opt-in metadata).
> - Nonce/IV handling for AES-GCM: 96-bit random nonces from the platform
>   CSPRNG, one key per message. This is standard usage but relies on the
>   platform RNG.

## What this is

Message bodies are encrypted on the sender's device and decrypted on the
recipient's device. The server stores ciphertext plus metadata (timestamp,
size, recipient, delivery state) and can no longer read bodies. Moderation
splits accordingly:

- the **sender's device** filters plaintext before encryption,
- the **recipient's device** reads plaintext and can opt in to hand a
  per-message key to moderators for a report,
- the **server** moderates on metadata and on plaintext that a user
  deliberately discloses.

## Library

The only cryptographic dependency is
[`cryptography`](https://pub.dev/packages/cryptography) (2.9.x), a published,
pure-Dart package. It is used for X25519 key agreement, HKDF-SHA256, and
AES-256-GCM. It has no native plugin and no Google Play Services dependency, so
the de-Googled sideload track keeps working; bodies are ≤ 500 characters, so
software performance is a non-issue. No primitive is implemented by hand here.

Forms of the envelope and the key schedule: see `crypto_constants.dart`.

## Files

| File | Purpose |
| --- | --- |
| `crypto_constants.dart` | Format constants, prefix, limits, review notice. |
| `crypto_encoding.dart` | Unpadded base64url + constant-time compare. |
| `message_crypto.dart` | Body/reply AEAD, X25519 key wrap, envelope codec. |
| `device_key_store.dart` | Per-install X25519 keypair in secure storage. |
| `claim_link.dart` | `#k=` fragment key transport (never query/path). |
| `filtered_words.dart` | Client-side hidden-word check (consequence 1). |
| `push_preview.dart` | Device-generated 140-char preview (consequence 2). |
| `report_disclosure.dart` | Opt-in per-message key handover (consequence 3). |
| `reinstall_policy.dart` | Honest key-loss behaviour + copy (consequence 4). |
| `crypto_service.dart` | Orchestration; injected transport. |
| `crypto_api.dart` | HTTP client for the routes in `api/src/crypto.ts`. |

## The four consequences of the server losing plaintext

1. **Filtered Words** now run on the sending client, before encryption. The
   client fetches the recipient's filter manifest from
   `GET /api/crypto/pubkey/:username` and mirrors the server's normalization.
   Strict hits are refused locally; standard hits are stored quarantined using
   a client-reported `filter_match` flag. **Honest caveat:** the flag is
   advisory, so a modified client can bypass the recipient's filter. The
   server-side enforcement that existed before 1.8 cannot survive E2E.
2. **Push previews** are generated on the sending device
   (`PushPreview.fromContent`, still capped at 140 characters with `…`) and
   sent to the API as a separate field. The preview remains visible to the
   server and to Google's push infrastructure; it is content the sender chose
   to surface. The full body never travels through FCM.
3. **Report review** is opt-in per report. The reporter's client re-decrypts
   the stored envelope locally, then sends the content key to
   `POST /api/crypto/report`. The server decrypts the stored ciphertext and
   stores plaintext only if AES-GCM authentication succeeds
   (`report_disclosures`). Decline and the report is still filed, reviewed on
   metadata only. **Honest caveat:** once disclosed, the plaintext is visible
   to whoever reviews reports and is subject to the normal retention rules.
4. **Reinstall** loses history. There is no escrow and no key backup: the
   private key never leaves the device. A reinstall generates a new key; old
   envelopes are permanently unreadable on the new install. The app labels
   those rows instead of pretending; account recovery codes restore the
   account, not the keys. Copy lives in `reinstall_policy.dart`.
   **Honest caveat:** escrow is what would "fix" this, and escrow is a
   backdoor; this build deliberately does not implement it.

## Migration for pre-1.8 plaintext messages

Existing rows keep their plaintext in `messages.content`. The prefix
`enc:v1:` distinguishes envelopes from legacy text. Clients must:

- render legacy rows as plaintext, labelled `Legacy message (not end-to-end
  encrypted)`;
- never rewrite or retroactively "encrypt" them (the server already saw the
  plaintext; a rewrite would only add a false claim);
- keep them readable forever unless the user deletes them.

Details and the SQL migration: `secretmsg-private/api/migration-e2e.sql` and
`secretmsg-private/api/src/CRYPTO-WIRING.md`.

## Claim-link key transport

A blind-reply thread runs under the same content key as the original message.
The sender keeps that key locally against the reply token and shares
`https://secretmsg.net/reply/<token>#k=<key>`; browsers do not transmit URL
fragments, so the server never sees the key. The recipient's app replies with
the same key (unwrapped from the envelope). The web client (`apps/web`) reads
the fragment and decrypts locally.

**Honest caveat:** anyone holding the full link can read the thread. The
fragment does not protect against clipboard sync, screenshots, or a hostile
client environment.

## Integration checklist (not done in this pass)

This directory is self-contained. To wire it into the app:

- In `send_screen.dart` / `sync/outbox.dart`: call
  `CryptoService.prepareSend`, send `SendPreparation.e2e` bodies through
  `CryptoApi.sendEncrypted`, persist `contentKey` via
  `rememberClaimKey(replyToken, key)` to build the claim link, and show the
  legacy ("not end-to-end encrypted") label when `e2e == false`.
- In `inbox_screen.dart`: render rows through
  `CryptoService.decryptStoredBody` and use the `HistoryReadability` state for
  labels rather than inventing per-screen logic.
- In `api_client.dart` — optional: the `CryptoApi` class already covers the
  new routes, so no change is required for a first wiring.
- On logout/account wipe: call `CryptoService.wipeKeys` alongside the existing
  local wipe.
- The API must be wired as described in `api/src/CRYPTO-WIRING.md` before any
  of this reaches a user.
