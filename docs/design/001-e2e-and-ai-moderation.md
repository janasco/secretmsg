# SecretMsg — Feature Briefs: End-to-End Encryption and On-Device AI

October 2026 · Status: draft specification for review · Scope: `apps/web`, `apps/mobile-flutter`, private Worker API + D1

How to read this: each brief has the required four sections (User story, Acceptance criteria, Edge cases, Open questions). Mechanism sections are provisional engineering recommendations. Acceptance criteria are the contract; they are written to be individually testable.

---

## 0. Shared context

### 0.1 The fixed decision

The hybrid privacy model is fixed, not open for debate in these briefs:

- **Message bodies and replies are end-to-end encrypted.** The server stores ciphertext it cannot read.
- **Metadata is visible to the server** — timestamps, ciphertext size, recipient, sender install-fingerprint hash, delivery/read state, rate-limit keys, block records, report records, push tokens.
- **Moderation happens client-side on the plaintext, in the recipient's client, before display**, plus server-side checks on the metadata channel.
- **Consequence, stated plainly:** client-side filtering is bypassable by a modified client. A modified client can disable filtering, skip translation, read anything its device can decrypt, and export it. Client-side moderation is a protection for the ordinary user, not an enforcement boundary against a determined one. The service can still enforce metadata-side rules (rate limits, sender-fingerprint blocks, account bans, report handling, legal process), but it cannot detect content it cannot read.

### 0.2 What this guarantees and what it does not

Guaranteed:

- SecretMsg, Cloudflare, and a D1/R2 database thief cannot read message or reply bodies in transit or at rest.
- A network attacker cannot read bodies.
- Reports can still be processed, either from metadata alone or from single-message content a user explicitly discloses.

Not guaranteed:

- A compromised, rooted, or unlocked device — malware, a person holding the phone, an accessibility service, screenshots, notifications, and clipboard all see plaintext.
- A malicious build of the client. The app cannot prove to the server that its filtering step ran, and it does not try.
- Key distribution, unless key transparency or out-of-band verification exists. A compromised or compelled service that serves a wrong public key for a recipient can read messages sent to that key. Brief 1 treats mitigations and leaves the strength of this guarantee as an open question.
- Content already in the system. Pre-migration messages are server-readable plaintext and stay so until migrated or deleted (Brief 1, migration).
- Recall. Deleting a message deletes it from SecretMsg systems and honest linked devices, not from copies other people already saw, exported, or screenshotted.

### 0.3 Constraints that both briefs must respect

- **Message cap:** `kMaxMessageLength = 500` characters (`apps/mobile-flutter/lib/api/config.dart`); replies are capped at 500 in the UI. No attachments exist. End-to-end payloads are short text.
- **No analytics SDK.** Feature measurement must not smuggle one in. Any optional feedback is explicit, content-free, default-off, and disclosed.
- **Age:** service is 13+ per policy (13–17 with guardian permission). No feature may process children's data beyond what the existing service does without legal review.
- **No raw content retention beyond defined windows.** With E2E, the server's only possible plaintext is user-disclosed report content; that gets a defined window (Section 3.1).
- **Current server-side content moderation must be replaced, not duplicated.** The shipped mechanisms are: server-side hidden-word matching (`off`/`standard`/`strict` via `mod_sensitivity`), `quarantine_reason = 'hidden-word'`, a server filtered tray (`GET /api/inbox?filter=quarantined`), and compose-time rejection of matching sends.
- **Push previews must change.** FCM currently receives a server-truncated 140-character preview (Privacy Policy §2). The server cannot generate that under E2E.
- **Reuse existing UX where possible:** single-use backup codes and `authRecover` for key recovery; the ~5-minute pairing code flow (`createPairCode`) for device linking; the once-only `BackupCodesScreen` gate for any new key-backup step.
- **Fonts:** if any new script coverage is added for translation, use freely available fonts (Google Fonts, e.g. Noto). No other font may be introduced.

---

## 1. Brief — End-to-end encryption for messages

### 1.1 User story

As a person who sends or receives an anonymous SecretMsg message, I want message bodies and replies to be readable only on the intended participant's device, so that SecretMsg, its infrastructure providers, a database breach, or a network observer cannot read what was written.

### 1.2 What changes, concretely

