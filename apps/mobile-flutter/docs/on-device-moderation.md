# On-device moderation and auto-translation (Flutter client)

Status: engineering change on `feat/1.8` · Scope: `apps/mobile-flutter` only ·
Server stays ciphertext-only for message bodies.

This document is the companion to the code in
`apps/mobile-flutter/lib/moderation/`. It states what is real, what is a stub,
what a reviewer must verify on a physical device, and why the pipeline has a
fixed order.

---

## 0. The honest summary first

**What is real (implemented and tested here):**

- The fixed pipeline `decrypt -> normalize -> deterministic hidden-words ->
  classifier -> translation -> render` with stage tracing.
- Deterministic hidden-word matching, resistant to case tricks, zero-width
  injection, combining-mark injection, cross-script lookalikes, separator
  insertion, repeated characters and common digit leet. Matching runs against
  the authoritative Unicode UTS #39 confusables data plus an NFKD fold table,
  both regenerable from `tool/moderation/`.
- Sensitivity semantics for `off` / `standard` / `strict`, wire-compatible
  with the existing server field.
- Signed model-bundle delivery: manifest schema, SHA-256 payload digest,
  ES256 (P-256/SHA-256) detached signature verification against pinned keys,
  app-private storage with atomic activation, versioning, staged rollout
  decisions and pointer-only rollback.
- An HTTPS bundle source that uses `package:http` directly, with no Play
  Services, no auth token and no account identifier.
- Deterministic tests for the normalize/fold/homoglyph stage, matcher, pipeline
  ordering, bundle verification, store/rollback and the translation handoff.

**What is stubbed (loudly):**

- **No toxicity model ships.** `UnavailableToxicityClassifier` is wired by
  default. It reports `modelUnavailable` for every message; it never guesses.
  The pipeline treats that as *not checked*, badges it, and holds in `strict`.
  Do not describe the app as "AI-moderated" until real weights ship and pass
  the release gates in §4.
- **No translation model ships.** `UnavailableTranslator` is wired by default.
  Cross-script messages show "translation unavailable"; nothing is sent
  anywhere.
- **No language-identification model ships.** Only script detection
  (`und-Latn`, `und-Cyrl`, ...) exists. Same-script translation cannot be
  triggered yet, and the app says nothing rather than guessing.
- **No background downloader/UI yet.** The verified install path is complete
  and tested; download scheduling (Wi-Fi preference, resume, size prompt) is a
  follow-up because it needs product UI outside this change.

**What is deliberately not done here:** wiring into `lib/screens/**`. That
surface is owned by parallel work; §7 lists exactly where the pipeline plugs
in.

---

## 1. Governing model

- Message bodies and replies are end-to-end encrypted; the server cannot read
  them. Metadata stays server-visible.
- Moderation therefore runs **on the recipient's device, against plaintext,
  after envelope verification and decryption**, immediately before render.
