# On-device model recommendations — SecretMsg Flutter client

Feature area: `apps/mobile-flutter/lib/moderation/` (toxicity classifier + auto-translation)
Researched: 2026-10-08. Method: primary sources only (model registries, model cards, licence
files, vendor docs, live file listings). Every size quoted below is an exact file size from a
registry/model repository, except where marked "computed" or "unverified".

**No device benchmark was run.** Every latency/RAM statement is an estimate with its
assumptions stated. The project's own docs say the same about its targets
(`docs/on-device-moderation.md` §4.3, §10).

**Scope note on budgets:** the brief's "p95 ≤ 250 ms, ≤ 120 MB RSS" is the *classifier*
budget. The same doc gives translation its own budget of **≤ 900 ms** for 500-character
messages and the same 120 MB added-RSS target (docs §10.1). This report uses those numbers.

---

## TL;DR

| Feature | Recommendation | One-line caveat |
|---|---|---|
| Toxicity classifier | **gravitee-io/bert-small-toxicity** (28.8 M params, 29.1 MB int8 ONNX, OpenRAIL++-M) — but only with an interface/copy change, as a **single-label abuse pre-screen**, not as the six-category classifier in the brief | It is binary ("toxic"/"not-toxic"), 15 languages with published F1 dropping to 0.56 for Hebrew, and no candidate at ≤ 35 MB covers the six categories. |
| Translation | **Mozilla Firefox Translations (Bergamot) models** (17.1–59.5 MB int8 per direction, MPL-2.0) run by **bergamot-translator** | Genuinely offline (proven in Firefox Android), but no Flutter package exists, each pack is 2–3 files while the bundle manifest supports one payload, and MPL-2.0 is file-level copyleft requiring legal sign-off. |

**The one honest "no good option" finding:** for the classifier's actual brief — six
categories, multilingual, ≤ 35 MB int8, commercial licence, ≥ 0.85 recall on top-severity
categories at ≤ 5 % FPR — **no downloadable model exists today**. The closest fully
multilingual six/seven-label models (Horizon-Labs, unitary, CitizenLab) are 125–308 M
params and 140–270 MB int8. Shipping one of them means giving up either the size budget or
the 120 MB RSS budget. The real fix is a fine-tune/distillation project (§1.5), which the
interim gravitee model buys time for.

---

## 0. What the code actually demands (shape of the fit)

From `lib/moderation/classifier/toxicity_classifier.dart` and `translation/translator.dart`:

**ToxicityClassifier**

- `Set<String> supportedLanguagePrefixes` — a model must declare which languages it claims,
  and must return `ClassifierAvailability.languageUnsupported` rather than guessing.
- `classify(text, languageTag) -> ClassifierResult` with **per-category scores** for
  `harassment, hate, sexual, violentThreat, selfHarm, spamScam` and per-category thresholds.
- `warmUp()`, `dispose()`, `modelId`, `modelVersion`. Background isolate, CPU, no network.
- Design target: ~25–40 M params, int8, ≤ 35 MB per file, every language prefix it claims
  must be evaluated, thresholds tuned per language.

**OnDeviceTranslator**

- `supportedSourceLanguages` / `supportedTargetLanguages` (per-pair packs), `hasAnyModel`,
  `translate(text, sourceLanguage, targetLanguage)`.
- Result statuses: `translated / notNeeded / modelUnavailable / unsupportedPair / failed` —
  a failed translation must return the original, never a partial sentence.
- Pack metadata carries `downloadBytes` shown before download.

**Bundle manifest** (`delivery/model_manifest.dart`): one `payload_file` per bundle with
`payload_size` + SHA-256, kinds `toxicity_classifier | translation | language_id`. Important
consequence found during research: **both recommended model families need 2–3 files**
(weights + vocabulary + optional shortlist/tokenizer). Either tar the pack into one payload
or extend the schema — see §4.

---

## 1. Toxicity classifier

### 1.1 Constraint map (all five hard constraints applied)

