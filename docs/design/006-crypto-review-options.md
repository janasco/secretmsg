# SecretMsg E2EE — options and plan for an independent crypto review

Research date: 2026-10-09. Scope: SecretMsg `feat/1.8` (`api/src/crypto.ts`, `apps/mobile-flutter/lib/crypto/`, `apps/web/src/lib/e2ee.ts`, design brief `docs/design/004-crypto-review-request.md`).
Prices and programme details change; every figure below is either sourced (with a URL) or explicitly marked **uncertain**.

---

## TL;DR — the honest headline

1. **Cheapest realistic route (this month, €0):**
   - Apply to **NLnet Restack** (deadline **3 Nov 2026**, €5k–50k, explicitly lists "security audits" as a support service, delivered by **Radically Open Security** to grantees). Frame it as *"replace the bespoke envelope with a standard construction and get the integration independently reviewed"*, not as *"audit my bespoke protocol"*.
   - Apply to the **GitHub Secure Open Source Fund** ($10k, rolling, 3-week security program).
   - Book **Trail of Bits' free one-hour office hours** for a design sanity check.
   - Post the protocol spec to the **IETF CFRG mailing list** and the **Modern Crypto** list for free expert comment.
   - Run **Verifpal** (free, by Nadim Kobeissi/Symbolic Software) on the protocol yourself.
2. **Recommendation: do NOT pay for a full protocol review of the bespoke envelope as it stands. Replace the bespoke key-wrap with an audited standard construction first (libsodium sealed boxes, or HPKE RFC 9180 base mode), then pay only for a focused integration review.** The known-gaps table already contains what a full review would headline; the rest is a threat-model/copy decision, not a code bug.
3. **No realistic free *full protocol review* exists for a small, non-critical, user-facing app with a bespoke protocol.** Every free/funded audit route (OSTIF, Alpha-Omega, Sovereign Tech Fund, OTF Security Lab) has eligibility SecretMsg mostly fails. Free routes that *do* exist are: funded *work* (NLnet, GitHub), free design feedback (CFRG, office hours), VDP platforms, and self-verification tooling. Once the protocol is a standard construction, funded review becomes genuinely attainable.
4. **Cheapest paid fallback if no grant lands:** one independent cryptographer for a 2–5 day focused review — Symbolic Software, Taylor Hornby (Defuse Security), or an individual like JP Aumasson — roughly **$5k–$25k** (uncertain), versus **$30k–$200k** for a full initial audit through OSTIF's published range.

---

## 1. What is actually being reviewed

The design (from `docs/design/004-crypto-review-request.md` and the `feat/1.8` code):

- Per-install X25519 keypair in `flutter_secure_storage`.
- Per-message (really per-thread) 256-bit content key `K`; body/reply AES-256-GCM with AAD `secretmsg-body-v1`.
- `K` wrapped once per recipient device: X25519 ECDH → HKDF-SHA256 (salt `secretmsg-e2e-v1`, info `secretmsg-wrap-v1:<kid>`) → AES-GCM, `kid` bound in AAD.
- Wire format: `enc:v1:<base64url(JSON)>` with `{v, alg, iv, ct, wraps:[{kid, epk, iv, ct}]}`.
- Worker (`api/src/crypto.ts`) stores envelopes verbatim, serves recipient public keys on a public endpoint, and decrypts only for opt-in report disclosure (AES-GCM with the handed-over `K`).
- Web client decrypts claim-link threads with `K` from the URL fragment.

