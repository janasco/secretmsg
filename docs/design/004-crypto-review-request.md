# Cryptographic review request — SecretMsg message encryption

**Status: unreviewed, and deliberately not shipped.** This document exists to
make the review cheap for whoever does it. It is not a summary for users.

Written 2026-10-08. Branch `feat/1.8`, commit `1709403`.

---

## What is being asked

Review the message-encryption design in
[`api/src/crypto.ts`](../../../secretmsg-private/api/src/crypto.ts) (762 lines)
and `apps/mobile-flutter/lib/crypto/`. Specifically: **is the threat model
achievable with this design, or does it claim more than it delivers?**

If the honest answer is that the design should be replaced with a standard
construction (HPKE, or an existing audited protocol) rather than repaired,
saying so is a better outcome than a list of patch notes.

## The one-paragraph design

Per-install X25519 keypair generated on device and held in
`flutter_secure_storage`. Each message gets a fresh 256-bit content key and is
encrypted with AES-256-GCM (`A256GCM`, AAD `secretmsg-body-v1`). The content key
is wrapped once per recipient device using X25519 ECDH → HKDF-SHA256 →
AES-GCM. The wire format is a versioned `enc:v1:` envelope. Primitives come from
the published `cryptography` Dart package; nothing is hand-rolled.

## Known gaps, stated by the implementer

These are believed correct and are **not** claimed as solved:

| Gap | Consequence |
|---|---|
| **Bespoke envelope**, not HPKE or a reviewed construction | Novel protocol, novel mistakes |
| **No sender authentication** | Anyone can put any content key in an envelope |
| **Malicious server can substitute device keys** | The server serves the public keys; it can serve its own and read messages at send time |
| **No forward secrecy** | Content keys are wrapped to long-lived device keys; one device-key compromise decrypts past messages |
| **No replay resistance** beyond the existing 5-minute `client_msg_id` window | A captured envelope can be re-delivered |
| **No key transparency, no safety numbers** | Users cannot verify they are talking to the right device |

## Questions where an expert opinion changes the plan

1. **Is the server-substitutes-keys gap acceptable for this product?** The
   server is operator-controlled, so the threat model is "honest-but-curious
   operator plus a compromised server". If substitution is out of scope, say so
   explicitly and the claim must be worded to match ("the server cannot read
   messages *unless it chooses to*" is not a privacy claim most users would
   recognise). If it is in scope, what is the cheapest fix — a pinned key
   fingerprint shown in the app on both ends?
2. **Is the wrapped-content-key construction sound?** ECDH → HKDF-SHA256 →
   AES-GCM over a fresh content key, one wrap per device. Is the info string and
   salt handling in `crypto.ts` correct, and is there a nonce-reuse path?
3. **Is there a downgrade path?** Messages carry `enc_version`; legacy plaintext
   stays at 0 and is dual-read forever. Can a client be induced to send or accept
   plaintext when it should not?
4. **Report disclosure.** A reporter may hand over the per-message key so the
   server can verify the report. Does handing over one content key leak anything
   beyond that one message?
5. **Multi-device.** Devices are linked via the existing 5-minute pairing code.
   What does that flow need to be safe for key material, and is the current
   approach adequate or actively harmful?
6. **Filtered Words moved client-side.** It is now advisory — a modified client
   can omit the result and the server cannot verify it. Is there any protocol
   change that restores a real guarantee without the server reading content?
   (Assume "no" is a fine answer; it would just have to be said out loud.)

## What the reviewer needs

- `secretmsg-private/api/src/crypto.ts` — envelopes, wrap/unwrap, report
  verification, route handlers
- `secretmsg-private/api/src/CRYPTO-WIRING.md` — the routes
- `secretmsg/apps/mobile-flutter/lib/crypto/` — key generation, storage,
  envelope construction, claim links
- `secretmsg/apps/web/src/lib/e2ee.ts` — the browser decrypt path for claim links

## What "reviewed" would need to mean before shipping

- Every gap in the table above is either fixed or **stated in user-facing copy**.
- The claim shown to users matches the guarantee. Specifically: if key
  substitution remains possible, the app may say "end-to-end encrypted" but must
  not say "not even we can read them".
- Reinstall and multi-device behaviour is stated before the user relies on it.

## Deliberately not built

Key escrow, key transparency, safety numbers, forward secrecy, ratcheting, and
private-set-intersection filtering. Each would be a claim someone would have to
defend, and none is implemented.