| Constraint | What it eliminates |
|---|---|
| Offline / no network at inference | Perspective API, Jigsaw-hosted endpoints, "Detoxify API", any hosted inference |
| No Google Play Services | Play-Services-backed ML Kit APIs; anything that fetches weights via GMS |
| Commercial closed-source licence | CC-BY-NC models (NLLB family), research-only releases, AGPL model weights, "no licence given" checkpoints |
| Mid-range phone | Everything above roughly 35–45 M params int8 for the classifier budget |
| p95 ≤ 250 ms, ≤ 120 MB RSS | Large transformer guards (Llama Guard, Granite Guardian, ShieldGemma, Qwen guard variants — all 1 B+ params) |

### 1.2 Candidates

All sizes below are exact file sizes from the Hugging Face API file listings, retrieved
2026-10-08.

| # | Model | Publisher | Licence | Params | int8 artefact | I/O | Android runtime | Maturity |
|---|---|---|---|---|---|---|---|---|
| 1 | **gravitee-io/bert-small-toxicity** | Gravitee.io | CreativeML Open RAIL++-M (commercial OK, use-restricted, not OSI) | 28.8 M | **29.1 MB** `model.quant.onnx` (fp32: 115.1 MB) | WordPiece ids + attention mask → 1 sigmoid logit (binary) | ONNX Runtime Mobile (MIT AAR); TFLite after conversion via `tflite_flutter` | Published May 2025; 2.7 k downloads/mo; per-language eval table; no independent eval |
| 2 | **gravitee-io/bert-mini-toxicity** | Gravitee.io | CreativeML Open RAIL++-M | 11.2 M | **11.4 MB** `model.quant.onnx` (fp32: 44.7 MB) | Same (binary) | Same | Same family; lower quality expected (card not reviewed in depth) |
| 3 | **KoalaAI/Text-Moderation** | Koala AI | CodeML OpenRAIL-M 0.1 (commercial OK, use-restricted) | ≈139 M | **143.0 MB** `model_int8.onnx` (q4f16: 136.4 MB; fp32: 556.8 MB) | DeBERTa WordPiece → 9-class softmax (OK, S, H, V, HR, SH, S3, H2, V2) | ONNX Runtime Mobile | 31 k downloads/mo, 99 likes; validation macro-F1 **0.326**; English-only |
| 4 | **Horizon-Labs/multilingual-toxicity-small** | Horizon Labs | **Apache-2.0** | 141 M | **268 MB** int8 ONNX (fp32: 562.6 MB) | mmBERT tokenizer → 7 sigmoid labels (Detoxify taxonomy) | ONNX Runtime Mobile | Released 2026-10-01, 59 downloads; best published multilingual evidence, no independent eval |
| 5 | **textdetox/xlmr-large-toxicity-classifier-v2** | TextDetox / PAN 2024 (academic) | OpenRAIL++ | 560 M | ≈560 MB (computed) | XLM-R SentencePiece → 1 sigmoid logit (binary) | ONNX/CTranslate2 — desktop-class only | In-domain TextDetox F1 0.878 / AUC 0.922; quality ceiling reference, unusable size |

Reference point: `unitary/unbiased-toxic-roberta` (125 M, Apache-2.0, English, 7 labels,
Civil Comments AUC 0.985 as published by Horizon-Labs) — the best-licensed multi-label
option, but 125 MB int8, so it fails the file and RSS budgets by ~4×. `s-nlp/roberta_toxicity_classifier`
(125 M, OpenRAIL++, binary, English) fails the same way.

### 1.3 The category-mapping problem (read this before comparing scores)

The interface wants six scores. What each candidate can actually produce:

| App label | KoalaAI | Horizon-Labs (Detoxify) | gravitee / textdetox |
|---|---|---|---|
| harassment | HR | insult, toxicity | toxic |
| hate | H, H2 | identity_attack | toxic (weak proxy) |
| sexual | S, S3 | sexual_explicit, obscene | — |
| violentThreat | V, V2 | threat | toxic (weak proxy) |
| selfHarm | SH | — | — |
| spamScam | — | — | — |

No candidate covers all six. The binary models collapse everything into one score. If the
app reports only a `harassment` score from a binary model and leaves the other five at
zero, `ClassifierResult.wasChecked` will be true and the UI will imply six categories were
checked — a dishonest state the pipeline cannot currently express. **This is a code change,
not a model choice:** either add per-label availability to `ClassifierResult`, or train the
six-head model described in §1.5. Note the existing `languageUnsupported` enum is the right
pattern to copy.