Known gaps (implementer's own list): bespoke envelope, no sender authentication, server can substitute device keys and read at send time, no forward secrecy, no replay resistance beyond the 5-minute `client_msg_id` window, no key transparency/safety numbers.

Things I found in the code that a reviewer *will* flag, which are worth fixing before paying anyone (details in §6):

- **Plaintext push preview is generated unconditionally** in `CryptoService.prepareSend` (`PushPreview.fromContent(plaintext)`), and `crypto.ts` accepts a `preview` field and passes it to FCM. If the caller sends it by default, the server and Google see up to 140 characters of every message. The README says previews are opt-in/default-off; the code and wiring must make that true.
- **Plaintext downgrade path is open**: `POST /api/message/:username` (legacy) still accepts plaintext for recipients who have registered device keys. "Server cannot read bodies" is false for anything sent through that lane.
- **Key registration has no proof of possession**: `POST /api/crypto/keys` accepts any 32-byte X25519 public key for an authenticated user. A server (or a malicious client) can register keys silently.
- **The content key is a thread key**: replies reuse the original message's `K`, so one report disclosure reveals the original *and all replies*, including the reporter's own reply.
- **`cryptography` 2.9.0 (the only crypto dependency) is not itself audited** — its README makes no audit claim. libsodium, by contrast, has a long audit history.
- **No key-change warning** of any kind: `device_keys` is append-only server-side and the client never compares key sets across fetches.

---

## 2. The three products are not the same thing

| Product | What it is | Typical effort | Typical cost (see §3 for sources) | Typical turnaround |
|---|---|---|---|---|
| **Design consultation** | 1 expert reads the spec/threat model, gives an opinion ("this is fixable / replace it with X / here are 5 design flaws"). Often no formal report, or a short memo. | 0.5–3 person-days | $0 (office hours, CFRG) – ~$5k–$15k (independent); **uncertain** | days–2 weeks |
| **Code audit / integration review** | Review of a defined codebase against a defined construction: parsing, nonce handling, key storage, downgrade paths, server routes. Not a proof about a novel protocol. | 3–10 person-days | ~$5k–$30k boutique; **uncertain** | 1–4 weeks |
| **Full protocol review** | Cryptographer models the protocol, tries to break its claims, checks the construction against literature, reviews implementation, delivers a report. For a *bespoke* protocol this is the expensive one. | 5–20+ person-days (2–6 person-weeks is common) | $30k–$200k (OSTIF's published range for initial audits); low-to-mid five figures for a focused boutique review | 4–12 weeks |

For this project the correct purchase is **design consultation now, integration review after standardization**. A full protocol review only makes sense if SecretMsg decides to keep a bespoke design — which the evidence says it should not.

---

## 3. Commercial options (named, with honest cost confidence)

### 3.1 Best-fit firms

| Firm | Why it fits | Published/observed scope evidence | Cost signal | Confidence |
|---|---|---|---|---|
| **Cure53** (Berlin) | Audits privacy/messaging/crypto products and publishes the reports; explicitly sells "design advice" and "infrastructure, platform and cryptography audits"; has done Threema mobile, Ente crypto design, Nym, Proton Pass, Monocypher, FlowCrypt, OpenPGP.js (OTF-funded). Team includes Nadim Kobeissi. | Reports page: [cure53.de](https://cure53.de). NordPass Business: 21 person-days. GreatFire: 2 testers × 4 days. Cyph: 5 testers × 12 days. | Independent 2026 market list: "low to mid five figures per review", quote-based ([atlantsecurity.com](https://atlantsecurity.com/blog/top-penetration-testing-companies)). A focused 2–4 week review plausibly **$10k–$40k**; **uncertain** | High on fit, medium on price |
| **Symbolic Software** (Paris; Nadim Kobeissi) | Independent applied-crypto consultancy; 300+ design-level engagements; protocol/threat-model/code review; built Verifpal; clients include 1Password, Bitwarden, Mozilla, ExpressVPN, Ente. "Plan a review" intake. | [symbolic.software](https://symbolic.software/) | No public prices. Small independent practice — best guess **$5k–$25k** for a small engagement; **uncertain** | High on fit, low on price |
| **Trail of Bits** (NY) | Dedicated Cryptography practice; "Cryptographic Design Assessment" service explicitly for reviewing designs *before* implementation; publishes effort in person-weeks (recent 1-week crypto engagements: Open Home Foundation SecureTar v3, Calyx HSM scripts). **Free one-hour office hours** with an engineer. | [trailofbits.com/services/cryptography](https://trailofbits.com/services/cryptography) | No public prices. Market day rates for senior specialist testers ~$1.2k–$3k/day ([synack.com](https://www.synack.com/blog/penetration-testing-cost)); a 1–2 person-week crypto review plausibly **$15k–$50k**; **uncertain** | High on fit, low on price |
| **NCC Group Cryptography Services** | One of the deepest protocol-review benches (Olm, (n+1)sec, Ricochet anonymous messaging, WhatsApp contacts, Go crypto/ssh); does "protocol review", "applied cryptographic design & architecture review". | [cryptoservices.github.io](https://cryptoservices.github.io), public reports | No public crypto prices; a G-Cloud 14 listing shows NCC day rates of **£500–£2,500/day** ([Digital Marketplace](https://www.applytosupply.digitalmarketplace.service.gov.uk/g-cloud/services/646579600901839)). A 2–4 week crypto review ≈ **£20k–£80k**; **uncertain** | High on fit, medium on price |
| **Quarkslab** (Paris) | Audited Session (secure messenger) over three engagements, 32 + 10 days; strong protocol/mobile work. | [blog.quarkslab.com](https://blog.quarkslab.com/audit-of-session-secure-messaging-application.html) | No public prices; full-messenger audits are multi-week. **$40k+**; **uncertain** | Medium |
| **7ASecurity** | Does open-source code audits funded by OSTIF and the Sovereign Tech Agency (conda-forge, Incus, zlib, Tor); mobile/web/code audit services. | [7asecurity.com](https://7asecurity.com), OSTIF news | No public prices; OSS audits are typically funder-negotiated. **$15k–$50k**; **uncertain** | Medium |
| **Least Authority** | 200+ published audits; cryptographic protocol and distributed-system expertise; fixed-price proposals; explicitly says "design reviews and other smaller engagements will have a lower cost"; member of OTF's Security Lab network. | [leastauthority.com/security-consulting](https://leastauthority.com/security-consulting) | No public prices. **$10k–$50k**; **uncertain** | Medium |
| **Radically Open Security** (Amsterdam) | Not-for-profit security company; delivers the **security-audit support service inside NLnet's NGI Zero programme**; OTF-funded audits (GlobaLeaks, RelayBaton, Urazi). Non-profit ethos usually means lower rates. | [radicallyopensecurity.com](https://radicallyopensecurity.com), [NLnet support services](https://nlnet.nl/NGI0/services/) | No public prices. **$10k–$30k** for a small scope; **uncertain** | Medium |

Also real but less well-matched: **Kudelski Security** (crypto services, enterprise pricing), **IOActive**, **Include Security**, **Atredis**, **Doyensec**, **X41 D-Sec** (German; OSTIF partner), **Security Innovation**. All quote-based; none publish crypto-review prices. **Least Authority and Cure53 are the two I would actually ask for quotes, plus Symbolic Software for a design consult.**

### 3.2 Individual consultants

| Person / practice | Notes | Cost signal |
|---|---|---|
| **Nadim Kobeissi — Symbolic Software** | See above. Also author of Verifpal and formerly on Cure53's roster. Best "one senior cryptographer reviews the design" option. | **uncertain**, likely $5k–$25k |
| **Taylor Hornby — Defuse Security** | Independent; "specializes in auditing cryptographic protocols and implementations"; audited gocryptfs, Zcash ecosystem security consultant; writes accessible threat models. | **uncertain**, likely $2k–$15k for a small scope ([defuse.ca/software-security-auditing.htm](https://defuse.ca/software-security-auditing.htm)) |
| **Jean-Philippe Aumasson** | Author of *Serious Cryptography*; independent crypto reviews (e.g. Plakar audit); day job at Taurus/Cloudflare — availability uncertain. | **uncertain**; Plakar did not disclose cost |
| **Filippo Valsorda / Geomys** | Go-crypto specialist; more relevant if the Worker/backend were the main risk; not Dart/Flutter-focused. | **uncertain** |
| **Thomas Pornin** | BearSSL author, now NCC Group consultant; embedded/primitive focus. | via NCC Group |

Individual consultants are the only realistic way to get a *meaningful* review for under ~$10k, but there is no published price list and quality varies. Ask for a fixed-scope 2–3 day engagement with a written memo.

### 3.3 Academic groups (free/cheap only if it becomes a research collaboration)

These groups really do analyze real messaging apps — but as research, not as a service. There is no application form, no SLA, and usually no report you can publish as an audit.

- **CISPA Helmholtz Center — Cas Cremers' group**: Tamarin-based analysis of secure messaging (formal analysis of Signal; post-compromise security). [people.cispa.io/cas.cremers](https://people.cispa.io/cas.cremers/).
- **ETH Zurich — Applied Cryptography group (Kenny Paterson et al.)**: published analyses of Threema, Matrix/secure messengers ("Three lessons from Threema").
- **University of Waterloo — CrySP (Ian Goldberg)**: the "SoK: Secure Messaging" survey lineage; ratchets, metadata.
- **Johns Hopkins — Applied Cryptography group (Matthew Green)**: messaging and protocol analysis.
- **INRIA — Prosecco (Karthikeyan Bhargavan)**: verified cryptography, TLS/Signal-family analysis.
- **KU Leuven — COSIC**: does industry-funded projects; likely paid, not free.
- **University of Birmingham (Tom Chothia)**, **TU Darmstadt (Cryptoplexy)**, **IMDEA Software**: protocol analysis groups.

**How to approach:** email the group with a 2-page summary, the spec, and an explicit offer to co-author a case-study paper. Expect 2–6 months, possibly an NDA/ethics process, and no guarantee. **Do not count on this route.** The honest version: "academic groups may review this as research, but you cannot schedule or rely on it."

### 3.4 University course projects

There is no standing programme I could verify that accepts external software for a graded audit. MIT 6.858's final project is building SecFS, not auditing third-party software ([MIT OCW](https://ocw.mit.edu/courses/6-858-computer-systems-security-fall-2014/pages/final-project/)); CMU 18-732 is a course, not an audit service ([CMU](https://courses.ece.cmu.edu/18732)). Individual professors occasionally run such projects, and they are worth an email — but this is ad hoc, cannot be scheduled, and does not produce a review you can cite. Treat it as a long-shot bonus, not a plan.

---

## 4. Free and funded routes — with eligibility stated honestly

| Programme | What it gives | Eligibility reality for SecretMsg | Verdict |
|---|---|---|---|
| **NLnet Restack / NGI Zero Commons Fund** | €5k–€50k grants (first-time applicants); support services include a **security audit delivered by Radically Open Security**; Restack explicitly covers "alternatives to closed online technologies serving a large userbase" and "full stack security". Deadline **3 Nov 2026**; [nlnet.nl/restack](https://nlnet.nl/restack/), [nlnet.nl/propose](https://nlnet.nl/propose/) | Individuals, collectives, SMEs all eligible. EU-funded calls require a "European dimension" (applicants mostly from Horizon Europe-eligible countries) — a real blocker if the maintainer is outside them. **GenAI policy: "We are not interested in AI-generated projects"; AI assistance must be disclosed.** The repo's `antislop.toml`/`AGENTS.md` and agent-written docs make this a material risk. Grants are "primarily for technical development", so bundle the audit with the standardization work. | **Best realistic route.** Apply. Be transparent about AI assistance. |
| **GitHub Secure Open Source Fund** | **$10,000 per project** paid in tranches ($6k/$2k/$2k), 3-week security program, GitHub Security Lab office hours, up to $10k Azure credits; rolling applications; 130+ projects in 3 sessions. [github.com/open-source/github-secure-open-source-fund](https://github.com/open-source/github-secure-open-source-fund) | Maintainers of open-source projects; selection is competitive and favours "fast-growing dependencies" and projects where funding can "impact security". No legal entity needed. | **Apply (rolling).** $10k alone buys ~3–5 days of an independent consultant. |
| **OSTIF** | Arranges and co-manages audits; publishes reports; **helps projects raise/split funding**; published initial audit range **$30k–$200k**. Intake form is open to any project for advice. [ostif.org/get-an-audit](https://ostif.org/get-an-audit/) | Historically selects widely-used/critical projects (OpenSSL, curl, Git, etc.). SecretMsg is not critical infrastructure; sponsorship unlikely. But the intake conversation is free and they say explicitly they will advise even if no audit happens. | **Talk to them now; do not expect funding.** Ask what scope would make the project fundable later. |
| **OpenSSF Alpha-Omega** | Grants and security engagements for critical OSS; $5.8M to 14 critical projects in 2025; OSI-licensed projects only; selection heavily informed by criticality/security impact. [alpha-omega.dev/grants/how-to-apply](https://alpha-omega.dev/grants/how-to-apply) | Requires demonstrable criticality; a 13+ anonymous messaging app does not meet that bar today. | **Not eligible now.** |
| **Sovereign Tech Fund / Sovereign Tech Agency** | Funds maintenance and audits of critical digital infrastructure; min cost €50k. | **Explicitly disqualified:** "We are currently not looking for user-facing applications, such as messaging apps or file storage services." [sovereign.tech/programs/fund](https://www.sovereign.tech/programs/fund) | **Not eligible.** |
| **OTF (Open Technology Fund) — Security Lab / Internet Freedom Fund** | Has funded and run audits of exactly comparable apps: **Briar, Ricochet (NCC Group), Olm, Delta Chat, Tella, Mailvelope, SecureDrop**. Internet Freedom Fund: $10k–$900k, rolling, individuals 18+ eligible. [opentech.fund/impact/security-safety-audits](https://www.opentech.fund/impact/security-safety-audits) | Remit is internet freedom — tools for people facing censorship/surveillance in repressive environments. A teen anonymous-messaging app does not obviously fit unless positioned for at-risk users. OTF's US-government funding is politically volatile (FY2026: $40.5M congressionally designated; the administration has proposed dismantling USAGM). | **Long shot; funding environment uncertain.** |
| **Mozilla MOSS** | Historically funded OSS security audits (including Cure53's Thunderbird/RNP). | **Programme is on indefinite hiatus and not accepting applications.** [mozilla.org/en-US/moss](https://www.mozilla.org/en-US/moss) | **Closed.** |
| **Google OSS-Fuzz** | Free continuous fuzzing on Google infrastructure. | Not a review. Acceptance uses a criticality score; supported languages are C/C++, Rust, Go, Python, Java/JVM, JS, Lua — **Dart is not listed**. OSS-Fuzz would find parser crashes at best, not protocol flaws. (There is no "OSS-Vuln" programme; **OSV** is a vulnerability database.) | **Not applicable.** |
| **Google's Open Source Security Team / OSTIF partnerships** | Google funds many OSTIF audits (OpenSSL etc.). | No application route for a small app. | N/A |
| **FUTO** | Funds user-control/privacy software (Grayjay, Immich, FUTO Keyboard, Polycentric). Mostly development grants, not audit procurement. [futo.tech](https://futo.tech) | Broad mission fit ("computers belong to you") but no published application process for audits; would need direct contact. | **Possible, unverified.** |
| **HackerOne Community Edition** | Free vulnerability-disclosure program (VDP) for eligible OSS: OSI license, project active ≥3 months, `SECURITY.md`, advertise the program, respond to reports within a week; no bounty required; 5% fee only if you pay bounties. [hackerone.com/company/open-source-community](https://www.hackerone.com/company/open-source-community) | SecretMsg qualifies on paper. But a VDP produces opportunistic reports, not a crypto review; crypto-protocol reviewers rarely hunt unpaid. | **Worth having; not a review.** |
| **Internet Bug Bounty (HackerOne)** | Paid bounties for critical internet software. | **Currently "taking a break and is not accepting new submissions"** ([hackerone.com/ibb](https://hackerone.com/ibb)); SecretMsg would not meet the criticality bar anyway. | **Closed/not eligible.** |
| **Bugcrowd / Intigriti / YesWeHack / Open Bug Bounty** | VDP/bounty platforms. | Free VDP tiers exist; without meaningful bounties you will not attract crypto specialists. Open Bug Bounty is web-vuln focused. | **Low value for protocol review.** |
| **Immunefi / Code4rena / Sherlock / Cantina** | Web3 audit contests. | SecretMsg is not web3. | **Not applicable.** |
| **Crowdfunding (Open Collective, GitHub Sponsors, Patreon)** | Raise an audit budget transparently. | Works only with an audience; the app targets teens, not a donor base. | Optional. |
| **CFRG / Modern Crypto / Cryptography Stack Exchange** | Free expert commentary on the design. IETF's Crypto Forum Research Group is where HPKE was standardized; the mailing list is open to anyone. | Not an audit and no confidentiality; but a well-written "here is my design, what breaks?" post gets real cryptographer attention. | **Do it now.** |
| **Verifpal (free, GPL) / ProVerif / Tamarin** | Symbolic protocol verification tools. Verifpal is designed for practitioners; you can model the envelope and its attacker. | Symbolic models can find logic attacks (e.g. missing authentication) but prove nothing about the computational construction and do not replace a review. | **Do it now.** |

**Bottom line on free options:** there is no free *protocol review* for a bespoke design at this project's scale. There are free *funded-work* grants (NLnet, GitHub), free *feedback* channels (CFRG, Trail of Bits office hours, OSTIF intake advice), free *tooling* (Verifpal, Scorecard, CodeQL), and free *vulnerability coordination* (HackerOne CE). The funded full audit becomes reachable only after the project either grows into "critical infrastructure" or adopts a standard construction and applies to a funder with an achievable scope.

---

## 5. Recommendation on sequencing

**Replace the bespoke envelope with a standard construction, then review the integration. Do not pay for a full review of the current design.**

Reasoning:

1. **The review's headline findings are already written down.** The implementer's own gap table covers bespoke construction, key substitution, no FS, no replay, no transparency. A paid review would confirm them and then say "replace the construction" — which the project can act on without paying for the confirmation.
2. **A review of a construction you intend to replace is spent money.** If the fix for the envelope is HPKE/sealed boxes, any review of `enc:v1` is invalidated the moment `enc:v2` ships.
3. **Standardization shrinks the review from "the whole protocol" to "the integration".** After replacing the wrap, the novel surface is: key generation/storage, registration, multi-device, migration, parser, report disclosure, and the key-substitution threat model. That is a 2–5 day review, not a 2–4 week one.
4. **The remaining gaps are product decisions, not code bugs.** No sender authentication is *intentional* for anonymous messaging; no forward secrecy is inherent to "encrypt to a long-lived published key with no ratchet"; key substitution needs safety numbers/key-change warnings, not cryptanalysis. These need honest copy plus cheap mitigations, and only then an expert to sanity-check the wording.

### Concrete replacement options (in order of preference)

**Option A — libsodium sealed boxes (recommended).** `crypto_box_seal`/`crypto_box_seal_open` are libsodium's purpose-built construction for exactly this case: anonymous sender encrypts to a recipient's public key. It is an audited C library, available in Dart/Flutter for VM and Web via the `sodium` 4.x package (`crypto_box_seal` is supported on both VM and JS; see [pub.dev/packages/sodium](https://pub.dev/packages/sodium)). The content key stays AES-256-GCM, so the Worker's report-verification path (`verifyEnvelopeWithContentKey`) and the web claim-link decrypt path do not change at all — only the *wrap* changes, and only clients ever open wraps. Envelope becomes `enc:v2:` with `wraps:[{kid, ct}]` (the ephemeral public key lives inside the sealed box; the `kid` AAD binding is no longer needed because each wrap is cryptographically bound to one recipient key). Keep v1 read support during migration.
*Effort: ~1–2 weeks for one developer familiar with the code, plus cross-language test vectors.*

**Option B — HPKE RFC 9180 base mode.** The "textbook correct" standard for this pattern; base mode is sender-anonymous, matching the product. Caveat: **there is no mature, widely-deployed pure-Dart HPKE implementation** — pub.dev results are new/small (`affinidi_tsp`, `turnkey_crypto`, `cipherbird`, `darkbio_crypto`), so you would either implement the HPKE schedule yourself on top of `cryptography` primitives (i.e. write bespoke glue again, but a small, testable amount) or add an FFI dependency. If chosen: use RFC 9180 test vectors and get the glue reviewed.
*Effort: ~2–4 weeks, more review surface than Option A.*

**Option C — keep AES-GCM + X25519 but formalize as "HPKE-like" and review as-is.** Not recommended; this is the current situation with a nicer name.

**Option D — adopt a full ratcheting protocol (Double Ratchet/X3DH via libsignal, or MLS via the `openmls` Dart wrapper).** This buys forward secrecy and sender authentication, but: libsignal's official bindings are not Dart; the Dart port is community-maintained; MLS is heavy and assumes group state and online key packages; and anonymous senders fight X3DH's identity-key model. This is a multi-month redesign, not a review-cheaper move. Only consider if forward secrecy becomes a product requirement.

### Effort/cost comparison

| Path | Engineering | Review scope | Review cost | Elapsed |
|---|---|---|---|---|
| **A. Review bespoke as-is** | none | Full protocol + 3 codebases | **$30k–$200k** (OSTIF range) or ~$15k–$60k boutique; free only if funded | 6–16 weeks |
| **B. Sealed boxes + integration review** | 1–2 weeks | Wrap replacement, key mgmt, migration, routes | **$5k–$20k** focused (2–5 days) | 4–8 weeks |
| **C. HPKE + integration review** | 2–4 weeks | Same + HPKE glue correctness vs vectors | **$8k–$25k** | 6–10 weeks |
| **D. Full ratchet redesign** | 2–4 months | New protocol + integration | full review again | 6+ months |

---

## 6. What to do before spending anything

These reduce both the cost and the risk of whatever review eventually happens. None requires money.

**Correctness/claims (do these first — they change what the review has to cover):**
1. **Fix the preview leak.** Make the plaintext `preview` opt-in end-to-end (default off), or remove it and send generic push text. Right now the code path always computes it; if the caller sends it, the server and FCM see message text and the E2E claim is false.
2. **Close the plaintext downgrade.** After a recipient has registered device keys, reject plaintext sends on the legacy `POST /api/message/:username` route (or at minimum mark them loudly and never present them as E2E).
3. **Add proof of possession to key registration.** Give each device an Ed25519 signing key (via `cryptography` or libsodium) and have it sign its X25519 public key on registration; the server verifies. Cheap, and it also lays groundwork for optional authenticated senders later.
4. **Add key fingerprints and key-change warnings.** Publish a stable fingerprint of the recipient's key set, show it in-app, and warn when it changes between fetches. This is the cheapest partial answer to the key-substitution gap (full key transparency is a bigger project).
5. **Add client-side replay dedup.** Store SHA-256 of received envelopes and drop duplicates; this removes reliance on the 5-minute server window.
6. **Fix the disclosure claim.** Either derive a separate reply key (so disclosing the original's `K` does not disclose the whole thread) or state in the report UI that the key covers the whole thread.
7. **Decide multi-device honestly.** The branch has no pairing/escrow implementation; do not ship copy that implies multi-device works.

**Engineering hygiene (free, and it is what OSTIF asks for):**
8. Write the full protocol spec (004 is a strong start) with a threat-model table, explicit assumptions, and test vectors. Add RFC 9180/sealed-box known-answer tests and cross-language vectors (Dart/TS/Web).
9. Fuzz `parseEnvelope`/`decodeEnvelope` (malformed base64, huge fields, wrong tag lengths) and add property tests for wrap/unwrap.
10. Run **OpenSSF Scorecard** and the **OpenSSF Best Practices Badge**; enable GitHub private vulnerability reporting; add `SECURITY.md`; run CodeQL (free for public repos), `dart analyze`, `gitleaks`.
11. Get free eyes: **Trail of Bits office hours** (free hour), **CFRG** mailing list post, **Modern Crypto** list, **OSTIF intake** (they explicitly offer advice without an audit), and email 2–3 academic groups.
12. Model the protocol in **Verifpal** and keep the model in the repo; it is free, and reviewers can rerun it.

---

## 7. Costed 90-day action plan

| When | Action | Cost |
|---|---|---|
| Week 1 | Fix items 1–7 in §6; write spec/test vectors; run free tooling | €0 (time) |
| Week 1–2 | Apply to **GitHub Secure Open Source Fund** (rolling) | €0 |
| Week 1–2 | Apply to **NLnet Restack** (deadline **3 Nov 2026**) — proposal = "standardize SecretMsg E2EE on audited constructions (sealed boxes/HPKE), add key-change warnings and test vectors, and commission an independent integration audit"; budget the audit + 2–3 weeks engineering within €5k–€50k; **disclose AI assistance per their policy** | €0 |
| Week 2 | Book **Trail of Bits office hours**; post to CFRG/Modern Crypto; submit **OSTIF** intake for advice; email **CISPA (Cremers)**, **Waterloo CrySP**, **ETH (Paterson)** with a case-study offer | €0 |
| Week 2–4 | Implement **Option A** (libsodium sealed boxes, `enc:v2:`), keeping v1 read support; add vectors and fuzz tests | €0 (if unfunded) |
| Week 4–8 | If any grant lands: request the **NLnet/ROS security audit** support service, or contract **Symbolic Software / Cure53 / Taylor Hornby** for a 2–5 day focused review; publish the report | $0 if funded by NLnet/ROS; else **$5k–$20k** |
| Ongoing | Run **HackerOne Community Edition** VDP; iterate; re-audit on protocol changes | €0 (5% fee only on paid bounties) |

**Total if funded (most likely outcome):** €0–€2k of incidental costs.
**Total if nothing is funded:** €5k–€20k for a focused independent review; €0 for the standardization, free feedback, and VDP.

**What not to do:** don't spend $30k+ on a full review of `enc:v1`. If someone offers that as the only path, the correct answer is to decline and standardize first.

---

## 8. Key sources

- Design and code: `docs/design/004-crypto-review-request.md`, `api/src/crypto.ts`, `apps/mobile-flutter/lib/crypto/`, `apps/web/src/lib/e2ee.ts` (branch `feat/1.8`).
- OSTIF audit process and published cost range: https://ostif.org/get-an-audit/
- Cure53 services/reports: https://cure53.de/
- Symbolic Software: https://symbolic.software/
- Trail of Bits cryptography services and free office hours: https://trailofbits.com/services/cryptography
- NCC Group Crypto Services: https://cryptoservices.github.io/ ; G-Cloud day-rate listing: https://www.applytosupply.digitalmarketplace.service.gov.uk/g-cloud/services/646579600901839
- Quarkslab Session audit: https://blog.quarkslab.com/audit-of-session-secure-messaging-application.html
- Least Authority: https://leastauthority.com/security-consulting
- Radically Open Security: https://radicallyopensecurity.com/
- Defuse Security (Taylor Hornby): https://defuse.ca/software-security-auditing.htm
- NLnet Restack / CodeSupply / support services: https://nlnet.nl/restack/ , https://nlnet.nl/codesupply/ , https://nlnet.nl/NGI0/services/ , https://nlnet.nl/propose/
- GitHub Secure Open Source Fund: https://github.com/open-source/github-secure-open-source-fund
- OpenSSF Alpha-Omega grants: https://alpha-omega.dev/grants/how-to-apply
- Sovereign Tech Fund (messaging-app exclusion): https://www.sovereign.tech/programs/fund
- OTF Security Lab audits: https://www.opentech.fund/impact/security-safety-audits ; Internet Freedom Fund: https://www.opentech.fund/funds/internet-freedom-fund/
- Mozilla MOSS hiatus: https://www.mozilla.org/en-US/moss
- OSS-Fuzz supported languages: https://google.github.io/oss-fuzz
- HackerOne Community Edition: https://www.hackerone.com/company/open-source-community ; IBB status: https://hackerone.com/ibb
- FUTO: https://futo.tech
- RFC 9180 (HPKE): https://www.rfc-editor.org/rfc/rfc9180.html
- libsodium sealed boxes: https://libsodium.gitbook.io/doc/public-key_cryptography/sealed_boxes ; Dart bindings: https://pub.dev/packages/sodium
- Verifpal: https://verifpal.com/ , https://github.com/symbolicsoft/verifpal