| Current mechanism | Disposition under E2E |
|---|---|
| `POST /api/message/:username` with `content` | Sends a versioned ciphertext envelope; server validates size, rate limits, block-list, pause state, Turnstile, and stores ciphertext |
| Reply via `POST /api/inbox/:id/reply` with `reply` | Stores a reply ciphertext envelope addressed to the per-message sender key |
| Claim page `/reply/:token` returns `content` and `reply_content` | Returns envelopes only; the per-message decryption key travels in the URL **fragment** (`#k=…`) and never reaches the server |
| Server hidden-word filter + compose-time 400 | Moves to the recipient client before display (Brief 2); the sender is no longer refused at compose time |
| Filtered tray `?filter=quarantined` | New E2E messages are held locally; the server tray remains only for pre-migration rows |
| FCM 140-char preview | Removed. FCM carries no text; optional preview is generated on-device after decrypt |
| Report stores report reason; server can read content | Metadata-only report by default; optional single-message disclosure with a per-message content key the server can verify against its stored ciphertext |
| Blocks, pause, rate limits, Turnstile | Unchanged; they operate on metadata and still work |
| `is_read`, pin, delete | Unchanged UI; now act on ciphertext rows plus local cache |

### 1.3 Recommended mechanism (provisional)

Key hierarchy:

- **Account identity key pair** (X25519), generated on the first device; never derived from the 4–6 digit PIN.
- **Per-device key pairs** (X25519). The account publishes a versioned key set: key IDs, algorithm, public keys, updated-at. Messages wrap to every active device key.
- **Per-message content key (CEK)**, 256-bit random. Body/reply encrypted with XChaCha20-Poly1305 (or AES-256-GCM where the web platform only exposes that).
- **Per-message sender key pair** for the claim link. Its private key is returned to the sender's client once, embedded only in the claim-link URL fragment. The server stores the public key with the message so the recipient's reply can be encrypted to it.
- **Signatures:** the per-message sender key (Ed25519 or the platform equivalent) signs the ciphertext. Needed for tamper detection and for report verification.
- **Envelope:** versioned JSON — `{v, alg, key_id, nonce, ciphertext, sender_pub, sig}`. One parser, one version negotiator, on both clients.
- **KDF:** HKDF-SHA-256 for key wrapping; Argon2id for recovery-material-derived wrapping keys.
- **Padding:** ciphertext padded to buckets (e.g. 512 B / 1 KiB / 2 KiB / 4 KiB) so exact character count is not exposed. Message cap of 500 characters keeps this cheap.

Key storage and recovery:

- Android: private keys wrapped by a Keystore-backed key via the existing `flutter_secure_storage`; plaintext inbox/outbox caches encrypted with a local key (the current `SharedPreferences` inbox cache and `outbox_ops_v1` queue must not store readable message text). Android auto-backup must exclude message data.
- Recovery/escrow: an opaque escrow blob in D1 holding the wrapped identity/device keys. The KEK comes from recovery material the server never sees. Backup codes as currently formatted may be too low-entropy to protect escrow alone; a high-entropy recovery key (or user passphrase) is the fallback requirement — see open questions.
- Multi-device: new device links through the existing short-lived pairing code, confirmed on an already-linked device, which transmits the wrapped key material over the authenticated channel. Revocation removes the device key from the published set.
- Rotation: rotate on device removal or suspected compromise. Devices keep old private keys for a defined grace window (proposal: 180 days) to decrypt history. The server always serves only the current set for new sends.

Reports (the hard problem):

1. **Metadata-only report (default).** Reason category, message ID, timestamp, sender fingerprint hash, device hint. No content. This keeps existing sanctions available: block by fingerprint, rate-limit tightening, account-level action, report counts.
2. **Optional content disclosure.** The user explicitly reviews exactly what will be shared, then the client sends: message ID, stored-ciphertext SHA-256, the per-message CEK, and the sender signature. The server re-decrypts its own stored ciphertext with that CEK, verifies the hash, and only then stores the plaintext (and the CEK) in the report record. A mismatched hash or wrong CEK is recorded as unverifiable and never enters moderation as verified content.
3. **Honest limits of disclosure.** The server can verify that disclosed plaintext matches the stored ciphertext. It cannot verify authorship (the sender is anonymous and keys are per-message), and a party who refuses to disclose leaves moderators with metadata only. Report records must be labeled "verified against stored ciphertext" vs "metadata only," and the report content is the only plaintext the operator ever holds.
4. Disclosure is per-message and revocable in the sense that the CEK is scoped to one message; it never unlocks the user's other messages.

Push:

- FCM payloads contain message ID and account routing only — no text.
- On-device preview: when notifications are enabled, the app can decrypt and post a local notification with text. "Show message previews in notifications" defaults **off**; when off, copy is generic ("New anonymous message").
- If the app cannot decrypt (no key), the generic notification is shown and the inbox shows the key-loss state.

