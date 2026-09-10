# SecretMsg (`secretmsg`)

> The open-source client application and platform for SecretMsg — a privacy-first anonymous question & message sharing platform built for Instagram Stories, TikTok, and direct links. Featuring real-time 3D dice roulette, viral TBH templates, granular supporter perks, comprehensive safety controls, and one-tap story stickers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Web & Android](https://img.shields.io/badge/Platform-Web%20%7C%20Android-green.svg)]()
[![Open Source](https://img.shields.io/badge/Open%20Source-Transparent%20%26%20Private-black.svg)]()
[![Polar.sh: Issue Funding](https://img.shields.io/badge/Fund%20Issues-Polar.sh-blueviolet.svg)](https://polar.sh/janasco/secretmsg)

**SecretMsg** is an open-source, privacy-first anonymous messaging and viral TBH platform running on [`secretmsg.net`](https://secretmsg.net) with a dedicated account hub at [`app.secretmsg.net`](https://app.secretmsg.net) and a native Flutter Android client in this repository. Anyone can receive candid questions, compliments, and social feedback via a personalized public link without revealing sender identity.

---

## Key Features

### 1. Profile & Safety Controls
- **Theme & Display**: a 3-choice theme engine that switches between:
  - *Always Light Mode*
  - *Always Dark Mode*
  - *Follow System Settings (Default)*
- **Alerts & Notifications**: opt-in alerts covering link-sharing reminders, incoming-message pings, occasional team prompts, and Daily Question of the Day (QOTD) nudges.
- **Filtered Words**: build custom blocklists of words, phrases, and emojis. The API enforces them server-side at compose time — the rejection happens even if the sender bypasses the client — so filtered content never reaches the inbox.
- **Pause Submissions**: suspend incoming submissions for 1 hour, 6 hours, 24 hours, or indefinitely, with a friendly public notice shown while paused.
- **Report**: flag abusive messages straight from the thread for operator review via `POST /api/report`.

> [!NOTE]
> **Sender blocking is not currently implemented.** Safety controls today are filtered words, pause, and reporting. There is no per-sender block list: anonymous messages arrive without a persistent sender identifier to block. See the Safety Center for the controls that exist.

### 2. Owner Sign-In & Device Pairing
- **Email OTP**: passwordless sign-in with a 6-digit one-time code; the session token is stored in the Android Keystore via `flutter_secure_storage` on mobile.
- **Web Pairing**: the app can mint a short-lived (5-minute, single-use) pairing code — shown in **Settings → Pair a browser** — that `app.secretmsg.net` redeems for a **read-only** session. Paired browsers can read the inbox and report messages, but replying, purchases, settings changes, and account deletion stay on the signed-in device, enforced by scope checks in the API and reflected in the web UI.

### 3. Modular Supporter Perks
Supporters can purchase standalone perks individually or bundle them into the full VIP pass:

| Perk | Price | Effect |
|---|---|---|
| **Verified Badge** | $5 | Official verified checkmark on public boards, compose headers, and recipient profiles |
| **Viewer Hints** | $5 | Live viewer counter tracking real-time impressions on user links |
| **Sender Hints** | $5 | Clues and approximate device/context signals for received messages |
| **Complete VIP Pass** | all perks | Requires donor tier support. Tiers: `Coffee Backer` ($5+), `Silver Patron` ($15+), `Golden Guardian` ($25+) |

Two verified grant paths exist; there is no client-side unlock path:
- **Web**: checkout via [Polar.sh](https://polar.sh/janasco/secretmsg); perks are granted only by the HMAC-verified Polar webhook after a successful checkout.
- **Android**: Google Play Billing purchases, verified server-side against the Play Developer API (`POST /api/billing/google/verify`) with idempotency and replay protection before a perk is granted.

### 4. Platform Sanitization & Handle Validation
- Strict handle requirements: board links and usernames must be **at least 4 characters** (alphanumeric, underscores, hyphens, dots).
- Edge and client-side sanitization against XSS, script injection, and malformed inputs.
- Server-side rejection of recipient word filters, enforced regardless of sender.
- Automated bot screening is **required** before any message is accepted.
- **Rate limiting** on message sending, OTP requests, and other sensitive actions.
- **Server-side sanitization** scrubs hostile payloads so they never reach storage or other users.

### 5. Double-Blind Replies, Report Controls & Platform Guidance
- **Double-blind replies**: reply to a message without ever learning the sender's identity; each party sees only the exchange they belong to.
- **Report controls**: flag abusive messages straight from the thread for review.
- **Safety Center**: a dedicated hub plus child safety policy, community guidelines, and an online safety guide — all reachable from the footer.
- **Streamlined navigation**: a clean 2-item top nav (`Explore Demo` + `Safety`) that stays stable and wraps cleanly on mobile, tablet, and desktop.
- **Comprehensive footer directories** list every platform tool, guideline, and legal disclosure in one place.

---

## Repository Structure & Architecture

This repository contains the **open-source client applications and frontend packages**:

- **Web Platform** (`apps/web`): React 18 + Vite + Tailwind CSS single-page application serving **both** public sites. The same build is deployed to:
  - **`https://secretmsg.net`** — landing page, public message submission `/:username`, the dice roulette, sticker studio, and legal/safety pages.
  - **`https://app.secretmsg.net`** — the authenticated account hub: login (pairing code or email OTP), inbox, double-blind replies, and settings.
  Configuration comes from `VITE_API_URL`, `VITE_PUBLIC_URL`, and `VITE_ACCOUNT_APP_URL` (sane production defaults baked in; see `apps/web/README.md`).
- **Flutter Android App** (`apps/mobile-flutter`): Native Flutter (Dart) Android application — the primary mobile client — shipped as release **APK & AAB** builds (application id `net.secretmsg.android_app`). Implements the full mobile experience: public send pages with automated bot screening, story sticker studio, dice prompt roulette, email-OTP sign-in, inbox & double-blind replies, settings with browser-pairing codes, Google Play Billing perks, supporters wall, and all legal/safety screens, with deep links and native haptics/share.
- **Legacy Prototypes & Wrappers** (`site/public`, `apps/mobile-android`): Earlier touch-optimized static HTML prototype and its legacy Android wrapper. No longer deployed (the `m.secretmsg.net` hostname has been decommissioned); kept for reference.

> [!NOTE]
> To protect platform stability, user data privacy, and prevent abuse, backend services, database storage, and design-system prototypes are maintained in an isolated private repository. Client apps interact with services strictly via standard REST API contracts (`https://api.secretmsg.net`).

---

## Security Highlights (Production Hardening Pass — Sept 2026)

- **Fail-closed bot screening**: a missing or invalid human-check token ⇒ the message is rejected. No bypass paths.
- **Fail-closed payment grants**: the former `/api/donation/google-pay` endpoint (which granted paid perks from an unverified client POST) is disabled. Web perks come only from the HMAC-verified Polar webhook; Android perks only from Play purchases verified server-side against the Google Play Developer API.
- **Scoped sessions**: web sessions created through pairing codes carry a `read` scope; the API rejects every write from them (replies, purchases, settings, deletion) with `403`.
- **CORS strict allowlist**: disallowed origins receive `Access-Control-Allow-Origin: null` and are blocked, rather than silently falling back to `secretmsg.net`.
- **Cryptographically clean tokens**: `generateRandomToken` uses rejection sampling to remove modulo bias.
- **Rate limiting**: message sending, OTP requests/verification, checkout, public profile views, and abuse reports are all rate-limited per IP / email.

---

## Legacy Screens (`site/public/`, kept for reference)

The decommissioned mobile prototype remains in the repo: `landing.html`, `index.html` (viral template gallery), `compose.html`, `dice.html` (Three.js roulette), `sticker-studio.html`, `inbox.html`, `message-detail.html`, `profile.html`, `supporters.html`, `settings.html`, and the `safety.html` hub with sub-pages. The live products are `apps/web` and `apps/mobile-flutter`.

---

## Quick Start (Local Development)

### 1. Prerequisites
- **Node.js**: v18.0.0 or later
- **npm**: v9.0.0 or later
- **Flutter**: for the Android app

### 2. Web Platform (`apps/web`)

```bash
git clone https://github.com/janasco/secretmsg.git
cd secretmsg
npm install
npm run dev        # serves apps/web via Vite
```

Open the printed local URL (default `http://localhost:5173`). The app targets the production API by default; point it at a local API with `VITE_API_URL`. A mock API mode exists for offline UI work (`apps/web/src/lib/mockApi.ts`). The API itself is developed in the separate private repository — see [`CONTRIBUTING.md`](CONTRIBUTING.md) for the full workflow.

Production build: `npm run build` (runs `tsc` then `vite build`).

### 3. Flutter Android App (`apps/mobile-flutter`)

```bash
cd apps/mobile-flutter
flutter pub get
flutter run                          # debug, on a connected device/emulator
flutter test && flutter analyze      # unit tests and lints
flutter build apk --release          # release APK
flutter build appbundle --release    # Play Store bundle
```

See [`apps/mobile-flutter/README.md`](apps/mobile-flutter/README.md) for release signing, the `--obfuscate` recommendation, and how download size should be measured.

**Key Native Mobile Capabilities**:
- **Bot screening**: A native widget produces a verified human-check token before any message send (fail-closed at the API).
- **OTP Authentication**: Email one-time-password sign-in; the JWT is stored in the Android Keystore via `flutter_secure_storage`.
- **Web Pairing**: Settings can mint a 5-minute code that pairs a browser to the inbox with read-only scope.
- **Google Play Billing**: Supporter perks purchased in-app, verified server-side before granting.
- **Deep Links**: `https://secretmsg.net/{username}` opens the public send screen; `https://app.secretmsg.net/inbox` opens the inbox.
- **Native Haptics & Share Sheet**: Haptic feedback on rolls/sends plus the system share drawer for story stickers and links.

---

## Community & Issue Funding ([Polar.sh](https://polar.sh/janasco/secretmsg))

SecretMsg is funded transparently through **[Polar.sh](https://polar.sh/janasco/secretmsg)**:
- **Issue Funding**: Backers can pledge funding directly to GitHub issues.
- **Supporter Perks**: Donors unlock Verified Badges, Viewer Hints, and Sender Hints directly on the platform.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for the development workflow, coding standards, and PR guidelines.

---

## License

This repository is licensed under the [MIT License](LICENSE).
