# SecretMsg (`secretmsg`)

> The open-source client application and platform for SecretMsg — a privacy-first anonymous question & message sharing platform built for Instagram Stories, TikTok, and direct links. Featuring real-time 3D dice roulette, viral TBH templates, granular supporter perks, comprehensive safety controls, and one-tap story stickers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Web & Android](https://img.shields.io/badge/Platform-Web%20%7C%20Android-green.svg)]()
[![Open Source](https://img.shields.io/badge/Open%20Source-Transparent%20%26%20Private-black.svg)]()
[![Polar.sh: Issue Funding](https://img.shields.io/badge/Fund%20Issues-Polar.sh-blueviolet.svg)](https://polar.sh/janasco/secretmsg)

**SecretMsg** is an open-source, privacy-first anonymous messaging and viral TBH platform running on [`secretmsg.net`](https://secretmsg.net) with a dedicated account hub at [`app.secretmsg.net`](https://app.secretmsg.net) and a native Flutter Android client in this repository. Anyone can receive candid questions, compliments, and social feedback via a personalized public link without revealing sender identity.

---

## Key Features

### 1. Account Preferences & Safety Controls
- **Appearance**: a 3-choice theme engine that switches between:
  - *Always Light Mode*
  - *Always Dark Mode*
  - *Follow System Settings (Default)*
- **Notifications**: opt-in alerts covering link-sharing reminders, incoming-message pings, occasional team prompts, and Daily Question of the Day (QOTD) nudges.
- **Hidden Words**: build custom blocklists of words, phrases, and emojis that auto-reject matching input at compose time or shunt it to the inbox quarantine.
- **Block Users**: review and manage blocked sender devices with instant unblock toggles.
- **Pause My Link**: suspend incoming submissions for 1 hour, 6 hours, 24 hours, or indefinitely, with a friendly public notice shown while paused.
- **Owner login**: secure email one-time-password (OTP) sign-in for the private inbox and settings.

### 2. Modular Supporter Perks
Supporters can purchase standalone perks individually or bundle them into the full VIP pass, checkout handled via [Polar.sh](https://polar.sh/janasco/secretmsg):

| Perk | Price | Effect |
|---|---|---|
| **Verified Badge** | $5 | Official verified checkmark on public boards, compose headers, and recipient profiles |
| **Viewer Hints** | $5 | Live viewer counter tracking real-time impressions on user links |
| **Sender Hints** | $5 | Clues and approximate device/context signals for received messages |
| **Complete VIP Pass** | all perks | Requires donor tier support. Tiers: `Coffee Backer` ($5+), `Silver Patron` ($15+), `Golden Guardian` ($25+) |

Perks are granted **only via the signature-verified Polar webhook** after a successful checkout. There is no client-side unlock path.

### 3. Platform Sanitization & Handle Validation
- Strict handle requirements: board links and usernames must be **at least 4 characters** (alphanumeric, underscores, hyphens, dots).
- Edge and client-side sanitization against XSS, script injection, and malformed inputs.
- Server-side rejection of recipient-hidden words, enforced regardless of sender.
- Automated bot screening is **required** before any message is accepted.
- **Rate limiting** on message sending, OTP requests, and other sensitive actions.
- **Server-side sanitization** scrubs hostile payloads so they never reach storage or other users.

### 4. Double-Blind Replies, Report Controls & Platform Guidance
- **Double-blind replies**: reply to a message without ever learning the sender's identity; each party sees only the exchange they belong to.
- **Report controls**: flag abusive messages straight from the thread for review.
- **Safety Center**: a dedicated hub plus child safety policy, community guidelines, and an online safety guide — all reachable from the footer.
- **Streamlined navigation**: a clean 2-item top nav (`Explore Demo` + `Safety`) that stays stable and wraps cleanly on mobile, tablet, and desktop.
- **Comprehensive footer directories** list every platform tool, guideline, and legal disclosure in one place.

---

## Repository Structure & Architecture

This repository contains the **open-source client applications, mobile designs, and frontend packages**:
- **Desktop & Responsive Web App** (`apps/web`): The modern responsive web platform deployed to **`https://secretmsg.net`**. Features wide desktop inbox dashboards, responsive navbar, modals, and client-side routing.
- **Flutter Android App** (`apps/mobile-flutter`): Native Flutter (Dart) Android application — the primary mobile client — shipped as release **APK & AAB** builds. Implements the full mobile experience: public send pages with automated bot screening, story sticker studio, dice prompt roulette, email-OTP sign-in, inbox & double-blind replies, settings & safety controls, supporters wall, and all legal/safety screens, with deep links and native haptics/share.
- **Legacy Prototypes & Wrappers** (`site/public`, `apps/mobile-android`): Earlier touch-optimized static HTML prototype and its legacy Android wrapper. No longer deployed (the `m.secretmsg.net` hostname has been decommissioned); kept for reference.

> [!NOTE]
> To protect platform stability, user data privacy, and prevent abuse, backend services, database storage, and design-system prototypes are maintained in an isolated private repository. Client apps interact with services strictly via standard REST API contracts (`https://api.secretmsg.net`).

---

## Security Highlights (Production Hardening Pass — Sept 2026)

- **Fail-closed bot screening**: a missing or invalid human-check token ⇒ the message is rejected. No bypass paths.
- **Fail-closed payment grants**: the former `/api/donation/google-pay` endpoint (which granted paid perks from an unverified client POST) is disabled. Perks now come exclusively from the HMAC-verified Polar webhook.
- **CORS strict allowlist**: disallowed origins receive `Access-Control-Allow-Origin: null` and are blocked, rather than silently falling back to `secretmsg.net`.
- **Cryptographically clean tokens**: `generateRandomToken` uses rejection sampling to remove modulo bias.
- **Rate limiting**: message sending, OTP requests/verification, checkout, public profile views, and abuse reports are all rate-limited per IP / email.

## Screens & Prototype Directory (`site/public/`)

1. **`landing.html`** — Minimalist Desktop/Mobile Landing Page (2-link header, direct board creation, instant handle claims).
2. **`index.html`** — Mobile Home & Explore (14,000+ viral templates, search, categories).
3. **`compose.html`** — Compose Anonymous Message (Input sanitization, pause enforcement, hidden word rejection).
4. **`dice.html`** — 3D Interactive Three.js Roulette Dice & Prompt Shuffle.
5. **`sticker-studio.html`** — 9:16 Instagram/Snapchat Story Sticker Exporter.
6. **`inbox.html`** — Anonymous Inbox (Quarantine tabs, real-time unread badges, viewer counter).
7. **`message-detail.html`** — Message Thread, Sender Hints unlock, double-blind replies, and Report/Block controls.
8. **`profile.html`** — Vanity Handle Hub, Verified Badge status, and Vector SVG QR Code.
9. **`supporters.html`** — Modular Donation Wall ($5 Verified Badge, $5 Viewer Hints, $5 Sender Hints).
10. **`settings.html`** — Preferences (Notifications & 3-Choice Appearance) & Safety Controls (Hidden Words, Block Users, Pause My Link).
11. **`safety.html` & Sub-pages** — Comprehensive Safety Center, Child Safety Policy, Online Safety Guide, Crisis Hotlines.

---

## Quick Start (Local Development)

### 1. Prerequisites
- **Node.js**: v18.0.0 or later
- **npm**: v9.0.0 or later

### 2. Running the Public Prototype
Clone the repository and serve the static files:

```bash
git clone https://github.com/janasco/secretmsg.git
cd secretmsg
npx serve site/public
```

Open [http://localhost:3000](http://localhost:3000) in your browser. All client features (theme toggle, local storage mock data, board generation, and safety controls) function out-of-the-box.

### 3. Flutter Android App (`apps/mobile-flutter`)

The mobile client is a native Flutter application. Build the release APK and AAB:

```bash
cd apps/mobile-flutter
flutter pub get
flutter build apk --release        # outputs build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release  # outputs build/app/outputs/bundle/release/app-release.aab
```

**Key Native Mobile Capabilities**:
- **Bot screening**: A native widget produces a verified human-check token before any message send (fail-closed at the API).
- **OTP Authentication**: Email one-time-password sign-in; the JWT is stored in the Android Keystore via `flutter_secure_storage`.
- **Deep Links**: `https://secretmsg.net/{username}` opens the public send screen; `https://app.secretmsg.net/inbox` opens the inbox.
- **Native Haptics & Share Sheet**: Haptic feedback on rolls/sends plus the system share drawer for story stickers and links.

---

## Community & Issue Funding ([Polar.sh](https://polar.sh/janasco/secretmsg))

SecretMsg is funded transparently through **[Polar.sh](https://polar.sh/janasco/secretmsg)**:
- **Issue Funding**: Backers can pledge funding directly to GitHub issues.
- **Supporter Perks**: Donors unlock Verified Badges, Viewer Hints, and Sender Hints directly on the platform.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for coding standards, safety controls, and PR guidelines.

---

## License

This repository is licensed under the [MIT License](LICENSE).