### 1.4 Acceptance criteria

1. **Ciphertext-only transport.** No send/reply path (web send page, app send, app reply, claim page) transmits plaintext message or reply text to SecretMsg infrastructure. Test: place a unique marker string in a message; assert it appears in no request body, no Worker log, no D1 column except the disclosed-report table (and only after consent).
2. **Round-trip parity.** A message composed on the web decrypts identically in the app; a reply composed in the app decrypts on the claim page; verified for every shipped script/language. Test: fixture matrix of scripts, emoji, RTL, 500-char edge cases.
3. **Key publication hygiene.** The public profile/key endpoint exposes only public key sets and timestamps. No private key, CEK, or unwrapped escrow material ever leaves a device; the escrow blob cannot be unwrapped by the server. Test: schema assertion + server-side unwrap attempt fails.
4. **No-key recipient (migration window).** If the recipient has no published key set, the sender sees an explicit pre-send notice ("this message will not be end-to-end encrypted") and the stored row is tagged `e2ee=false`; the recipient sees a "not end-to-end encrypted" badge on it. Test both clients.
5. **Migration cutoff.** After the announced cutoff, the API rejects plaintext submissions with a distinguishable error, and clients show an update-required path rather than a generic failure. Test with a legacy client build and a plaintext request.
6. **Tamper/corruption handling.** A modified ciphertext byte produces a clean decrypt failure: "couldn't verify this message," no partial plaintext, no crash; the entry still supports metadata-only report and delete. Test: mutate a stored D1 row and an in-flight response.
7. **Key loss without recovery material.** A wiped account with no escrow and no linked device shows messages by metadata with "content unavailable — the key was on the original device"; delete and metadata report still work; nothing pretends to recover content. Test: wipe, reinstall, sign in.
8. **Recovery with escrow.** With valid recovery material, a new device decrypts history within the documented grace window; the recovery UI states what will and will not come back before the user commits. Test: restore on a second device.
9. **Multi-device.** Messages sent after a second device links are decryptable on both; history behavior on a newly linked device matches the documented rule; a revoked device cannot decrypt messages sent after revocation. Test: link, verify, revoke, send, verify failure on revoked device.
10. **Claim-link secrecy.** The per-message key exists only in the URL fragment; opening the link without the fragment shows "cannot decrypt" with metadata only. Test: server log/referrer audit, open bare token URL.
11. **Report verification.** A disclosure report with the correct CEK is recorded `verified=true` after the server decrypts its own row; a wrong CEK or altered hash is recorded `verified=false` and is not treated as content evidence; the moderation surface labels which is which. Test: correct, wrong-CEK, tampered-hash cases.
12. **Metadata-only report.** A report with no disclosure is accepted, drives existing block/sanction paths, and never requests or receives content.
13. **Filtered Words replacement.** Hidden-word matching runs in the recipient client after decrypt and before render, honoring `off`/`standard`/`strict`; `strict` requires a deliberate reveal; the sender gets no filter error and cannot observe the recipient's word list; the server filtered-tray endpoint is not used for new messages. Test: all three sensitivity levels on new E2E messages.
14. **Offline compose.** Queued sends contain already-encrypted payloads and retry byte-identically under the same `client_msg_id`; a draft whose key set was never fetched is held and labeled "not yet encrypted" until it can encrypt; the local queue holds no plaintext readable without the device keystore. Test: airplane-mode compose, reconnect, storage inspection.
15. **Push hygiene.** FCM payloads contain no message text; notification copy is generic by default and, with previews enabled, generated on-device after decrypt. Test: payload capture, default settings.
16. **Deletion.** Deleting a message removes its ciphertext and wrapped CEKs from D1 and the local cache on the acting device; other linked devices drop it on next sync; disclosed report content follows the report retention window (Section 3.1). Test: delete on device A, inspect device B and D1.
17. **Transparency list.** A published table of server-visible metadata matches what D1 actually stores (row-dump test), and the in-app "What the service can see" screen reflects the same list.

### 1.5 Edge cases