### 1.4 Recommendation (toxicity)

**If a model must ship this cycle: gravitee-io/bert-small-toxicity, as a single-label
abuse pre-screen only**, with:

1. Copy/UI that says "abuse check" and not "AI content check for six categories"; only the
   one label it produces is flagged; everything else stays explicitly unchecked.
2. A hard-coded language allowlist of the pairs with published F1 ≥ 0.80 (en, fr, ru, hi,
   de, uk, tt, it, es — note it/es only marginally) and `languageUnsupported` for the rest
   (he 0.57, zh 0.62, ar 0.69, am 0.63, ja 0.73 are not good enough for a precision-first
   feature).
3. Reviewer-measured thresholds; do not adopt the card's implied 0.5.

Why this one: it is the only candidate that simultaneously (a) fits ≤ 35 MB int8 (29.1 MB
exact), (b) stays comfortably inside 120 MB RSS on paper, (c) has 15-language evidence and
a commercial-use licence, and (d) can plausibly hit p95 ≤ 250 ms — a 4-layer/512-hidden
BERT over ≤ 128 tokens of int8 ONNX on a 2021 mid-range SoC is low tens of milliseconds
(estimate, not measured). Its base is Apache-2.0 `prajjwal1/bert-small`.

**What it does badly:**

- **Binary, not six-category.** Cannot meet the release gates for violentThreat/selfHarm/sexual
  as written. `spamScam` is not addressed by anything on the market at this size.
- **Uneven languages.** F1 0.56 (he) to 0.96 (en), from an English-pretrained backbone
  fine-tuned on translated PAN/TextDetox data. Low-resource languages will be both missing
  abuse and, at a lowered threshold, inventing it.
- **No published precision/FPR, no slices for quotes, reclaimed language, AAVE, sarcasm,
  banter, or code-switching.** The card has no ethics section at all. F1 alone cannot tell
  you which way it errs at your operating point.
- **Benchmark provenance.** TextDetox/PAN corpora are single-sentence, largely machine
  translated from/to English; label judgements are English-annotator judgements carried
  across languages (the same weakness Horizon-Labs documents for its own data).
- **The whole family is new and unvetted.** 0–1 likes, one vendor, no third-party
  reproduction; treat the numbers as vendor claims.
- **File-size anomaly in the smallest sibling:** `gravitee-io/bert-tiny-toxicity`'s
  `model.quant.onnx` is 29.0 MB while its fp32 is 17.5 MB — the "quantized" file is bigger
  than fp32, which suggests a packaging mistake. Do not use bert-tiny without re-exporting
  it yourself.

**If the six-category brief is non-negotiable: there is no good off-the-shelf option at
this size, and the honest answer is not to ship a classifier yet.** Keep
`UnavailableToxicityClassifier`/`modelUnavailable` semantics (the app already handles this
state). Do not dress the binary model up as six-category coverage.

### 1.5 What to actually build (the real deliverable)

Evidence-based path to the brief:

1. **Base:** an Apache-2.0 compact multilingual encoder. `jhu-clsp/mmBERT-small`
   (141 M, the base Horizon-Labs used) is the best-documented modern option; a
   multilingual fine-tune of a bert-small/mini-class student is the size-viable option —
   gravitee's own results show an 11–29 M student can reach F1 0.82–0.96 in several
   languages after cross-lingual fine-tuning.
2. **Heads:** six sigmoid outputs, not softmax — the categories are not mutually exclusive
   (a violent threat can also be hateful).
3. **Data:** Civil Comments (CC0) + translated comment data + real in-domain message
   samples with slice labels (AAVE, reclaimed, quoted, sarcasm, banter, Hinglish, etc.).
4. **Ship size:** distill and quantize to ≤ 35 MB; the 141 M base will not fit — a ≤ 30 M
   student is required and its quality loss is the central engineering risk.
5. **Do not** fine-tune on outputs of a proprietary moderation API (the KoalaAI approach);
   it muddies training-data rights and bakes in that API's biases.

### 1.6 Toxicity: reviewer measurements on a real device

