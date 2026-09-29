# SecretMsg (`secretmsg`)

> The open-source client application and platform for SecretMsg — a privacy-first anonymous question & message sharing platform built for Instagram Stories, TikTok, and direct links. Featuring real-time 3D dice roulette, viral TBH templates, comprehensive safety controls, and one-tap story stickers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Web & Android](https://img.shields.io/badge/Platform-Web%20%7C%20Android-green.svg)]()
[![Open Source](https://img.shields.io/badge/Open%20Source-Transparent%20%26%20Private-black.svg)]()

**SecretMsg** is an open-source, privacy-first anonymous messaging and viral TBH platform running on [`secretmsg.net`](https://secretmsg.net) — public boards and the account hub (`/login`, `/inbox`, `/settings`) on one host — with a native Flutter Android client in this repository. Anyone can receive candid questions, compliments, and social feedback via a personalized public link without revealing sender identity.

---

## Key Features

### 1. Profile & Safety Controls
- **Theme & Display**: System / Dark / Light appearance (default: follow the OS, live-switching via `prefers-color-scheme`; explicit choice stored per-device in Settings).
- **Inbox & Sharing**: share-link banner with copy button, social story-card generator, and live inbox with timestamps, sender-hint chips, and double-blind replies. The **web** inbox is pull-only and sends no email digests. The **Android** app can deliver new-message push through Google Firebase Cloud Messaging, with an inline reply action; the push payload is data-only and carries a preview truncated to 140 characters, never the full body (see [the privacy policy](https://secretmsg.net/p/privacy/)).
- **Filtered Words**: build custom blocklists of words, phrases, and emojis. The API enforces them server-side at compose time — the rejection happens even if the sender bypasses the client — so filtered content never reaches the inbox.
- **Pause Submissions**: suspend incoming submissions — timed pauses (30 min, 1 hour, 24 hours, 1 week) and permanent pause in the Android app; pause/resume toggle on web (`PATCH /api/me`). While paused, visitors see a friendly notice and submissions are rejected server-side.
- **Report**: flag abusive messages straight from the thread for operator review via `POST /api/report`.

> [!NOTE]
> **Sender blocking:** block the sender from any message (`POST /api/inbox/:id/block`) or manage the list in **Settings → Blocked Senders** / `GET /api/me/blocked`. Only the SHA-256 of the sender's anonymous device fingerprint is stored — senders stay anonymous to recipients. Blocked fingerprints are rejected server-side at compose time, alongside filtered words, pause, and reporting.

### 2. Owner Sign-In & Device Pairing
- **Handle + PIN (default)**: passwordless Auth V2 — pick a handle, set a 4–6 digit PIN, save 10 single-use backup codes. PIN changes and code refreshes live in Settings; recovery uses a backup code plus a new PIN.
- **Web Pairing**: the app can mint a short-lived (5-minute, single-use) pairing code — shown in **Settings → Pair a browser** — that the web login redeems for a **read-only** session. Paired browsers can read the inbox and report messages, but replying, purchases, settings changes, and account deletion stay on the signed-in device, enforced by scope checks in the API and reflected in the web UI.
- **Email code (legacy)**: 6-digit one-time code for pre-V2 email accounts; on mobile the JWT is stored in the Android Keystore via `flutter_secure_storage`.

### 3. Funding: Ads, and One Ad-Free Purchase

**SecretMsg is funded by advertising in the Android app.** There is no donation
button and no web checkout; the previous Polar.sh integration and the four
retired tiered perk products (`verified_badge`, `viewer_hints`, `sender_hints`,
`supporter_bundle`) are all gone. What remains is one Google Play product:

| Product | Type | Effect |
|---|---|---|
| `remove_ads` | One-time, non-subscription | Stops the app making ad requests, for the account, on every device |

- **Where ads appear**: Google AdMob serves a banner and an optional rewarded
  video **in the Android app only**. `secretmsg.net` loads no ad SDK, no ad
  exchange and no ad script, and serves no ads.
- **Consent**: personalised ads require consent in the EEA, the UK and
  Switzerland; declining leaves you on non-personalised ads rather than locking
  you out. Settings carries an **Ad privacy options** entry that opens Google's
  privacy options form, shown only when the SDK reports a choice is available to
  you.
- **Server-side only**: entitlements are recorded by the API
  (`POST /api/billing/google/verify`) after verifying the purchase against the
  Play Developer API, with idempotency and replay protection. There is no
  client-side unlock path.
- **Ad serving is behind a kill-switch.** `ADS_ENABLED` on the API Worker
  (public at `/api/config/ads`) is currently **off**, so no ads are being served
  in production even though the SDK and ad units ship in the build. The clients
  fail closed: a missing, errored or stale flag means no ads.

The account tier a purchase sets also still governs the supporter status that
gates viewer/sender hints and the badge, so the old perks are consequences of
`remove_ads` rather than separate products. Full detail, including what an ad
request does and does not contain, is in [`/p/privacy/`](https://secretmsg.net/p/privacy/).

### 4. Platform Sanitization & Handle Validation
- Strict handle requirements: board links and usernames must be **4–30 characters** (lowercase letters, numbers, underscores, hyphens, dots).
- Edge and client-side sanitization against XSS, script injection, and malformed inputs.
- Server-side rejection of recipient word filters, enforced regardless of sender.
- Automated bot screening is **required** before any message is accepted.
- **Rate limiting** on message sending, OTP requests, and other sensitive actions.
- **Server-side sanitization** scrubs hostile payloads so they never reach storage or other users.

### 5. Double-Blind Replies, Report Controls & Platform Guidance
- **Double-blind replies**: reply to a message without ever learning the sender's identity; each party sees only the exchange they belong to.
- **Report controls**: flag abusive messages straight from the thread for review.
- **Safety Center**: a dedicated hub plus child safety policy, community guidelines, and an online safety guide — all reachable from the footer.
- **Streamlined navigation**: top nav (Support the Project, Inbox/Settings when signed in, Get-Your-Link when not) plus a view-only banner for paired browsers; wraps cleanly on mobile, tablet, and desktop. The Support button opens a modal explaining the funding model — it is not a checkout.
- **Comprehensive footer directories** list every platform tool, guideline, and legal disclosure in one place.

---

## Repository Structure & Architecture

This repository contains the **open-source client applications and frontend packages**:

- **Web Platform** (`apps/web`): React 18 + Vite + Tailwind CSS single-page application, served from **`https://secretmsg.net`** as a Cloudflare static-assets Worker, and prerendered to 239 static HTML pages (215 blog posts plus 24 static routes). Routes: landing page, public message submission `/:username`, the dice roulette, sticker studio, blog, download, FAQ, and the safety/legal page tree at `/p/*`, plus the account hub (`/login`, `/inbox`, `/settings`, `/supporters`). Single-host app — there are no subdomain deployments.
  Configuration comes from `VITE_API_URL`, `VITE_PUBLIC_URL`, `VITE_TURNSTILE_SITE_KEY` and `VITE_USE_MOCK` (sane production defaults baked in; see `apps/web/README.md`).
- **Flutter Android App** (`apps/mobile-flutter`): Native Flutter (Dart) Android application — the primary mobile client — shipped as release **APK & AAB** builds (application id `net.secretmsg.android_app`). Implements the full mobile experience: public send pages with automated bot screening, story sticker studio, dice prompt roulette, handle-and-PIN sign-in, inbox & double-blind replies, settings with browser-pairing codes, the one-time `remove_ads` Play purchase, and all legal/safety screens, with deep links, FCM push notifications, and native haptics/share. The app also serves the AdMob banner and rewarded video.

### Published Android build

The current sideload release is **v1.6.10** (`versionCode 25`), served from
`secretmsg.net/downloads` and enumerated in
[`apps/web/src/lib/appVersion.ts`](apps/web/src/lib/appVersion.ts), which is the
single source of truth for the version, sizes and SHA-256 checksums that
`DownloadPage` and `LandingPage` both read. Per-ABI APKs are shipped because
Cloudflare Workers static assets reject any single file over 25 MiB.

| File | Size |
|---|---|
| `secretmsg-android-v1.6.10-arm64.apk` (recommended) | 13.1 MB |
| `secretmsg-android-v1.6.10-arm32.apk` (older phones) | 12.7 MB |
| `secretmsg-android-v1.6.10-x64.apk` (emulators, Chromebooks) | 13.3 MB |

Two release artifacts exist and they are signed with two different keys — the
Play upload AAB and the publicly downloaded sideload APKs are, to Android,
different apps that can never be upgraded into one another. That is not a
rounding error in the docs; it is a load-bearing operational fact, and
`apps/mobile-flutter/README.md` is the authoritative runbook for it.

> [!NOTE]
> To protect platform stability, user data privacy, and prevent abuse, backend services, database storage, and design-system prototypes are maintained in an isolated private repository. Client apps interact with services strictly via standard REST API contracts (`https://api.secretmsg.net`).

> [!NOTE]
> Retired hostnames: the former `app.` (account hub) and `m.` (mobile web) subdomains are removed. Everything is served from `secretmsg.net` — account routes live at `/login`, `/inbox`, `/settings`. The API allowlist no longer includes the retired hosts.

> [!IMPORTANT]
> **Canonical legal URLs are under `/p/`** — `/p/privacy/`, `/p/terms/`,
> `/p/cookies/`, `/p/disclaimer/` and the rest of the safety tree. A bare
> `/privacy` or `/terms` is a *username* route and returns the homepage shell,
> so never link to one. The canonical policy text lives in the React pages
> (`apps/web/src/pages/PrivacyPage.tsx` and siblings) and in the
> `apps/mobile-flutter` static content; the markdown under `LEGAL/` is a
> convenience copy, not the text users or Play reviewers see.

---

## Security Highlights (Production Hardening Pass — Sept 2026)

- **Fail-closed bot screening**: a missing or invalid human-check token ⇒ the message is rejected. No bypass paths.
- **Fail-closed payment grants**: the former `/api/donation/google-pay` endpoint (which granted entitlements from an unverified client POST) is disabled, as is the Polar.sh webhook that used to feed it. The only remaining purchase, the Android app's `remove_ads` product, is granted only after the purchase is verified server-side against the Google Play Developer API, with idempotency and replay protection.
- **No ad data, no ad code on the site**: the website loads no ad SDK and serves no ads. Ads exist only inside the Android app, and an ad request never carries message content, sender identity, your handle or your display name.
- **Scoped sessions**: web sessions created through pairing codes carry a `read` scope; the API rejects every write from them (replies, purchases, settings, deletion) with `403`.
- **CORS strict allowlist**: disallowed origins receive `Access-Control-Allow-Origin: null` and are blocked, rather than silently falling back to `secretmsg.net`.
- **Cryptographically clean tokens**: `generateRandomToken` uses rejection sampling to remove modulo bias.
- **Rate limiting**: message sending, OTP requests/verification, checkout, public profile views, and abuse reports are all rate-limited per IP / email.
- **Report-only CSP**: four security headers are generated from one list in `apps/web/src/security-headers.ts` — `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, and a **`Content-Security-Policy-Report-Only`** derived from what the site actually loads, with violation reports POSTed to the frontend Worker and logged to Workers Logs. The CSP is deliberately not enforcing yet: the fail-closed bot screening above means a wrong `connect-src` or `frame-src` would break signup, OTP, send and report at once. **HSTS is not set**, because Always Use HTTPS was only recently enabled and HSTS must not ship before the redirect is known to be stable. See [`apps/web/README.md`](apps/web/README.md#security-headers) for the two open questions the report-only policy is measuring and the criteria for promoting it.
- **Plaintext HTTP is closed**: Cloudflare's "Always Use HTTPS" is enabled, so `http://` returns a 301 to `https://`. One open item remains — no `www`→apex redirect is configured, so `www.secretmsg.net` currently serves `200` rather than redirecting, which means the site answers on two hosts.

---

## Quick Start (Local Development)

### 1. Prerequisites
- **Node.js**: v18.0.0 or later (the toolchain this repo is developed against runs v22.14.0 / npm 10.9.2)
- **npm**: v9.0.0 or later
- **Flutter**: for the Android app

### 2. Web Platform (`apps/web`)

```bash
git clone https://github.com/janasco/secretmsg.git
cd secretmsg
npm install
npm run dev        # serves apps/web via Vite
```

Open the printed local URL (default `http://localhost:5173`). The app targets the production API by default; point it at a local API with `VITE_API_URL`, or set `VITE_USE_MOCK=true` for a mock API mode with no backend at all (`apps/web/src/lib/mockApi.ts`). The API itself is developed in the separate private repository — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full workflow.

From the repository root, `npm run dev`, `npm run build` and `npm run preview`
delegate into the `apps/web` workspace member. `npm run typecheck` and
`npm test` exist only in `apps/web/package.json`, so run those from
`apps/web`. Production build: `npm run build` (`tsc`, then `vite build`, then
the prerender step that emits the 239 static HTML pages).

### 4. The gate

```bash
bash scripts/verify.sh
```

This is the **only** enforcement point for this repository. There is
deliberately no CI and no `.github` directory — that is a cost decision, not an
oversight, and the script runs the equivalent checks locally so the safety net
survives it. It runs 15 named checks and takes 10+ minutes: web typecheck,
tests, build and prerender, blog link integrity and the a11y colour scan;
`flutter analyze`, `flutter test` and the three Dart a11y checks; the private
API's tests and syntax checks; and a file-ownership reconcile plus assertion.
It must be green before any commit.

> **Ownership.** Everything here runs as root, so any file a build or an agent
> creates is owned by `root:root` and the human operator then cannot edit it in
> their own editor. The gate reconciles ownership of all git-tracked files and
> then asserts it, because the build's prerender step rewrites hundreds of
> tracked files on every run and undoes a one-off `chown`. If you create files
> by hand, `chown -R janasco:janasco` them.

### 3. Flutter Android App (`apps/mobile-flutter`)

```bash
cd apps/mobile-flutter
flutter pub get
flutter run                          # debug, on a connected device/emulator
flutter test && flutter analyze      # 162 unit/widget tests, and the linter
```

**Do not run a bare `flutter build apk --release` or `flutter build appbundle
--release` to produce a shippable artifact.** Both are expected to fail: the
Gradle build throws a `GradleException` on any release build that would carry
the placeholder AdMob app id, because AdMob identifiers are build-time inputs
that are never committed. That refusal is the feature — do not work around it by
substituting a placeholder or by editing the guard. Use the two scripts in
`scripts/`, which validate the identifier set before starting:

```bash
# Play upload AAB (upload key; Google Play App Signing re-signs it).
set -a; . /opt/secretmsg/.secrets/admob.env; set +a
scripts/build_release.sh aab --obfuscate --split-debug-info=build/symbols

# Sideload APKs, per-ABI, on the dedicated sideload key.
scripts/build_sideload.sh
```

See [`apps/mobile-flutter/README.md`](apps/mobile-flutter/README.md) for release signing, the `--obfuscate` recommendation, how download size should be measured, and why the Play and sideload tracks are two installs that never converge.

**Key Native Mobile Capabilities**:
- **Bot screening**: A native widget produces a verified human-check token before any message send (fail-closed at the API).
- **Authentication**: handle + PIN with backup codes; the JWT is stored in the Android Keystore via `flutter_secure_storage`.
- **Web Pairing**: Settings can mint a 5-minute code that pairs a browser to the inbox with read-only scope.
- **Google Play Billing**: the one-time `remove_ads` purchase, verified server-side against the Play Developer API before any entitlement is recorded.
- **Push Notifications**: new-message notifications via Firebase Cloud Messaging, data-only, with an inline reply action and a 140-character server-truncated preview.
- **Ads**: a Google AdMob banner and an optional rewarded video, behind a server kill-switch the app fails closed on. Settings → Support & legal carries an **Ad privacy options** entry that opens Google's privacy options form when the SDK reports a choice is available.
- **Deep Links**: `https://secretmsg.net/{username}` opens the public send screen; `https://secretmsg.net/inbox` opens the inbox.
- **Ranks, Challenges & Badges**: server-computed activity tiers (Newcomer → Icon from messages, replies, and supporter status) with a progress card, rotating daily challenges, check-in streaks, a 14-badge shelf, and one-time celebrations — all anonymous, no leaderboards, no public counts.
- **Native Haptics & Share Sheet**: Haptic feedback on rolls/sends plus the system share drawer for story stickers and links.

---

## Funding

SecretMsg is funded by **advertising in the Android app**. There is no donation
button and no web checkout — the Polar.sh integration that funded the project
earlier has been removed entirely, along with its tiered supporter products.
The single remaining purchase is the one-time `remove_ads` in-app product
described in [Funding](#3-funding-ads-and-one-ad-free-purchase) above.

Supporter counts are published as a number only, never a name, alias or list:
`GET /api/supporters` counts accounts holding the `remove_ads` entitlement and
exposes no identities.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development workflow, coding standards, and PR guidelines.

---

## License

This repository is licensed under the [MIT License](LICENSE).
