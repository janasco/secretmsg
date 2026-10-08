# SecretMsg — Product briefs: branded boxes, reactions, verified senders, group boxes

Status: draft for product review · Date: 2026-10-08 · Scope: product behavior only, not implementation.
These briefs are written against SecretMsg as it exists: React/Vite web app prerendered and deployed as a Cloudflare Worker; Flutter Android client (`net.secretmsg.android_app`); private Cloudflare Worker API with D1; shipped anonymous boxes, double-blind replies, Filtered Words, pause, report, block, Daily Drop, prompt roulette, Sticker Studio, ranks/challenges, FCM push, one-time `remove_ads`; auth by handle + PIN with optional email OTP; no analytics SDK; audience 13+.

## Shared constraints (apply to all four briefs)

1. **Privacy model (fixed).** Message bodies are end-to-end encrypted and unreadable by the server. Metadata — timestamps, ciphertext size, recipient routing, delivery state, and the sending account — is server-visible and used for abuse prevention. Moderation runs in two places: client-side on plaintext (official clients only) and server-side on metadata.
2. **Moderation honesty.** Client-side filtering, including Filtered Words, runs in the official clients and is **bypassable by a modified client**. No brief below treats client-side filtering as a security boundary. Server-side enforcement is limited to what metadata allows: rate limits, size caps, account state, and delivery patterns.
3. **Data policy.** Every field a feature introduces must appear in the public data policy before launch, with purpose, retention, and deletion behavior. "Not collected" is preferred to "collected but unused."
4. **Age.** Accounts are 13+. Nothing may create a path to under-13 accounts or collect data from them. Data about 13–17 year olds is children's data under GDPR and must be minimized. COPPA analysis is required for any verification or school-related feature. This document is not legal advice; compliance needs counsel review before launch.
5. **No dark patterns.** Defaults are the least deceptive option; turning a feature off is as easy as turning it on; disabling a feature never silently keeps processing data; consequences are described before commitment, not after.
6. **Fonts and theming.** Any font used is on Google Fonts under an open license, self-hosted by SecretMsg. Users cannot supply font files, font URLs, arbitrary CSS, or `@font-face`. This is a fingerprinting and licensing boundary, not a styling preference.
7. **No analytics SDK.** Anti-abuse decisions may only use account, rate, and delivery signals already present server-side, plus user reports.

---

## 1. Custom themes and branded links

**User story.** As a box owner, I want a memorable custom handle and a themed public box page, so that the link I share is easy to remember and is visibly mine rather than a copy.

**Acceptance criteria**

1. An authenticated account can claim one custom handle, replacing `secretmsg.net/{auto-handle}` with `secretmsg.net/{custom}`. Claiming is optional; auto-generated handles remain valid forever.
2. Handle syntax: 3–20 characters, `a–z`, `0–9`, `-`, `_`; must start and end with a letter or digit; no consecutive separators; uniqueness is case-insensitive; ASCII only (no Unicode or IDN, so no homoglyph or punycode lookalikes).
3. Rejected at claim time, with a plain-language reason: the reserved list (platform routes such as `about`, `login`, `api`, `report`, `download`, `g`, `admin`, plus platform/legal/support terms); names matching an existing handle under a normalization rule (differ only by case, `-`/`_`, or a defined lookalike set such as `l/1/I`); names flagged for impersonation. The check runs server-side and atomically: simultaneous claims produce exactly one winner.
4. Anti-squat: a custom handle requires either a verified email OTP or an account older than 7 days in good standing. One custom handle per account; at most one change per 30 days and 3 changes per rolling 12 months, server-enforced.
5. Link continuity: `secretmsg.net/old` performs a server-side redirect to the account's current handle for as long as the account exists. Sticker exports, QR codes, and any shared image containing the old handle keep working. After a second migration, every previously held handle points at the newest one; there is no redirect chain.
6. Retired handles are never reassigned. If the account is deleted, the handle is tombstoned and permanently unavailable. A tombstoned page shows a "this box no longer exists" notice with a Report link — never another user's box.
7. Appearance options on the public box page: one background color, one accent color, one pattern from a curated set, and one typeface from a curated Google Fonts list (initial set: Inter, Lora, Space Grotesk, Bitter, IBM Plex Sans). Two theme modes: a prepared light/dark pair, or "platform default."
8. Color inputs are constrained hex values (`^#[0-9a-fA-F]{6}$`), validated server-side. The editor previews light and dark and blocks saving combinations that fail WCAG AA (4.5:1 body text, 3:1 large text and controls), naming the failing pair.
9. The page follows the visitor's system light/dark preference, offers a visible light/dark toggle, and honors `prefers-reduced-motion` by disabling pattern animation.
10. Fonts are served from SecretMsg's own origin as subsetted woff2. Page CSP is `font-src 'self'; style-src 'self'; img-src 'self'` — no third-party font or image requests at render. The only font control is the fixed list; there is no URL input, file upload, or CSS field.
11. The owner can preview the exact public page (mobile and desktop, light and dark, including the submit form) before saving.
12. Theming affects the public box page only — not the app UI, not message content, and not encryption. No user HTML, SVG, markup, or remote images are accepted or rendered anywhere on the box page.
13. The current handle appears on the box page, share sheet, QR export, and any sticker exported after the change. OG/Twitter metadata uses the current handle and theme; cache TTLs are documented.
14. Every box page, themed or not, carries a platform-owned strip: "SecretMsg never asks for your PIN on a box page," plus a Report link that works without login. Abuse review can force a page to the default theme while a report is investigated.
15. The data policy lists handle history, theme choices, and migration events, each with a stated purpose (link routing, page rendering). Theming adds no tracking and no third-party requests.
16. Page accessibility (focus order, labels, contrast) is unchanged by theming; the screen-reader structure is the same on every theme.