1. **Latency/RSS:** p95 for 500-char input, cold and warm, in the isolate, on the reference
   device; RSS delta and after 100 classifications (check for leaks from session
   release). Verify no main-thread frame > 16 ms.
2. **Precision-first curves:** per-language PR curves at the chosen threshold. Gate: FPR
   ≤ 5 % **and** recall ≥ 0.85 on violentThreat / self-harm / sexual-minors *if* those
   labels exist. For the interim binary model, measure FPR on innocuous banter first —
   because a false positive costs a real message.
3. **Slice tests, per language:** quoted speech ("he called me a X"), reclaimed in-group
   use, AAVE dialect markers (Jigsaw/Civil-Comments-derived models are documented in the
   literature to over-flag them), sarcasm and indirect abuse, consensual banter, romanised
   code-switching (Hinglish), emoji-only, single-word messages.
4. **Normalizer interaction:** the pipeline feeds `normalized.display` (bidi stripped, not
   NFKD-normalised). Confirm the model's WordPiece/other tokenizer behaves on that exact
   input; the docs already warn a translation model needs its own normalisation — the
   classifier needs the same check.
5. **Zero egress:** airplane mode + proxy capture during install, warm-up and classification.
6. **Bundle integrity:** SHA-256 of the exact `.onnx` pinned in the signed manifest; run the
   corrupted-bundle rejection path.