1. **Key loss, no escrow.** No backup material and no linked device. Ciphertext is unrecoverable by design. UI must say so before the user deletes anything, and support must have no override. The account itself still works (new key set generated).
2. **Multi-device in the hostile case.** A pairing code is intercepted inside its ~5-minute window; the new "device" receives wrapped keys. Mitigation required: confirmation on the existing device plus binding of the pairing session to both endpoints; an account with one device offers recovery-material restore instead of pairing.
3. **Recipient has no key yet.** Legacy accounts, paused accounts, and an account in mid-rotation with an empty key set. Send policy (allow with disclosure vs block) is per-criterion 4/5; mid-rotation must never produce a message wrapped to zero keys silently.
4. **Reinstall.** Android Keystore keys are non-exportable and app data is cleared. Recovery is escrow-only. Both Play and sideload tracks are affected; sideload users update manually, so the migration cutoff interacts with `update_check.dart` and the download page.
5. **Reply threading.** One reply per message today. The claim link must keep working when opened before the reply exists (empty state), then on revisit fetch and decrypt the reply. The link is a bearer capability: anyone holding the full fragment can read the thread, and losing it means the reply can never be read. The UI must say both things at send time.
6. **Report when the server cannot read.** Covered by the disclosure flow (1.3). Sub-cases: the user deleted the local message (CEK gone → metadata-only report); the reporting client is a third-party or modified client that never retained the CEK (metadata-only); the report is filed from the web inbox (web must hold the key, see open question 2); repeated reports on one sender fingerprint accumulate sanctions even without disclosure.
7. **Moderation with no signal.** Not applicable to E2E itself, but the inbox must render decryptable cached messages offline and show held/unavailable states without network. Detailed in Brief 2.
8. **Model updates.** Decoupled from E2E envelopes, but envelope version negotiation and key-set schema versions must be forward/backward compatible: an older client must show an update prompt, never garbage.
9. **Translation of encrypted text.** Translation happens after client-side decryption only. No network translation API may receive message text while it is supposed to be E2E; the only server-side translation is of content a user disclosed in a report, under the report retention window. Detailed in Brief 2.
10. **Offline compose.** The current outbox stores operation params (including message text) in `SharedPreferences`. That is a plaintext leak at rest. The queue must hold either ciphertext or keystore-encrypted plaintext; retries must not re-encrypt under a rotated key in a way that breaks idempotency (queued payload stays fixed; a 409 key-rotation response produces a new `client_msg_id` and re-encryption from the locally held plaintext).
11. **Very long messages / payload limits.** The 500-character cap means bounded envelopes, but the server now cannot check plaintext length. Enforce a ciphertext size ceiling (proposal: 8 KiB) and padding buckets; reject oversize envelopes at the API edge, before storage.
12. **Unicode and bidi.** Normalize to NFC before encryption; decide whether to strip or flag bidi control characters (RLO can visually reorder text); emoji ZWJ sequences must round-trip; classifiers/summaries operate on the normalized original.
13. **Server-side Filtered Words, exact fate.** Compose-time rejection cannot survive server-side E2E without publishing a dictionary-testable representation of the recipient's word list to senders, which leaks it. Default: recipient-side enforcement only; the send-screen bullet "Filtered Words refuse matching sends at the moment they are sent" and Settings copy must change. Pre-migration quarantined rows remain viewable in the server tray until read/deleted, then purged on the normal schedule. If the product insists on preserving compose-time refusal, the only honest path is a private set-intersection design; treat it as a research question, not a v1 requirement.
14. **Legacy plaintext history.** Pre-migration messages are readable on the server. Options: (a) clients that already hold them re-encrypt to their own device keys and replace the server rows, (b) unclaimed rows are deleted at the cutoff. Either way the privacy page must state that messages sent before the migration date were not end-to-end encrypted, and the deletion must be verifiable.
15. **Legal process.** A content demand can only be answered with ciphertext and metadata; content exists only if the user disclosed it in a report or if a device is separately compelled. Response templates and the privacy page must say this without implying universal unreadability (pre-migration rows exist).
16. **Compromised key service.** A malicious or compelled server can substitute a recipient public key at send time. Mitigations, in order of cost: key-change warnings for the account owner, published key fingerprints users can compare, then a transparency log. Until then the guarantee is "the server cannot read ciphertext it stores," not "the server can never arrange to read messages."
17. **Account deletion.** Deleting the account removes the public key set and escrow blob; outstanding claim links resolve to nothing; ciphertext already delivered to other devices is gone from our systems but not from those devices.

### 1.6 Open questions