- The server's old hidden-word enforcement and compose-time refusal are
  replaced by this recipient-side stage. A sender is no longer refused at
  compose time (that would require publishing a dictionary-testable
  representation of the recipient's list).
- **Client-side filtering is bypassable by a modified client.** A patched app
  can skip the pipeline, read anything its device can decrypt, and export it.
  This is weaker than the server-side enforcement it replaces. It is a
  protection for the ordinary user, not an enforcement boundary. This is said
  in `user_copy.dart`, and it must be said wherever the feature is described
  to users.

---

## 2. The fixed pipeline and why the order cannot move

```
decrypt -> normalize -> deterministic hidden-words -> classifier
        -> translation -> render
```

`ModerationPipeline.process` executes exactly these stages and records every
executed stage in `ModerationOutcome.executedStages`, so tests can prove the
order (see `test/moderation/pipeline_test.dart`).

Why fixed:

1. **Decrypt first, and only plaintext.** Stages are defined against a
   `MessageDecryptor`; on failure the pipeline throws `DecryptionFailure` and
   nothing renders. No stage can run on ciphertext by accident.
2. **Normalize once, before matching.** One pass produces the display text
   (bidi controls removed) and the matching forms (`folded`, `skeleton`,
   `compact`). If the matcher had its own normalization, the matcher and the
   renderer could disagree about what the message says — the classic
   filter-evasion bug.
3. **The deterministic stage always runs and is not skippable.** It is first
   after decrypt, costs microseconds, and has no model dependency. Sensitivity
   `off` disables *enforcement* (no hold), not the check: enforcement is a UI
   policy, the check is the safety mechanism. A probabilistic model must never
   be the first line of defence.
4. **Classifier after the deterministic stage, before translation.** A message
   held by either stage never reaches translation, so **no translation is
   produced for text that will be blocked** — that is the reason translation
   sits after the classifier, not before rendering. The classifier also runs
   on the original text, not on a translation that may have lost or added
   meaning.
5. **The one sanctioned re-check.** If the classifier does not support the
   original language and a translation exists, the pipeline may run the
   classifier again on the translation, labelled
   `ClassifierInput.translation`. The stage trace then contains `classifier`
   twice; that is intentional and visible to tests, not a reordering.
6. **Render last, from the outcome only.** `ModerationOutcome` is data: hold
   state, reveal steps, reasons, badges, display text. The UI never re-reads
   the envelope, and held text is not drawn until the user completes
   `revealSteps` deliberate actions.

---

## 3. Deterministic hidden-words stage (the evasion-resistant part)

Files: `text/text_normalizer.dart`, `text/hidden_words.dart`,
`text/confusables.dart`, generated tables
`text/unicode_fold_table.g.dart` (1744 entries, from CPython UCD 15.1.0) and
`text/confusables_table.g.dart` (1118 entries, from Unicode UTS #39
confusables.txt 18.0.0). Both are regenerable:

```
curl -sSLo /tmp/confusables.txt \
    https://www.unicode.org/Public/security/latest/confusables.txt
python3 tool/moderation/generate_unicode_fold_table.py
python3 tool/moderation/generate_confusables_table.py /tmp/confusables.txt
```

### 3.1 Normalization

One pass over code points produces four views:

| View | Contains | Used for |
|---|---|---|
| `display` | original text with bidi controls removed; emoji joiners and variation selectors kept | rendering |
| `folded` | case-folded; NFKD compatibility fold; UTS #39 lookalike fold; zero-width/format/variation/tag characters and universal combining marks removed | exact matching (emoji, non-Latin) |
| `skeleton` | `folded` with punctuation/symbols collapsed to single spaces | short-entry token matching |
| `compact` | symbol substitution fold (`@`->a, `$`->s, `!`->i, `|`->l) then remove every non `[a-z0-9]` | main substring match |

Table policy:

- The UTS #39 table is restricted to **non-ASCII sources**. The raw file also
  encodes leet substitutions (`1 -> l`, `0 -> O`) and identifier folds
  (`m -> rn`) that would mangle ordinary text; digit leet is handled by
  bounded wordlist variant expansion instead.
- Sources already covered by the NFKD fold are dropped from the confusables
  table so precedence is trivial: confusables, then NFKD, then leave the
  character alone.
- Script-specific vowel signs and tone marks (Indic, Arabic, Hebrew, Thai,
  Japanese) are **not** stripped: they are letters, not evasion, and removing
  them would collide distinct words. Universal combining diacritics
  (U+0300–U+036F and four other international ranges) are stripped.

### 3.2 Matching semantics (`HiddenWordsMatchMode.evasionResistant`)

The recipient's list entries are normalized by the same pass, then:

- Entries with a compact form of 3+ characters match as a **substring of the
  compact message**. `s p a m`, `s.p.a.m`, `s\u200Bp\u200Bam`, `spаm`
  (Cyrillic а) and fullwidth `ｓｐａｍ` all collapse to the same string.
- Each character allows repetition in the message (`spaaam`) but the match
  must be at least as long as the entry, so `as` does not satisfy `ass`.
- Entries shorter than 3 compact characters match **whole tokens** in the
  skeleton, so a one-letter entry cannot match every message.
- Entries with no compact form (emoji-only, emoji sequences, CJK words) match
  as an exact substring of the folded form, with zero-width injection removed.
- Digit leet is handled on the wordlist side, capped at 64 deterministic
  variants per entry: `spam` -> `5pam`, `love` -> `l0ve`, `test` -> `t3st`,
  `ass` -> `a55`. Symbol leet (`a$$`, `b!tch`) is folded on the text side.

`plainSubstring` mode reproduces the legacy closest equivalent (case/lookalike
containment without separator or repetition tolerance) and exists so the
behavior change is auditable in tests.

### 3.3 Known limits (documented, not hidden)

- **False positives:** substring semantics mean `ass` matches `class`, exactly
  as the old containment check did. Reveal is one tap and never punishes the
  user.
- **False positives:** separator blindness can bridge word gaps (`if u ck`
  compacts to a match). This is the deliberate price of not letting attackers
  split words; the alternative (word-start-only matching) lets a prefixed
  letter evade.
- **False negatives:** UTS #39 does not give ASCII skeletons for every
  lookalike. Latin `ð` (maps to ∂ + overlay), Cyrillic `и`, `к`, `т`, `м` and
  Greek `κ`, `τ` are *not* folded and are caught only when the recipient lists
  the exact lookalike spelling. `ł`/`ø`/`đ`/`ħ`/`ŋ`/`þ` and fullwidth,
  mathematical, circled, superscript and precomposed-diacritic forms **are**
  folded.
- **Not full NFC.** `TextNormalizer` is stronger than NFC for matching
  (marks stripped) but the display form preserves the sender's original
  characters minus bidi controls. A future translation model that requires
  precomposed input needs its own normalization step inside the translation
  stage.
- **No intent understanding.** Deterministic matching cannot see context:
  quotes, reclaimed language, satire and code-switching will surface false
  positives; the classifier (once real) is the layer for that.

### 3.4 Sensitivity mapping

| Setting | Hidden-word hit | Classifier flag | Model/target language unavailable |
|---|---|---|---|
| `off` | no hold; stage still runs | classifier not run | no hold |
| `standard` | hold, 1 reveal step | hold, 1 reveal step | allowed with an explicit badge |
| `strict` | hold, 2 reveal steps | hold, 2 reveal steps | hold, 2 reveal steps (documented trade-off on devices that never install a model) |

Held messages appear only in the local filtered view; there is no server tray
for new E2E messages and no automatic report, block, delete or server record.

---

## 4. Toxicity classifier

### 4.1 Interface (real)

`classifier/toxicity_classifier.dart` defines `ToxicityClassifier`,
`ClassifierResult`, `ToxicityLabel` (harassment, hate, sexual, violentThreat,
selfHarm, spamScam), `ClassifierAvailability`
(`checked` / `modelUnavailable` / `languageUnsupported`),
`ClassifierInput` (`original` / `translation`) and per-category
`ToxicityThresholds`.

### 4.2 Shipped implementation (stub — read this twice)

`UnavailableToxicityClassifier` reports `modelUnavailable` for every message.
It is **not moderation**. `standard` shows messages with an
"AI check unavailable" badge; `strict` holds them until a model is installed.
The UI must never present unchecked content as "clean" (the pipeline returns
`classifierChecked: false`, and no copy in `user_copy.dart` claims otherwise).

### 4.3 Target model and budgets (design targets, not measured facts)

The intended production classifier is a quantized multilingual text
classifier of the compact-BERT class:

- ~25–40 M parameters, int8 quantized, **≤ 35 MB per model file**.
- Executed in a background isolate on CPU; no Play Services, no network.
- Latency target **p95 ≤ 250 ms** for a 500-character message on the
  reference mid-tier device (4 GB RAM, Android 10-class, 2021-era SoC).
- Memory target **≤ 120 MB added peak RSS**; classification is one window per
  message at the current 500-character cap (`kMaxMessageLength`), chunking
  only if the cap grows.
- Output is label + score per category; thresholds are tuned per category and
  per language, never globally.

These numbers come from the design brief. **No on-device benchmark has been
run because no weights ship in this change**; they are acceptance criteria for
the model drop, and the reviewer checklist in §11 includes measuring them.

### 4.4 Release gates before any model is enabled

- Held-out multilingual eval: recall ≥ 0.85 for top-severity categories
  (violent threat, self-harm, sexual content involving minors) and false
  positive rate ≤ 5% at the default threshold, reported per language.
- A model card documenting slang, reclaimed language, quotes, satire and
  code-switching failure modes.
- Signed bundle through the §5 pipeline, with a rollback plan.

Until then the app keeps deterministic filtering only and says so.

---

## 5. Model delivery (signed bundles, de-Googled track)

Files: `delivery/model_manifest.dart`, `delivery/bundle_verifier.dart`,
`delivery/bundle_store.dart`, `delivery/rollout_policy.dart`,
`delivery/bundle_source.dart`; crypto in `crypto/sha256.dart` and
`crypto/p256_ecdsa.dart`.

### 5.1 Bundle format

```
<base>/<kind>/<model_id>/<version>/manifest.json
<base>/<kind>/<model_id>/<version>/manifest.sig
<base>/<kind>/<model_id>/<version>/<payload_file>
```

`manifest.json` (schema 1):

```json
{
  "schema": 1,
  "kind": "toxicity_classifier | translation | language_id",
  "model_id": "toxicity-multilingual-tiny",
  "version": "1.2.0",
  "language": "mul",
  "payload_file": "model.tflite",
  "payload_size": 1234567,
  "payload_sha256": "<64 lowercase hex>",
  "min_app_version": "1.8.0",
  "signing_key_id": "secretmsg-model-signing-2026-1",
  "description": "optional"
}
```

`manifest.sig` is a detached **ES256** signature (NIST P-256 + SHA-256) over
the exact `manifest.json` bytes, base64url-encoded as raw 64-byte `r || s`.

### 5.2 Verification (fail closed)

`BundleVerifier` checks, in order: manifest parses; schema supported; kind
supported; payload file name is a safe bare name; `min_app_version` satisfied;
signature verifies under a **pinned** key from the compiled-in key map;
payload size matches; SHA-256(payload) matches. Signature is checked before
hashing so a hostile large payload cannot burn CPU first. Any failure means
nothing is written and the previous active model stays in place.

The pinned key map is empty until production keys are provisioned; with an
empty map **every** bundle is rejected, which is the correct default. Key
rotation is a client release (pin the new key alongside the old).

### 5.3 Versioning, rollout, rollback

- `ModelRolloutPolicy` (server-published per kind): `preferred_version`,
  `minimum_supported_version`.
- `decideModelRollout` (pure, tested): no install -> install preferred; older
  -> install preferred; equal -> up to date; installed newer than preferred ->
  keep the newer install; below minimum -> stop using it (client update
  required). Rolling the preferred version backward never uninstalls or crashes
  a newer valid model.
- On disk: `<app-support>/models/<kind>/<model_id>/<version>/...` plus a
  per-kind `active.json` pointer written last via temp-file rename. Rollback
  only moves the pointer. `pruneOldVersions` keeps the active version plus the
  newest N non-active versions.

### 5.4 De-Googled / sideload track

`HttpModelBundleSource` uses `package:http` directly against first-party
HTTPS storage. It sends no auth token, no account identifier, no message text,
and has no Play Services or Firebase dependency; the same signed bundles are
served to both tracks. Download UX still pending (see §0): resumable transfer,
Wi-Fi preference, size display, and streaming the payload to disk with an
incremental digest instead of buffering (today the cap is enforced and the
buffered path is covered by tests; a 35 MB buffer is acceptable on mid-range
devices but streaming is the right final shape).

### 5.5 Why hand-rolled crypto

`crypto/sha256.dart` and `crypto/p256_ecdsa.dart` implement SHA-256 (FIPS
180-4) and P-256 ECDSA verification with `BigInt`, with no new dependency.
They exist because bundle verification must work without Play Services and the
app deliberately keeps its dependency set small. They are validated against
FIPS vectors and OpenSSL-generated ES256 signatures in
`test/moderation/crypto_test.dart` (accept, tampered message, flipped
signature bit, off-curve key, malformed input). They verify only — there is no
signing code in the app, and the private key never ships. This code has not
had an external audit; the test vectors are the current evidence.

---

## 6. Auto-translation

### 6.1 The hard rule

**No network translation API may receive message text.** Message bodies are
end-to-end encrypted; shipping plaintext, a translation, or a
content-derived query to a third-party service would defeat that promise.
`OnDeviceTranslator.translate` is the only seam the pipeline knows, and the
shipped implementation is `UnavailableTranslator`.

### 6.2 What is achievable on device, and what is not

Achievable, with signed on-device packs (not shipped here):

- Per-pair NMT models in the **30–90 MB** int8 range, downloaded on demand,
  Wi-Fi preferred, with size shown before download.
- Short-message translation (≤ 500 characters) within a sub-second budget on
  the mid-tier reference device; originals always preserved.
- Display contract: `translation + "Translated on this device" + "Show
  original"`; a failed translation shows the original with an explicit badge,
  never a partial sentence.

Not achievable now, and not claimed:

- Universal coverage. Packs are per language pair; low-resource languages
  will not be available at launch.
- Same-script translation without a language-ID model. The only identifier
  shipped is script detection; English vs Spanish is invisible to it, so the
  pipeline does not attempt same-script translation. This is why translation
  coverage today is effectively "cross-script pairs, once a pack exists".
- Translation of held content. By construction, held messages never reach the
  translation stage.
- Machine translation of emoji/CJK mixed text without a dedicated model; the
  pipeline passes the original display text to the translator and lets the
  model decide, but no model ships.

### 6.3 Language identification honesty

`ScriptHeuristicLanguageIdentifier` returns `und-<Script>` tags (`und-Latn`,
`und-Cyrl`, `und-Hani`, ...) with the dominant-script share as confidence, or
`unknown` when no script reaches 60%. It never guesses a language, and the
pipeline never calls off-device to find out. A real per-language ID model is
a separate signed bundle in `language_id` kind, evaluated like any other.

### 6.4 Fonts

If translation introduces scripts the app cannot render, the only permitted
families are Google Fonts, with Noto as the safe default for script coverage.
This change adds no fonts; the app continues to use Inter plus system script
fallback. Rendering of translated RTL/CJK text must be checked on device
(§11).

---

## 7. Integration status

The pipeline is implemented and tested but **not wired into `lib/screens/**`
yet** (that surface is owned by parallel work). Wiring points:

- Inbox load/decrypt path: after envelope decrypt, call
  `ModerationPipeline.process(envelope, userLanguage: ..., sensitivity: ...,
  translationEnabled: ...)`, then render from the returned
  `ModerationOutcome` (`executedStages`, `held`, `revealSteps`, `reasons`,
  `badges`, `displayText`).
- Settings: build `ModerationSensitivity.parse(user.modSensitivity)` and pass
  the user's `hiddenWords` via `pipeline.updateHiddenWords(...)`.
- Copy: use `ModerationCopy` for labels and the bypass/probabilistic notices.
- The repo also contains a send-side compose-time check
  (`lib/crypto/filtered_words.dart`, owned by the E2E work). It is advisory:
  a modified sender can skip it, and it exposes the recipient's list to
  senders. The recipient-side stage documented here is the display authority
  for text the server cannot read. The reviewer should confirm the product
  intent that both exist in 1.8 and that copy does not present the send-side
  check as a guarantee.

---

## 8. Privacy, ads and analytics boundaries

- No analytics SDK is added, and none may be added for these features. Any
  future quality feedback must be explicit, content-free, default-off and
  disclosed.
- Message text, translations and classifier labels are never sent to the
  server, ad SDKs, or any network service. Labels and translations are
  local-only; the ad layer is not passed message-derived fields (the ads
  boundary test belongs to the integration change).
- Model manifests and payloads contain no user data.
- Local labels/translations follow local message deletion and account wipe
  policy (integration work).

---

## 9. Tests and how to run them

```
cd apps/mobile-flutter
flutter analyze
flutter test
```

This change adds 100 tests under `test/moderation/`:

| File | Covers |
|---|---|
| `text_normalizer_test.dart` | case/compat/lookalike folding, zero-width, combining marks, bidi, whitespace, emoji/ZWJ, script-specific marks |
| `hidden_words_test.dart` | every evasion class and its limits, short/emoji/non-Latin entries, parity mode, dedupe |
| `pipeline_test.dart` | fixed order, short-circuit rules, sensitivity matrix, translation gating, post-translation re-check, bidi badge |
| `crypto_test.dart` | SHA-256 FIPS vectors + streaming; P-256 against OpenSSL vectors, tamper/off-curve/malformed rejection |
| `bundle_test.dart` | signed accept, every rejection reason, rollout/rollback semantics, atomic store, staging install, HTTPS source |
| `translation_test.dart` | script heuristic, language->script map, honest unavailable translator |

The baseline 162 tests and the parallel E2E test files all pass alongside
these (311 total at the time of writing).

---

## 10. What a reviewer must check on a physical device

1. **Performance with real models** (once they exist): p95 classifier ≤ 250 ms
   and translation ≤ 900 ms for 500-character messages, ≤ 120 MB peak RSS,
   and no main-thread frame over 16 ms. Today only the deterministic stage can
   be benchmarked, and it is microseconds.
2. **Strict-mode first run with no network**: messages are held with
   "Held: this device has no AI content check installed yet"; the filtered
   view still offers the deliberate two-step reveal. Confirm the product
   accepts this state on a device that can never install a model.
3. **Zero content egress**: on an airplane-mode device, decrypt, hidden-word
   holds and (with a test pack) translation all work; with a proxy/network
   capture, no message text, translation or label appears in any request.
   Bundle downloads contain only signed model files.
4. **De-Googled sideload build**: install a bundle from the first-party CDN on
   a device with no Play Services; verify a corrupted bundle is rejected with
   "update postponed" and the previous version keeps working; verify a signing
   key rotation requires an app update.
5. **Unicode rendering and accessibility**: RTL, CJK, emoji ZWJ sequences and
   combining marks render as sent; TalkBack announces the held state without
   reading held text before reveal; translation toggle reachable; fonts are
   Google Fonts only if new script coverage is added.
6. **Notification hygiene**: held content must not leak through lock-screen
   previews or notification text. The push-preview work (parallel) and this
   pipeline must be checked together.
7. **No automatic consequences**: flag/hold a message, then diff server rows
   to prove no report, block, deletion or server-side record was created.
8. **Reveal flow**: one tap in `standard`, two deliberate steps in `strict`;
   reveal is per-message, never bulk, and does not change server state.

---

## 11. Files owned by this change

```
lib/moderation/**                     (new)
test/moderation/**                    (new)
tool/moderation/**                    (new; table generators)
docs/on-device-moderation.md          (this file)
```

No file under `lib/screens/**`, `lib/theme.dart`, or
`/opt/secretmsg/secretmsg-private` is touched. The generated data tables are
the only large files; they are deterministic output of the scripts above.