7. **Runtime ops:** confirm every op in the ONNX graph is in ONNX Runtime Mobile's operator
   set (or the TFLite conversion's op set), and that the int8 file does dynamic-range
   quantisation the mobile build supports. This is the most likely silent failure.

---

## 2. Auto-translation

### 2.1 The local-only test (the brief asks explicitly)

| Candidate | Is inference genuinely local? | Detail |
|---|---|---|
| Mozilla Firefox Translations / Bergamot | **Yes** | intgemm8 models on disk, `bergamot-translator` C++/wasm, no network. Ships in Firefox; registry carries `Release Android` statuses. |
| Helsinki-NLP OPUS-MT | **Yes** | Plain Marian checkpoints you host; CTranslate2/ORT inference. |
| Google ML Kit On-Device Translation | **Yes at inference, no at delivery** | Runs locally, but models are **dynamically downloaded through Google Play Services**; Google's own install-path table lists Translation as dynamic-only (no bundled option). Excluded for the sideload build; **there is no non-Play variant.** |
| Meta NLLB-200-distilled-600M | Yes | But licence excludes it (§2.3). |
| Google TranslateGemma 4B-it | Yes | But 4 B params; own-hosted GGUF/int4. |

Also excluded without a table row: Android's `TranslationService` system API (Android 12+)
— a system-provided provider, in practice Play-Services/OEM backed, opaque locality, absent
on de-Googled devices; and any "translate" Flutter package that calls a network endpoint
(the failure mode the brief warns about — always check for an HTTP client in the package).

### 2.2 Candidates

Sizes are exact from Mozilla's live model registry (generated 2026-10-08) and Hugging Face
file listings. "Per direction" matters: en→fr and fr→en are two separate files.

| # | Model | Publisher | Licence | Params / size (int8) | I/O | Android runtime | Maturity |
|---|---|---|---|---|---|---|---|
| 1 | **Firefox Translations (Bergamot) models** | Mozilla (trained with Edinburgh/Bergamot; models via `mozilla/translations`) | **MPL-2.0** (README: "model files are distributed under the MPL 2.0 license") | tiny: 16.9 M / **17.1 MB**; base-memory: 31.2 M / **31.6 MB** (some pairs 43.5 M / 43.8 MB); base: 42.7 M / 43.0–59.5 MB, per direction | raw text in → raw text out (SentencePiece internal); pack = weights + vocab (.spm) + optional lexical shortlist | `bergamot-translator` (MPL-2.0): native C++ (NDK/JNI or Dart FFI) or wasm-in-WebView; **no Flutter package exists** | Production: powers Firefox 118+; registry has 113 released directions across 60 languages; live updates |
| 2 | **Helsinki-NLP OPUS-MT** | University of Helsinki | Apache-2.0 on the card checked (`opus-mt-en-es`); licences vary per pair — verify each | ≈78 M / ≈78 MB int8 (computed from 312.1 MB fp32) | raw text in → raw text out; SentencePiece spm32k | CTranslate2 (MIT), ONNX Runtime, or Marian; no mobile packaging | Huge, mature, community standard; desktop/server oriented |
| 3 | **Google ML Kit Translation** | Google | Proprietary SDK terms; attribution requirements | ~30 MB/pack (Google's numbers) | text → text | ML Kit SDK; **Play Services dynamic download only** | Mature, good quality (50+ languages, English-pivot for non-English pairs) — excluded on sideload |
| 4 | **Meta NLLB-200-distilled-600M** | Meta | **CC-BY-NC-4.0 + "research model, not released for production"** | 600 M / ≈600 MB int8 | text → text; 200 languages, one model | CTranslate2/ONNX; desktop-class | Mature research artefact — **legally excluded for a commercial app regardless of size** |
| 5 | **Google TranslateGemma 4B-it** | Google | Gemma licence (commercial use allowed with use restrictions; not OSI) | 4 B / ≈2.3–2.6 GB int4 | chat-formatted text → text; 55 languages | llama.cpp / MediaPipe LLM Inference | New (Jan 2026), well-liked — excluded on RAM/size/latency |

### 2.3 Recommendation (translation)

**Firefox Translations (Bergamot) models, little "tiny"/"base-memory" variants first,
with direct en↔target packs, run by `bergamot-translator`.**

Why:

- **Genuinely local, and proven on Android.** These are the only models in the comparison
  that ship in a mass-market Android app with fully offline inference; five directions are
  explicitly marked `Release Android` in the registry and the same format runs in the
  Firefox Android translation engine.
- **Fits the documented pack budget and beats it:** 17.1 MB (tiny) and 31.6–43.8 MB
  (base-memory) per direction against the brief's 30–90 MB int8.
- **Quality is published per direction:** FLORES-200 COMET 0.79 (en–hi tiny) to 0.90
  (en–ja) for released pairs; Mozilla's ship criterion is within ~5 % of Google Translate,
  and each model's FLORES numbers are in the registry so the app can pick pairs honestly.
- **Licence is uniform and commercial-compatible:** MPL-2.0 for code and model files.

**What it does badly:**

- **No universal coverage, by construction.** 113 released directions across 60 languages
  (overwhelmingly en-centric plus intra-European directions). No model means
  `unsupportedPair`, which the UI already handles.
- **Same-script messages remain untranslatable** until a real language-ID model ships —
  identical scripts are invisible to the shipped script heuristic (docs §6.2–6.3). This is
  a separate signed bundle (`language_id`), not a translation-model property.
- **Short, slangy, typo-ridden messages are out of domain.** Mozilla trains and evaluates
  on FLORES/news/dialogue sentences, not 12-word messages with abbreviations, emoji and
  profanity. Quality on exactly the app's text distribution is **unverified**.
- **MT can distort the meaning that matters most:** profanity is often neutralised and
  negation can flip; quoted, mixed-script and CJK/emoji text degrades. The pipeline's
  order (classifier on the original before translation) mitigates moderation impact, but
  the reader still sees the translation as the primary text.
- **Integration burden is the real cost.** No Flutter package exists. You must build
  `bergamot-translator` with the NDK and wrap it (FFI/JNI), or run its wasm build inside a
  WebView. The WebView route adds a large baseline RSS and carries the 16 ms-frame risk, so
  native FFI is the serious option. This is a multi-week native engineering item, not a
  pub.dev dependency.
- **MPL-2.0 is file-level copyleft.** Static-linking MPL C++ into a closed app is fine, but
  modifications to MPL-covered files must be published in source form; distributing the
  model files (MPL-2.0) obliges you to carry the licence and make source available. Get
  counsel to sign off on how that applies to binary weights — this is the main licence
  difference versus OPUS-MT's Apache-2.0.
- **The model repo moved.** `mozilla/firefox-translations-models` is archived (Dec 2025);
  the live pipeline and registry are `mozilla/translations` + the GCS registry. Pin the
  `uncompressedHash` and `uncompressedSize` from that registry into the signed manifest,
  and re-verify when Mozilla rotates files.

**Fallback if the native engine is judged too expensive and licences allow:** OPUS-MT via
CTranslate2 (Apache-2.0, more pair coverage, ~78 MB int8) — but it is heavier, not
mobile-tuned, and there is no evidence it meets 900 ms on the reference device. It is a
worse fit, offered only for licence flexibility.

**Explicitly rejected:** ML Kit (no non-Play variant for the sideload track), NLLB
(non-commercial + research-only), TranslateGemma 4B (RAM/latency), any network translation
package.

### 2.4 Translation: reviewer measurements on a real device

1. **Latency:** p95 for a 500-char message per direction, warm and cold (model load is
   seconds; it must be off the render path), on the reference 4 GB device. Target ≤ 900 ms
   per the project's own docs. Also cap intgemm threads so the UI isolate never misses a
   16 ms frame.
2. **RAM:** added peak RSS with 1 and 2 packs resident; verify ≤ 120 MB added. Memory is
   the reason to prefer native `base-memory`/`tiny` over the WebView spike.
3. **Quality on your distribution:** human or COMET evaluation on real message-like text —
   slang, abbreviations, typos, emoji, profanity, negation, mixed script — per pair. Do
   not rely on FLORES; it is the training/eval distribution, not the product's.
4. **Zero egress:** airplane mode + proxy capture; whole pipeline on a held message and a
   translated message; verify `bergamot-translator` has no telemetry and the app never
   resolves a translation host.
5. **Bundle mechanics:** multi-file pack (weights+vocab[+shortlist]) through
   `BundleVerifier` — currently `payload_file` is a single file (§4); corrupted-pack
   rejection; atomic activation and rollback with a translation pack; `downloadBytes`
   displayed must match the registry's `uncompressedSize`.
6. **Display contract:** "Translated on this device" + "Show original" present; RTL and CJK
   render correctly (render with the OS fallback; no new bundled font is required by this
   recommendation); failed run shows the original with the explicit failure badge, never a
   partial sentence.
7. **Ordering invariants:** held messages never reach the translator; the post-translation
   classifier re-check runs only for `languageUnsupported` originals and is labelled as
   checking the translation.

---

## 3. Other options considered and why they are out

| Option | Reason |
|---|---|
| ML Kit Language Identification | Play-Services or bundled; relevant only to the separate `language_id` gap (see §5) |
| Llama Guard 3/4 1B, Granite Guardian, ShieldGemma, Qwen guard | 1 B+ params; far past RAM/latency; some have non-OSI community licences |
| Perspective API / any hosted moderation | Network; forbidden by the E2E promise |
| Detoxify (library) | Apache-2.0 wrapper, but its models are 125–278 M uncompressed transformer weights — same size problem |
| NLLB / M2M-100 | CC-BY-NC (non-commercial) |
| Argos Translate | MIT code, but a Python/CTranslate2 desktop stack; packs are repackaged OPUS-MT; no Android runtime |
| Android `TranslationService` API | Provider-dependent, Play/OEM backed in practice, opaque; absent on de-Googled devices |

## 4. Integration findings that affect the model drop (from reading this repo)

1. **Manifest supports one payload file.** Bergamot packs need at least weights + vocab;
   ONNX classifier packs need the graph + vocab. Either wrap the pack in an archive and
   reference it as the single payload, or extend schema 1 to a payload list before
   production keys are provisioned.
2. **Tokenizers:** BERT WordPiece (vocab.txt, 30 k) is straightforward to port to Dart;
   Marian SentencePiece (.spm) is handled inside `bergamot-translator`, which is another
   point in its favour. Do not ship a model whose tokenizer you cannot reproduce exactly —
   wrong tokenization is a silent quality cliff.
3. **Partial coverage cannot be expressed today.** `ClassifierResult` has one availability
   for the whole model; per-label availability (or a documented single-label contract) is
   needed for every realistic candidate. The `languageUnsupported` path is the pattern to
   extend, and the post-translation re-check logic already exists.
4. **Strict mode with a partial model is dangerous.** In `strict`, `languageUnsupported`
   holds the message; with a 15-language model that is correct behaviour for unsupported
   languages but may surprise users. Decide product copy before shipping.
5. **Model version strings** (`modelId`/`modelVersion`) should match the signed manifest
   fields exactly so local labels can be audited against the deployed version.

## 5. Bonus: the language-ID gap blocks same-script translation

Not one of the two asked features, but it gates translation reach, and the docs already
reserve the `language_id` bundle kind. Candidate directions, all offline:

- **fastText language identification (`lid.176`, ~1–2 MB int8)** — fastText code is MIT;
  verify the model file's own terms before shipping.
- **CLD3** (Apache-2.0, code) — needs a model, narrow language set.
- **MediaPipe Tasks Language Detector** (Apache-2.0) — model ships in-app, no Play
  Services; verify on the sideload build.

A ~1–2 MB language-ID model is the cheapest way to make same-script packs reachable at all.

## 6. Sources (all retrieved 2026-10-08)

- Project docs and code: `apps/mobile-flutter/docs/on-device-moderation.md`,
  `lib/moderation/classifier/toxicity_classifier.dart`, `lib/moderation/translation/translator.dart`,
  `lib/moderation/delivery/model_manifest.dart`, `lib/moderation/pipeline/moderation_pipeline.dart`
- Mozilla model registry (live, generated 2026-10-08): `https://storage.googleapis.com/moz-fx-translations-data--303e-prod-translations-data/db/models.json`
- Mozilla README (model files MPL-2.0; Firefox 118+): `https://github.com/mozilla/translations`
- `bergamot-translator` (MPL-2.0): `https://github.com/browsermt/bergamot-translator`
- Archived models repo licence (MPL-2.0): `https://github.com/mozilla/firefox-translations-models`
- ML Kit Translation overview / install paths: `https://developers.google.com/ml-kit/language/translation`,
  `https://developers.google.com/ml-kit/tips/installation-paths`
- gravitee model card + file tree + licence: `https://huggingface.co/gravitee-io/bert-small-toxicity`
- gravitee model family: `gravitee-io/bert-mini-toxicity`, `gravitee-io/bert-tiny-toxicity`
- KoalaAI model card + ONNX tree: `https://huggingface.co/KoalaAI/Text-Moderation`
- Horizon-Labs model card (comparison table used for unitary/CitizenLab figures):
  `https://huggingface.co/Horizon-Labs/multilingual-toxicity-small`
- TextDetox XLM-R card: `https://huggingface.co/textdetox/xlmr-large-toxicity-classifier`
- Helsinki-NLP opus-mt-en-es card + file tree: `https://huggingface.co/Helsinki-NLP/opus-mt-en-es`
- NLLB licence/research-only: `https://huggingface.co/facebook/nllb-200-distilled-600M`
- TranslateGemma model list: Hugging Face search API, `google/translategemma-4b-it` (Gemma licence)
- Flutter runtimes: `https://pub.dev/packages/tflite_flutter` (Apache-2.0, tensorflow.org,
  v0.12.1, Oct 2025), `https://pub.dev/packages/onnxruntime` (MIT, last release Mar 2024 —
  maintenance risk; ONNX Runtime itself is MIT)

## 7. What I could not verify (treat as acceptance-test items)

- **No latency or RSS measurement exists for any candidate on the reference device.**
  The classifier sub-250 ms claim and translation sub-900 ms claim are estimates.
- **No candidate publishes precision/recall at an operating threshold**; only F1, ROC-AUC
  or accuracy. The ≤ 5 % FPR / ≥ 0.85 recall gates cannot be checked from documentation.
- gravitee's per-language numbers are in-domain F1; no slice or FPR data; no ethics
  review. KoalaAI's macro-F1 0.326 is from its own card.
- OPUS-MT int8 sizes are computed from fp32 parameter counts, not downloaded artefacts.
- Whether the koalaai/gravitee ONNX graphs are fully supported by ONNX Runtime Mobile's
  operator set is unverified; this must be tested before selecting the runtime.
- The exact Android-vs-desktop released pair list for Firefox models (registry statuses
  distinguish `Release`, `Release Desktop`, `Release Android`); confirm the specific pairs
  you plan to ship.
- Legal interpretation of MPL-2.0 coverage of model weights, and of OpenRAIL use-restriction
  propagation through an app's terms, has not been reviewed by counsel here.