1. Recovery entropy: are the current backup codes strong enough to wrap an identity key, or must E2E restore require a separate high-entropy recovery key / passphrase with a hard warning that losing it loses history? (This is the single biggest UX constraint on the design.)
2. Does the web inbox ship decryption at all? If yes, unlocking must use recovery material (backup code/passphrase), never the 4–6 digit PIN alone, because the wrapped key is an offline-attackable blob. If no, web inbox is ciphertext + "open in app," which is a visible product regression for logged-in web users.
3. Transparency: full append-only key log with consistency proofs, or fingerprints + change warnings? Who operates it, and is it worth it for this audience?
4. Device cap and revocation UX: maximum linked devices; what a revoked device's client does with its local plaintext cache (honest client wipes; dishonest client cannot be stopped).
5. Migration policy: cutoff date, force-update mechanics for sideload users, and whether legacy rows are client-re-encrypted or deleted. Who owns the user communication for the resulting message loss?
6. Should a strict hidden-word hit optionally emit an opaque "filter hit" signal (message ID + filter version, no words) so the server keeps some abuse signal, default off? Determine whether it leaks enough to be useful and whether it is acceptable to disclose.
7. Envelope algorithm choice for the web path: X25519 + XChaCha20-Poly1305 with a WASM library, or P-256 ECDH + AES-GCM via WebCrypto only. Whichever is chosen must be verified against the minimum supported Android WebView.
8. PIN reset via support/backup code: does the key set follow, or does a PIN reset produce a new identity key with old history locked? Needs a decision before the first release because the recovery screen promises an outcome.
9. Post-quantum timeline: X25519 now; when, if ever, do hybrid key exchange (e.g. X25519 + ML-KEM) and a new envelope version become a requirement for a 13+ consumer app?
10. What is the published retention window for report-disclosed plaintext and CEKs, and who signs off on legal holds that extend it?

---

## 2. Brief — On-device AI toxicity filtering and auto-translation

### 2.1 User story

As a SecretMsg inbox owner, I want potentially harmful messages held and foreign-language messages translated on my own device, so that I get protection and comprehension without message content ever being sent to the service.

### 2.2 Placement and pipeline

Fixed order of operations, all on the recipient device, all after E2E decryption:

1. Decrypt and verify envelope (Brief 1).
2. Normalize (NFC); neutralize/flag bidi override characters.
3. Deterministic hidden-words pass (recipient's existing `hidden_words` list, existing `off`/`standard`/`strict` semantics).
4. On-device classifier pass (probabilistic labels + scores).
5. Auto-translation (on-device model) when the detected source language differs from the user's language and the user allows it.
6. Render: original or translation, with label chips and a reveal gate per sensitivity setting.

Server-side, only metadata checks remain: Turnstile at compose, send rate limits, sender-fingerprint blocks, report counts, account sanctions, report intake. The server never receives text, translations, or classifier labels except in a content-disclosure report (Brief 1, 1.3) where labels may be attached only with the disclosure consent.

### 2.3 Recommended mechanism (provisional)

- **Classifier:** quantized multilingual text classifier (int8 TFLite or ONNX Runtime Mobile class), CPU inference in a background isolate. Budget: ≤ 35 MB per shipped model file, ≤ 120 MB added peak RSS, p95 ≤ 250 ms for a 500-character message on a reference mid-tier device (proposal: 4 GB RAM, Android 10). Categories: harassment/bullying, hate, sexual content, violent threat, self-harm, spam/scam. Output: label + score buckets, never a single "bad" boolean. Messages are short (≤ 500 chars), so one inference window per message; chunk only if the cap changes.
- **Model delivery:** signed, versioned model bundles (manifest with SHA-256 + detached signature; HTTPS from first-party storage or Play Feature Delivery for the Play track; the same bundles over the CDN for sideload). Baseline deterministic lexicon is bundled in the APK so first-run protection works before any download. Downloaded models live in app-private storage. No dependency on a runtime service that requires a Google account.
- **Translation:** per-language on-device NMT models, downloaded on demand, Wi-Fi preferred, resumable, size shown before download; on-device language identification. Originals are never replaced: display is `translation + "Translated from X" + "Show original"`. No network translation API may receive message text.
- **Sensitivity mapping (preserves existing user-facing model):** `off` = no classifier pass, no hidden-word holds (current semantics kept); `standard` = matches/flags are held in the local filtered view with a reveal action; `strict` = not shown in the main list, reveal requires a deliberate two-step action. The classifier runs per user setting only; it is not a silent background process.
- **Flag UX:** held messages show a stub with a reason chip ("Held: possible harassment"). Reveal never auto-reports, auto-blocks, or auto-deletes. Self-harm and credible-threat labels show the existing safety-resources route (there is already a SafetyResources/ChildSafety page on the web; the app needs the parallel surface). No counts or labels are sent anywhere without explicit user action.
- **Sender-side advisory (optional, later phase):** the sender's own client may run the same classifier before encrypting and show "Recipients may see a warning on this message" with edit/send-anyway. The result never leaves the sender's device; the check is advisory and bypassable by design.
- **Feedback without an analytics SDK:** a per-flag "Was this right?" control, stored locally; optionally submitted content-free (label, model version, locale, single-use random token) only if the user opts in during onboarding or at the flag. Default off. This is the only field measurement channel; without it, quality is measured by internal evals and user support reports.
- **Release gates:** before each model ships, measure on a held-out multilingual eval set: recall ≥ 0.85 for the top-severity categories (threat, self-harm, sexual content involving minors) and a false-positive rate ≤ 5% at the default threshold, reported per language; thresholds are tuned per category, not globally. Document known failure modes (slang, reclaimed language, quotes, satire, code-switching) in the model card.

### 2.4 Acceptance criteria

1. **Zero content egress.** With models installed and the device in airplane mode, decryption, hidden-word holds, classification, and translation all function; a network capture of an online session contains no message text, translation, or classifier label for ordinary use. Test: airplane-mode matrix + request capture with marker strings.
2. **Pipeline order.** A message that both matches hidden words and triggers the classifier shows the hidden-word reason; a translated message's classifier ran on the original text when the original language is supported, and on the translation (labeled as such) only when it is not. Test: crafted fixtures.
3. **Flag persistence.** Hold state, labels, and model version survive app restart and local cache; after reinstall, messages return as ciphertext and are re-evaluated after unlock with the current model. Test: kill/relaunch, wipe/reinstall.
4. **No automatic consequences.** An on-device flag alone never creates a report, block, deletion, or server-side record. Test: flag a message, then diff the server rows to prove no change.
5. **Strict mode is not a black hole.** `strict` hides from the main list and still exposes the local filtered view with a reveal action; controls that discard a held message are explicit and undoable until confirmed. Test: strict-mode flows for hidden-word hits and classifier flags.
6. **Offline/absent-model state.** With models installed, behavior is identical offline. Without the classifier model, deterministic filtering still runs, and the message shows an "AI check unavailable" badge; `standard` shows the message with the badge, `strict` holds it until checked (documented trade-off). Test: fresh install, no network, both sensitivity levels.
7. **Model integrity.** A model bundle that fails signature or SHA-256 is rejected, the previous version stays active, and the user sees "model update postponed." Test: corrupt bundle, wrong signature.
8. **Model rollout and rollback.** A server-published preferred model version controls rollout; minimum supported version controls compatibility; rolling the preferred version backward does not uninstall a valid newer model or crash older clients. Test: version flip forward and back with two app builds.
9. **Performance.** p95 classification ≤ 250 ms and translation ≤ 900 ms for 500 characters on the reference device; no main-thread frame over 16 ms caused by inference; memory and storage budgets enforced in CI on a physical or emulated reference device. Test: benchmark harness.
10. **Translation UI and storage.** "Translated from X" label, "Show original" toggle, original preserved in local storage, translation cached per message per language, re-translate on language change. Test: toggle and language switch.
11. **Unsupported language honesty.** A message in a language without a classifier model is labeled "not checked for your language"; translation-unavailable copy is distinct from failure; no message is ever presented as "checked clean" when it was not checked.
12. **Hidden words parity.** Existing `hidden_words` and `mod_sensitivity` values keep working after migration, evaluated on-device; legacy server-quarantined rows remain viewable; the server filtered-tray endpoint is no longer used for new messages. Test: upgrade a real account fixture through both paths.
13. **Report integration.** When a flagged message is reported with content disclosure, the report may include label + model version (consent is explicit); a metadata-only report includes no label. Test: both report paths.
14. **Accessibility and rendering.** TalkBack announces the held state without reading held text before reveal; the translation toggle is reachable; RTL and CJK render correctly with the app's fonts; if script coverage requires new fonts, they are Google Fonts (e.g. Noto). Test: TalkBack pass, RTL/CJK fixtures.
15. **Minor-safety and ads boundary.** Classifier labels and message text are never passed to the ad SDK or used for ad selection; an ad-request payload inspection test confirms no message-derived fields. Test: instrument the ads layer.
16. **Copy and compliance shipped together.** Every page/string claiming "does not use machine-learning content classification" is replaced in the same release with an accurate description (on-device, probabilistic, bypassable by modified clients); privacy disclosures, the Play Data Safety annex, and the in-app legal copy are updated. Test: string audit over web + app legal content.

### 2.5 Edge cases

1. **Moderation with no signal.** Covered by criterion 6. Additional case: first-run with no Wi-Fi and no bundled lexicon thresholds — the UI must distinguish "not checked" from "checked."
2. **Model updates.** Staged rollout, rollback, poisoned bundle, storage pressure (refuse download, keep current), and labels created by a model version that is later pulled — historical labels stay pinned to their model ID and are never retroactively rewritten.
3. **Translation of encrypted text.** Only after decryption; no clipboard-to-translate path that sends text to a server; report-disclosed content may be machine-translated server-side under the report retention window, and that is disclosed in the report flow.
4. **Long messages at the cap.** 500 chars of Latin, CJK, or emoji; URLs, @handles, and numbers must survive translation unchanged; translation failures return the original with an error chip, never a partial sentence silently.
5. **Mixed language / code-switching.** Language ID picks a dominant language; the classifier must still run (multilingual model) even when the language-ID confidence is low; UI shows the detection it used.
6. **Unicode attacks.** Bidi overrides (RLO/LRO), zero-width characters, homoglyphs, and leet substitutions can disguise or evade. Normalize before classification; visually neutralize bidi controls; document that evasion is expected in a bypassable client-side model.
7. **False positives on legitimate language.** Reclaimed in-group terms, quotes, satire, and support-speak must be recoverable with one tap ("Show anyway"), and the tap must not nag or shame. Test fixtures assembled from real-world slang, not just clean examples.
8. **De-Googled and sideload devices.** Model download must work without Play Services; the sideload track gets the same signed bundles from the first-party CDN; no model may be gated behind a Google account.
9. **Low-end devices.** 2–3 GB RAM or < 500 MB free storage: refuse the download, keep deterministic filtering, and surface why; never attempt a model load that risks OOM-killing the app before a message is shown.
10. **Self-harm and threat flags.** Highest-severity labels show resources without automatically contacting anyone, without revealing the flag to the sender, and with localized crisis links where available; the app must not claim to detect every such message.
11. **Notifications and screenshots.** Preview text is default-off and, when enabled, generated locally; flags are not shown on the lock screen; if flagged content is held, its preview must not leak through notifications.
12. **Multi-device flag drift.** Flags are computed per device and are not synced by default; two devices with different model versions can disagree about the same message. Define acceptable drift or sync opaque label metadata (the latter leaks a coarse content property server-side — open question).
13. **Hidden-word strict hits and optional opaque signal.** If the optional hit signal ships, it must carry no words and no content, be default off, and be documented; verify the server cannot use it to test dictionary candidates.
14. **Web inbox.** If the web client gets no ML runtime, it must say "held/checked on your phone" rather than showing unclassified content as if clean; decide scope explicitly (open question).
15. **Aged/migrated messages.** Pre-migration plaintext rows that are migrated client-side must be run through the current pipeline before display; messages too old to migrate follow the E2E migration deletion schedule.
16. **Abuse of the reveal flow.** A user (or someone else holding the unlocked phone) can reveal anything; reveal must not unlock a "report all" or bulk action, and repeated reveals must not change server-visible state.

### 2.6 Open questions

1. Model provenance: in-house training vs licensing; training-data consent and licensing for a multilingual hate/abuse corpus; who owns and reviews the taxonomy, and how teen-slang coverage is validated.
2. Measurement without an analytics SDK: is opt-in, content-free feedback enough to operate a quality bar, and would the privacy policy language for it be credible? What is the minimum acceptable field signal for model updates?
3. Launch language set for both classifier and translation: which languages ship first, in what order, and what the download-size budget per user is.
4. Web scope: does `apps/web` get classification/translation (WASM runtime + downloaded models) or is the web inbox ciphertext-only/"open in app"? This changes effort substantially.
5. Label disclosure in reports: always with disclosure consent, never, or user's choice per report? A label is content-derived metadata and reveals something even without text.
6. Any automatic escalation at all (e.g., repeated self-harm flags)? The no-auto-consequences stance protects users but interacts with child-safety legal review under E2E; get counsel before shipping anything automatic.
7. Age banding: the service has self-declared 13+, no assertion; using age to tune thresholds creates compliance exposure with no real enforcement. Confirm thresholds are age-independent.
8. Model governance: who signs bundles, key custody, rollback authority, staged-rollout visibility, and whether model cards are published.
9. Do local labels and translations need their own retention/wipe policy distinct from message deletion, and should they be included in "delete my data"?
10. Is on-device translation allowed to use a system-provided translation service that we do not operate (unknown egress), or is that forbidden by the E2E promise? Recommend forbidden until verified otherwise per platform.
11. Does the opt-in feedback path count as "analytics" under the product's own statements, and what exact wording replaces the current blanket "no analytics SDK" claim if it ships?
12. Would a private set-intersection pre-send check (recipient word list vs sender draft, revealing only a match/no-match bit) ever be worth building to restore compose-time Filtered Words, or is recipient-side-only final?

---

## 3. Cross-cutting compliance and copy

### 3.1 Retention windows (proposal)

| Data | Where | Retention |
|---|---|---|
| Message/reply ciphertext | D1 | Until the recipient deletes the message or the account is deleted (unchanged from today) |
| Report-disclosed plaintext + its CEK + moderation translation | Report records | 90 days after the case is resolved; legal hold may extend; then plaintext/CEK/translation deleted, metadata retained |
| Message plaintext (ordinary operation) | Never on SecretMsg infrastructure | — |
| Local plaintext cache and translations | Device, keystore-encrypted | Until message delete, account wipe, or uninstall; excluded from Android auto-backup |
| FCM payloads | Firebase | Message ID and routing only; no text |
| Optional classifier feedback | Content-free | Default off; if enabled, ≤ 90 days, described in the privacy page |
| Public keys / device list | D1 | Until rotation or account deletion; key history only if a transparency log is adopted |
| Escrow blob | D1 | Until the user disables escrow, rotates, or deletes the account |

### 3.2 GDPR / COPPA notes

- **GDPR:** update Article 13 disclosures for E2E, metadata processing, on-device processing, and any opt-in feedback. Document lawful bases per purpose (contract for delivery, legitimate interests for abuse prevention, consent for optional feedback and personalised ads as today). Record a DPIA covering: E2E design, metadata-based abuse prevention, on-device profiling of 13–17 year olds, and report-content handling. Data subject rights: access/portability can return metadata and ciphertext, not readable content; erasure cannot recall ciphertext already decrypted on a user device or content disclosed in a report within its window; state both in the policy in the same plain register the current policy already uses. No solely automated decision with legal effect exists (flags are display-level and user-reversible); keep it that way.
- **COPPA:** unchanged position — not directed to under 13, deletion path for discovered under-13 users exists (`safety@secretmsg.net`, child-safety policy page). E2E removes proactive server-side content detection; the child-safety page and Approach-to-Safety page must describe the compensating controls (user reports, metadata signals, blocks, bans) and must not claim detection capabilities the system lacks.
- **Do not overclaim:** the words "private," "unreadable," and "moderated" all need qualified copy. The lie to avoid is "we read your messages to keep you safe" after E2E; the other lie to avoid is "nobody can ever read your messages" given modified clients, screenshots, and key substitution.

### 3.3 Files that must change with these features

- `apps/web/src/pages/PrivacyPage.tsx` (canonical policy) and `LEGAL/PRIVACY_POLICY.md` (mirror, never the source of truth): E2E scope, metadata list, FCM preview removal, report disclosure, on-device AI, retention table, DPIA-relevant detail.
- `apps/web/src/pages/ApproachToSafetyPage.tsx`, `SafetyPage.tsx`, `SafetyToolsPage.tsx`, `CommunityGuidelinesPage.tsx`, `ChildSafetyPage.tsx`, `TermsPage.tsx`, `BlindReplyPage.tsx`, `SendMessagePage.tsx`, `InboxPage.tsx`.
- `apps/mobile-flutter/lib/data/static_content.dart` (parallel legal copy; currently states the service does not use machine-learning classification in multiple sections).
- `apps/mobile-flutter/store/DATA_SAFETY.md` (Play form annex: encryption-in-transit answers, on-device processing, any opt-in feedback).
- `apps/mobile-flutter/lib/screens/settings_screen.dart` (filter copy: "sent straight to moderation" line and the strictness dial descriptions) and `send_screen.dart` (the compose-time Filtered Words bullet: "Filtered Words refuse matching sends at the moment they are sent").
- Moderation tooling in `secretmsg-private` (report verification status, disclosed-content retention jobs).

### 3.4 Suggested sequencing

1. Crypto foundations behind flags: envelope format, key generation/storage, escrow, recovery UX.
2. Publish recipient key sets; web send-path encryption; claim-link fragment keys for replies.
3. App inbox decrypt; encrypt the local cache and outbox; remove server preview from FCM.
4. Reporting: metadata-only first, then verified content disclosure and moderation tooling; purge legacy plaintext per the migration policy.
5. Move hidden words to the recipient client; ship the copy changes in the same release; stop using the server filtered tray for new messages.
6. Ship the classifier (deterministic baseline bundled, ML bundles downloaded); release-gate evals.
7. Ship auto-translation; language set and download UX.
8. Transparency deliverables: "what the service can see," key fingerprints, model cards.