**Edge cases**

1. **Handle squatting.** One account parks dozens of desirable names. Criterion 4 (one handle, change limits, standing requirement) plus no-transfer and no-sale handle it by policy; sockpuppet parking is only partly preventable without analytics, with reports and rate limits as fallback. Inactivity reclaim is an open question below.
2. **Trademark and impersonation.** `official-nike`, `lincolnhigh-principal`, `secretmsg_support`. Complaint path: a report category requiring evidence (trademark registration, or an email from the organization's own domain for org claims). The platform can provisionally replace the handle with a notice during review. Substantiated cases are reclaimed and tombstoned; the account is notified with the reason and can appeal. Impersonating platform staff or support is a permanent ban. Handles are strings, not identity: an unverified handle conveys no affiliation.
3. **Migration breaks published links and stickers.** The redirect in criterion 5 covers stickers, printed QR codes, and external previews that still point at the old URL. Third-party platforms may keep cached OG images after a theme change; the docs state this and publish a cache TTL. A second migration does not create a chain.
4. **Old handle after account deletion.** Tombstones (criterion 6) mean traffic intended for a deleted account never reaches a different person. The cost is permanent namespace exhaustion, acknowledged in the open questions.
5. **Confusable handles.** `rn` vs `m`, `1` vs `l`, trailing separators, double hyphens. Syntax and normalization (criteria 2–3) cover the common cases; the rest is report-driven. Display preserves chosen case; links resolve case-insensitively.
6. **A legal handle becomes needed as a reserved word later.** Reclaims require notice, a stated reason, an appeal path, and end in a tombstone — never a transfer to another user. There is no blanket "we can take any handle at any time" clause.
7. **Themed page used for phishing or impersonation.** The page has no custom markup, but a display name plus copy ("enter your PIN to continue") is possible. Countermeasures: no input fields other than the message composer; the platform strip in criterion 14; a dedicated report reason; forced default-theme review; account action for repeat offenders.
8. **Malicious theme payloads.** Field validation (criterion 8), server-side allowlists for pattern and font IDs, and CSP (criterion 10). A modified client sending arbitrary CSS or a font URL is rejected server-side and unrenderable client-side.
9. **Illegible or inaccessible themes.** The contrast gate blocks saving (criterion 8); the viewer-side light/dark toggle and reduced-motion handling are always available. Pattern opacity is capped so it never cuts text contrast.
10. **Minors claiming public handles.** A 13-year-old claims `emma-lincoln-2012`. The claim screen warns that the handle is public, appears on every shared link, and should not contain a full name, school plus graduation year, or other identifying details. Apparent full legal names are reportable, not automatically blocked.
11. **Weaponized complaints.** Competitors or bullies mass-report a handle. Complaint review requires evidence, decisions are logged and appealable, and reports are rate-limited per reporter.
12. **Theme change while pages are cached.** Rendering is per-request; only external caches can be stale (criterion 13). In-app views never depend on third-party caches.
13. **Account deletion / GDPR erasure.** Theme data and migration logs are deleted with the account; the tombstone retains no personal data. Export includes the handle history.
14. **Auto-handle owners.** Users who never claim a custom handle can still choose a theme, and their auto-handle links keep working.

**Open questions**

- Free vs paid custom handles: free invites squatting; paid invites a speculative market and excludes teens without money. Is a change-limit the whole answer?
- Inactivity reclaim: after how long, with what notice, and does reclaim break the "links are forever" expectation the sticker feature creates?
- Do tombstones last forever, or is there a documented release window (e.g., 12 months) with a "previously used" flag?
- Who adjudicates trademark disputes, against what evidence bar, given a small team and no analytics? Can a rights-holder be verified without exposing unrelated user data?
- Should a disputed name be offered to the complainant through the organization-verification path (brief 3), or always tombstoned?
- Does requiring a verified email for custom handles coerce users into handing over an identifier they otherwise wouldn't? Is that an acceptable trade for anti-squat enforcement?
- Should the platform support club/school handle handoff (a graduating class passing `lincoln-2027` to the next one), and if so, how does that coexist with no-reassignment?
- Are themed sticker exports (colors matching a box) in scope, or does the Sticker Studio stay on a platform palette?

---

## 2. Reactions and upvotes

Decisions up front: reactions are a fixed set of six expressive emoji, one per person per message, visible to the author. Upvotes are a private, on-device ranking that only the viewer sees — no public counts, no negative scores anywhere. This removes the obvious harassment surface (score-visible negativity) by design. The trade is no viral-popularity mechanic, which is deliberate for a 13+ audience.

**User story.** As a box recipient, I want to react to messages and rank them privately, so that I can acknowledge and triage what I receive without writing a full reply and without creating a public score that others can attack.

**Acceptance criteria**

1. Every message and reply shows a reaction bar with a fixed set of six expressive emoji (❤️ 😂 😮 😢 👏 🔥 — final set fixed per app version). The set contains no negative rating glyph (no thumbs-down). Tapping applies; tapping a different one switches; tapping the same removes. One reaction per actor per message at any time.
2. Reaction writes are idempotent under retries and offline queue replay; duplicate delivery never creates duplicate states or inflated counts.
3. The message's author sees which emoji was left. In group feeds, per-emoji aggregate counts are visible to members. No surface shows who reacted. (A 1:1 box has one possible reactor by construction; this is not presented as identity.)
4. No downvotes, dislikes, or negative scores exist anywhere in the product. Reports are the only negative signal, and they are reviewed by a human, not counted.
5. Sender-originated reactions (anonymous sender → owner's replies) are delivered with a randomized delay of 30–120 minutes and are shown to the owner with coarse timestamps only ("Today," "Yesterday," a date) — never exact times. Owner-originated reactions deliver immediately with exact times in the sender's thread view.
6. Push notifications for reactions are coalesced: at most one per thread per 30 minutes ("3 new reactions"), and reaction notifications default to generic text; detailed content is opt-in. A thread can be muted independently of blocking.
7. Server-side rate limits using metadata: at most one reaction change per 10 seconds per message and 60 per hour per account; exceeding returns a soft error and never penalizes the account on first occurrence (tolerance for accidental taps).
8. Upvotes: an owner can upvote a message in their 1:1 inbox, and a member can upvote a group-feed post. An upvote is stored on-device only, never sent to the server in any form, never visible to the author or other members, and is lost on reinstall. The app documents this.
9. The inbox offers an "Upvoted first" sort: upvoted messages ahead of the rest, recency-ordered within each set. Sorting works offline. A "Clear rankings" control deletes all local upvotes after one confirmation.
10. Reactions can be disabled per box. Disabling stops new reactions; existing reactions stay visible until the message is deleted; the toggle's copy states this before saving. Group-feed reaction settings live in brief 4.
11. Any received reaction can be reported. Filing a report attaches the reporter's decrypted copy of the reaction — and optionally the message — with explicit per-item consent; nothing is uploaded silently.
12. Reactions are encrypted with the same thread key material as the message they attach to. The server stores ciphertext and metadata only; inspecting stored envelopes must not reveal which emoji was chosen.
13. The server rejects reaction payloads exceeding the feature's fixed envelope size. Official clients render only allowlisted emoji IDs; unknown or malformed payloads render as a neutral placeholder, never as sender-chosen text or an image.
14. Deleting a message deletes its reactions for all parties on next sync. Removing a reaction updates the author's view on next sync. Blocking a sender hides their reactions along with their messages.
15. Accessibility: every reaction has a spoken label ("React with heart"), hit targets ≥ 44×44 dp, haptic and visual confirmation, and selection is not conveyed by color alone.

**Edge cases**

1. **Reaction bombing / notification harassment.** A sender reacts repeatedly or to old messages to flood notifications. Coalescing (criterion 6), rate limits (criterion 7), per-thread mute, and the existing block feature apply. No "reactions received" counter is exposed, so there is no score to chase.
2. **Downvote storms.** The product has no downvotes (criterion 4). The nearest analogues are mass reports and sustained pile-ons in group feeds; reports are rate-limited, reviewed, and never shown to the reported party. If any future feature introduces public aggregate scores, this brief's minimum bar applies: no negatives aggregated, no count below a k-anonymity threshold, one vote per account, and blast-radius caps. Nothing here ships such a feature.
3. **Sender identity or activity leaking through a reaction.** A reaction proves the sender read the reply. Countermeasures: delayed randomized delivery, coarse owner-side timestamps, no read receipts, no presence indicators, no live "reacted" events, no stable sender IDs across threads. Residual risk (behavioral inference: style, schedule, which message earns a reaction) cannot be eliminated and is disclosed in the sender-facing help.
4. **Reaction racing message deletion.** A reaction arrives for a message deleted moments earlier. The client drops reactions for messages it no longer holds; the server drops reactions addressed to deleted message IDs; the reactor sees no error beyond a failed state that silently resolves.
5. **Offline and out-of-order delivery.** With jitter and offline queues, a reaction can arrive before the reply it refers to, or twice. Clients reconcile by message ID; state is last-write-wins per actor; counts never go negative or above the number of actors.
6. **Forged reactions from modified clients.** An unlocked client sends arbitrary bytes. Server size caps (criterion 13) and rendering rules contain it. Because reactions cannot carry free text, there is no filterable content, and unknown payloads degrade to a placeholder.
7. **Blocking after a reaction exists.** Block hides the sender's messages and reactions; if the block is lifted, prior reactions reappear (they were not deleted). Copy states this.
8. **Verified sender reacting (brief 3 dependency).** Reactions never carry verification badges in v1, so a verified account's reaction does not narrow the sender set. If badges are ever added to reactions, they must follow brief 3's linkage rules.
9. **Group-feed correlation in small groups.** In a six-member group, reaction timing plus content narrows who reacted. Group feeds use coarse reaction timestamps, no live indicators, and no per-member reaction history; owners get no "who reacted" tool.
10. **Notification leakage on shared devices.** Reaction notifications are generic by default because a device may be shared. Detailed previews are opt-in and follow the user's existing notification settings.
11. **Device backup leaking local upvotes.** Upvotes live in a local database excluded from Android auto-backup and from any cloud sync, so a copied phone does not reveal rankings and a reinstall starts clean.
12. **Accidental taps and changing one's mind.** One free change within 60 seconds; then the 10-second and hourly limits apply. Removing a reaction is always allowed, subject only to the write budget.
13. **Disabling reactions mid-thread.** Existing reactions are kept; the setting copy explains that the author can still see them; re-enabling resumes acceptance. A setting never silently deletes history.
14. **System cards.** Only messages and replies are reactable; prompts, challenge cards, and group rule notices are not.

**Open questions**

- Should upvotes ever leave the device (encrypted sync across a user's own devices)? That needs server-stored ciphertext the viewer can decrypt — convenience versus a new metadata surface.
- Is a private ranking discoverable enough to be used, or will it feel like an invisible bookmark? If only the recipient benefits, is any visible confirmation needed?
- Should the fixed emoji set be chosen by a teen user panel rather than internal judgment? Emoji meaning drifts by platform and region.
- Should authors be able to hide an unwanted reaction from their own view (cosmetic only, without deleting the sender's action)?
- Do reactions count toward the existing points and challenges system, and if so, can that be farmed with reaction toggles?
- Is there any group context (e.g., community Q&A) where a coarse public upvote is worth the brigading risk, and what evidence would justify shipping the minimum bar in edge case 2?

---

## 3. Optional verified identity for senders (opt-in)

Decisions up front: verification asserts a checked claim — organization affiliation or 18+ age — attached per message as a server-signed attestation. The recipient learns the claim, never the person or account. Reactions never carry badges, and replies carry none by default. The sender-facing disclosure states plainly that the verification record is a deanonymization path under legal process, while message bodies remain encrypted.

**User story.** As an anonymous sender, I want to optionally attach a verified claim to a message, so that recipients can distinguish my message from an impersonator's without learning who I am.

**Acceptance criteria**

1. Off by default. Nothing about a sender is shown until the sender opts in per message (org claim) or per account (18+ claim) and enables display for a specific send or thread.
2. Two methods at launch: (a) organization affiliation — a one-time code to an address at a non-consumer mail domain, with domain ownership established once by an org admin (DNS TXT record or a registered admin mailbox); (b) 18+ age — handled by an external vendor; SecretMsg receives only pass/fail plus a vendor reference and stores no document images or identity fields.
3. The badge inventory is fixed: "Verified: member of {Organization}" and "Verified: 18+." No custom badge text, logos, or colors. Staff/support badges are visually and semantically distinct, grantable only by the platform.
4. Attestations are produced by the server, signed with the platform key, and travel outside the E2EE payload. Clients render a badge only when the signature verifies against the current key; on failure or unknown key, nothing is shown (fail-closed). Modified clients cannot mint badges because they do not hold the signing key.
5. Per-message default: each attestation contains no stable identifier the recipient's client can reuse — no verification ID, no account ID, no stable hash. Two verified messages from the same sender cannot be linked by the client. Behavioral inference is disclosed, not preventable.
6. Persistent identity is opt-in: a sender can enable a per-box alias (a generated phrase such as "cobalt-otter") so recipients can recognize the same verified sender within that box. The preview shows exactly what the recipient will see before enabling. Cross-box alias reuse is not offered.
7. Reactions never carry badges. Replies carry no badge unless the sender enables it for that thread; enabling shows a preview and a warning that the recipient can now link the reply to the original verified message.
8. The recipient-facing badge includes the claim text, the verification date, and a tap-through explanation: "SecretMsg checked this claim at send time. It does not tell you who the sender is. A verified claim is not a promise of good intent."
9. Before verifying, the sender sees a consent screen stating what is stored (org: domain, date, and a one-way HMAC of the address; age: vendor result, date, and vendor reference), retention and deletion behavior, and the legal-process path — a valid subpoena or equivalent to SecretMsg or the vendor can identify a verified sender. Canceling before completion stores nothing; a failed attempt stores nothing.
10. Recipient option per box: "accept only verified senders." When on, unverified incoming messages are blocked at submission with an explanation; existing threads continue; the box page shows the requirement. The option is presented as a trade-off (fewer senders), not a safety guarantee.
11. Platform revocation stops new attestations and marks already-delivered badges as "verification revoked" on next sync. Offline clients may show the old badge until they sync; this limitation is documented.
12. Verification records are deleted with the account. Org admins can disable a domain, stopping new badge issuance under it; existing badges remain as historical attestations unless revoked for abuse.
13. No profile or ranking effects: badges never change feed order, never power a "verified only" search, and never appear in rosters or aggregate counts. Group owners see per-message badges like any member and get no lookup tool.
14. Both clients (Flutter and the web box page) render the same badge logic; a badge is never rendered from local or user-supplied state.
15. ID-based verification is 18+ only and enforced at the vendor; a failed or underage attempt stores nothing. The org path is available for school accounts where the organization has enabled the domain; the setup flow states that the organization, not SecretMsg, is responsible for any consents its deployment requires.

**Edge cases**

1. **Verification defeats the purpose of the anonymous box.** A recipient may read "verified" as "known person" and pressure senders, or turn on verified-only mode and effectively narrow the sender pool. Countermeasures: per-message unlinkable attestations (criterion 5); badge copy that says the opposite (criterion 8); no rosters or lookups (criterion 13); a warning when a verified sender writes into a small group where the claim narrows to a few people. Residual: in a class of 30 with 6 verified accounts, the recipient knows it is one of six. This is inherent to verification and is described, not hidden.
2. **Identity leaking through a reaction or a reply.** Reactions carry no badges and replies carry none by default, so a badge never lands on an interaction the sender did not deliberately tag. Timing is the remaining channel: sender replies and reactions are jittered and shown with coarse timestamps (brief 2), so "the verified sender reacted at 3:02 a.m." is not viewable. A sender enabling badge-on-replies sees the resulting linkage in the preview.
3. **Forged badges.** Covered by server signing (criterion 4). Key rotation publishes a new key over HTTPS; clients fail closed. Replay by a modified client is prevented by binding each attestation to the message ID and a short expiry.
4. **Shared mailboxes and team addresses.** `office@school` proves a domain mailbox, not a person. Domain badges therefore read "affiliated with {Organization}" unless the address is an individual mailbox pattern and the org admin has enabled member-level claims. Domain admins can request disablement, which stops new claims.
5. **Org domain changes or is reissued.** A school closes or a domain lapses and is re-registered by someone else. Claims require current, verified DNS or mailbox control; existing badges are historical attestations tied to the claim date (criterion 8 shows the date) and are revoked on verified abuse. Whether historical badges should display "was verified on {date}" instead of a live "Verified" is an open question.
6. **Minors and COPPA/GDPR.** ID checks are 18+ only and store no documents. School deployments require the organization to assert it has the necessary authority; SecretMsg does not treat a school's consent as parental consent for under-13s (there are no under-13 accounts). For 13–17, only the org-affiliation path exists, and only when the organization enables the domain. Vendors are bound by a DPA; the data policy names the vendor and the retention period.
7. **One person, many accounts.** One org-email verification binds to one sender identity at a time; moving it requires re-verification. This prevents a verified "network" of accounts. The unit of verification is the unique address, not the person.
8. **Verified sender as a scam assist.** A badge can make a phishing pitch more convincing. Badges do not suppress the app's existing link-safety affordances, the recipient-facing copy states what verification does and does not mean (criterion 8), and repeated abuse revokes the badge.
9. **Attempted verification by an ineligible minor.** The vendor returns fail; nothing is stored; the user sees a neutral "couldn't verify" message, with no retry loop designed to wear them down and no age-related data retained.
10. **Legal process.** A verified sender is identifiable through the verification record (org HMAC/domain or vendor reference) under valid legal process; message bodies remain unreadable. This is stated to the sender before opting in, and counted in the transparency report.
11. **Vendor outage or breach.** Badge issuance pauses; existing badges stay valid; on breach, verified users are notified with what was exposed. SecretMsg's own store holds no document data to lose.
12. **Revocation fallout.** A revoked badge does not silently vanish — that would hide a safety signal; it shows "verification revoked" (criterion 11). False revocations are appealable; recipients are not told the reason.
13. **Group owner pressure.** In group boxes (brief 4), an owner cannot require an individual member to verify; they can only turn on verified-sender mode for the feed. Members who do not verify can still be members, and owners cannot query who is verified.
14. **"13+" badges.** No badge claims 13+; a trivially claimable badge would lower trust in all badges. Only 18+ and org claims exist.
15. **Deletion vs. delivered attestations.** Deleting the account deletes the verification record. Attestations already delivered to other devices cannot be recalled; the data policy states that delivered content is out of the platform's reach.

**Open questions**

- What exactly is verified — the account, the person, or a thread identity? A link-based sender without an account would have verification bound to that thread's sender token. Is one-thread portability the intended meaning, or should verification require an account?
- Is 18+ verification actually useful here, or does it create a false-trust badge and a data honeypot? Could organization claims alone carry the feature?
- How often must verification be renewed before "verified in 2026" becomes misleading?
- Should the recipient-side "verified-only" option exist at all, given it pressures senders toward deanonymization and may reduce the volume of honest messages?
- What evidence registers an organization's domain — is DNS control sufficient, and what happens when the person who registered it leaves?
- How should the platform handle a verified sender whose messages are consistently abusive — is pre-adjudication revocation acceptable?
- Does holding verification records change the platform's legal posture and obligations? This needs counsel, not product judgment.
- Should verification ever appear on sticker or share exports, or stay in-app only?

---

## 4. Group boxes for classrooms and communities

Decisions up front: a group box has two surfaces — (a) a group feed where members post anonymously to the whole group, and (b) member boxes where any member can send an anonymous message to one member; the owner has no access to member boxes, enforced by keys, not policy. Groups are unlisted, invite-only, and pseudonymous: the owner never sees member handles. Member posting to the feed is off by default. The platform cannot read feed content and cannot moderate before delivery; Filtered Words run on members' devices and are bypassable by modified clients, and owner moderation sees only what is in the feed or what members report.

**User story.** As a teacher or community moderator, I want a group box my members can join with one link, so that anonymous messages have one controlled home with rules, membership limits, and reporting that does not require the platform to read everyone's messages.
(Secondary) As a member of a class or community, I want to send and receive anonymous messages inside a group without my identity or the group's messages being exposed to the group owner, so that I can participate without losing my privacy.

**Acceptance criteria**

1. An account can create a group: name, rules text (≤500 characters), slug under `secretmsg.net/g/{slug}` (same syntax, validation, and reserved rules as custom handles, brief 1), and settings. Defaults: member posting OFF (owner posts only), join approval ON, reactions ON, generic notifications.
2. Group size: up to 20 members with no owner verification; up to 200 members requires the owner to hold org or 18+ verification (brief 3). Crossing 20 prompts the owner to verify within 14 days; otherwise the group goes read-only until verified, with no content loss.
3. Joining requires the app. Admission is an invite link plus a 6-digit code the owner can rotate; with approval on, the owner sees a join request from a pseudonym and can accept or decline without seeing the handle. Web visitors can reach only the group's public page, which can send a message to the owner's inbox if "accept outside messages" is enabled (default off).
4. The owner sees a roster of group pseudonyms, join dates, and membership state — never handles, emails, or account IDs. Members see only their own pseudonym. The roster is not visible to members.
5. Each member gets a stable per-group pseudonym (e.g., "quiet-pine-42") at join; a member may post under a fresh random pseudonym per post. No user-facing surface maps pseudonyms to handles; platform-side account linkage exists only for rate limits and bans.
6. Member boxes: any member can send an anonymous message to another member's in-app box (opt-out per member). Messages are encrypted to the member's key and cannot be decrypted by the owner or, in practice, by the platform. Member boxes are not web-addressable and cannot be enumerated from outside the group.
7. Feed encryption uses a group key. On member removal the key rotates, so removed members cannot read posts made after removal; new members cannot read posts made before they joined. The history policy is stated on the join screen.
8. Owner tools: delete a post (removes it for all members on next sync; screenshots cannot be recalled), delete all feed posts by one pseudonym, remove or mute a member, freeze the feed, set slow mode (minimum interval between a member's posts), turn member posting on or off, and turn reactions on or off. Every owner action is logged server-side as metadata for platform accountability.
9. Reporting: a member can report a feed post to the owner and/or the platform. An owner-facing report includes plaintext (the owner can already read the feed). A platform report uploads the reporter's decrypted copy of that item only, with explicit consent; the platform reviews that item, not the whole feed.
10. Platform-side metadata moderation: per-account and per-group limits on joins, invites, and posts; automatic throttling or freezing of a group on report-rate or burst signals; frozen groups are read-only; appeals within 7 days. No automated content decisions, because the platform cannot see content.
11. Before the first save, group creation shows an honest-limits screen: bodies are E2EE; the server cannot scan them; Filtered Words run on members' devices and are bypassable by modified clients; owner moderation cannot prevent screenshots; the platform acts on reports and metadata, not on unseen content.
12. Owners can post as the group, attributed "Group owner" rather than a pseudonym, for rules and notices. Owner posts are labeled as owner posts.
13. Official org groups: an owner with org verification can mark the group "Official: {Organization}." Unverified groups may not use "official" or an organization's exact name as their display name (client check, report path, takedown for impersonation). Verification never exposes member identities.
14. Ownership transfers to another verified member. An owner inactive for 90 days triggers a notification; the group goes read-only. The platform transfers ownership only with evidence of authority (school or organization) and notifies the current owner unless legally barred.
15. Data policy per group: group profile and slug, membership events, post metadata, and owner action logs are server-visible. Message bodies, handle-to-pseudonym mappings, and member-box routing are not exposed to the owner. No ad targeting may use group membership, message content, reactions, or verification status — a hard exclusion given the ad-supported free tier and the teen audience.
16. Deleting a group: 14-day grace period, member notification and export, then server-side deletion. Member boxes and their messages are deleted with the group; owners cannot export member-box content, because they never had access.

**Edge cases**

1. **Owner reading messages meant for one member.** Enforced by encryption: member-box messages are encrypted to the member's key. The owner's client never receives the ciphertext, and even if a malicious server delivered it, the owner could not decrypt it. API authorization also denies owner access. The owner cannot search, moderate, or export member boxes. Harassment inside a member box is handled by the platform in response to a report; the owner cannot intervene.
2. **Bullying in a captive audience (classroom).** An open anonymous feed in a class of 30 is a known harm pattern; members are socially compelled to join and read. Safeguards: member posting off by default; owner approval mode for posts; slow mode; local mute of the feed; leave without an announcement; no read receipts, no "seen by" lists, no public upvote counts; platform auto-throttle on report spikes; mandatory rules text. Honest limit: a determined bully with a modified client can still post; the response is removal, bans, and group freeze, not prevention.
3. **Membership discovery.** Invite links leak into group chats. Codes rotate; approval is on by default; groups are not listed or searchable; the roster is owner-only; members see no member list beyond pseudonyms in the feed. Join requests are pseudonymous, so the owner cannot discriminate by identity — and cannot take attendance from the app.
4. **Owner profiling members via metadata.** Post timestamps can be correlated with who was in class. Owner tools therefore never show per-member post histories or account data, and feed timestamps for others' posts are shown at day granularity. The platform keeps the account linkage needed for bans without exposing it to owners.
5. **Moderation at scale.** The platform cannot scan content, and client-side filtering is bypassable. Scale tools are structural: rate limits (joins, invites, posts), slow mode, approval mode, report-driven review of individual items, group freeze, and account bans. A 200-member group cannot be pre-moderated, and the join screen says so.
6. **Reaction and verification correlation in small groups.** With few members, a reaction or a badge can narrow authorship (briefs 2 and 3). Mitigations: coarse timestamps, no who-reacted tool, badge warnings; small groups see a plain note that anonymity is weaker in small rooms.
7. **Rejoining after removal / ban evasion.** Removed members can rejoin with a new account; accounts are cheap. Per-group join limits, per-account limits, approval, and code rotation slow this. The honest limit is that identity-poor accounts are cheap. Schools that want stronger entry control can require verification to join, accepting the anonymity trade (brief 3).
8. **Group slug squatting and school impersonation.** `g/lincoln-high` claimed by an unrelated account. Slug rules, no reassignment, an official path via org verification (criterion 13), and takedown for name impersonation; disputes follow the handle complaint process (brief 1).
9. **Cross-group spam and recruitment.** One account joins 50 groups to post ads or invites. Per-account and per-group join/post caps; approval default; slow mode; owner bans; invite links rate-limited per member.
10. **The owner is the bully.** Owner tools (delete, mute, remove, freeze) can be weaponized to silence dissent. Owner posts are labeled, and members can report the owner to the platform, which is not filtered through the owner. Platform actions (freeze, suspension, ownership transfer) exist independently of the owner.
11. **Minors, schools, and consent.** No under-13 accounts. Schools deploying groups are told they must handle their own authorizations; the platform offers a data-minimized setup (no names or emails required from students) and a DPIA summary. A school requesting admin access to a student-created group goes through an evidence process with notification, and never receives key access to member boxes.
12. **Group history and new members.** New members cannot read pre-join posts (criterion 7), protecting the original audience's expectation. This breaks classroom catch-up — a legitimate need that conflicts with the privacy default; see open questions.
13. **Group deletion and erasure.** Deleting the group deletes member boxes server-side after the grace period. A GDPR erasure for one member deletes the account and flags their feed posts for removal to clients on next sync. Copies already read, screenshotted, or exported cannot be recalled — stated in the data policy and the honest-limits screen.
14. **Notification leakage on shared devices.** A group name like "Teen Support" in a push notification can out a member. Notifications default to generic text ("New message in a group you joined"); detailed previews are opt-in per group.
15. **Ownership vacuum.** The owner graduates or deletes the account. The group goes read-only, the transfer path (criterion 14) applies, and ownership is never handed to a random member.
16. **Legal requests.** The platform can produce metadata (pseudonymous roster, timestamps, sizes, owner action logs) but not message bodies or mappings it does not hold. The transparency report says this.

**Open questions**

- Should anonymous member-posted feeds exist for minors at all, or should school-flagged groups be owner-announcement-only? The harm evidence around anonymous classroom boards is real, and platform moderation cannot read them.
- Is the 20-member verification threshold meaningful, or just a speed bump? What changes at scale is moderation load, not a number.
- What should new-member history visibility be? From-join protects original posters; catch-up helps classes. Could history be re-shared selectively with consent?
- Should member boxes exist inside groups at all, or does the feed cover the use case? Member boxes concentrate one-to-one risk; the feed is more visible and socially checked.
- Can a school legitimately own a group its students created? What is the minimum evidence, and does notification endanger the owner through retaliation?
- Is the pseudonymous roster workable for teachers who need attendance? If they must map names, that mapping should live outside SecretMsg — is that acceptable operationally?
- Should group owners ever see aggregate safety signals (e.g., "posts from this pseudonym were reported 5 times") without identities?
- How large can a group grow before E2EE fan-out and push load make it unusable, and does that cap conflict with community ambitions?
- Are group boxes free, limited, or bundled with `remove_ads`-style purchases? Monetization must never push groups toward more surveillance.

---

## Dependencies between briefs

- Brief 4 uses brief 1 (slug rules, no-reassignment), brief 2 (reactions and private upvotes), and brief 3 (owner/member verification paths).
- Brief 2 defines feed reaction semantics that brief 4 configures per group; brief 4 defines where public aggregate scores would first appear, and brief 2 sets the safety bar for them.
- Brief 3 depends on how sender identity is modeled: an account-based sender versus a link/thread sender (introduced more sharply by brief 4's member boxes). This is unresolved and listed as an open question in brief 3.
- All four depend on the shared constraints above, in particular the honest statement that client-side filtering is bypassable by a modified client.
