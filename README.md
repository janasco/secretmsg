# SecretMsg (`secretmsg`)

> The open-source client application and platform for SecretMsg — a privacy-first anonymous question & message sharing platform built for Instagram Stories, TikTok, and direct links. Featuring real-time 3D dice roulette, viral TBH templates, granular supporter perks, comprehensive safety controls, and one-tap story stickers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Web & Android](https://img.shields.io/badge/Platform-Web%20%7C%20Android-green.svg)]()
[![Open Source](https://img.shields.io/badge/Open%20Source-Transparent%20%26%20Private-black.svg)]()
[![Polar.sh: Issue Funding](https://img.shields.io/badge/Fund%20Issues-Polar.sh-blueviolet.svg)](https://polar.sh/janasco/secretmsg)

**SecretMsg** is an open-source, privacy-first anonymous messaging and viral TBH platform running on [`secretmsg.net`](https://secretmsg.net) and [`m.secretmsg.net`](https://m.secretmsg.net). Anyone can receive candid questions, compliments, and social feedback via a personalized public link without revealing sender identity.

---

## What's New & Core Capabilities

### 1. Account Preferences & Safety Controls
- **Preferences → Appearance**: 3-choice theme engine supporting:
  - *Always Light Mode*
  - *Always Dark Mode*
  - *Follow System Settings (Default)*
- **Preferences → Notifications**:
  - Reminders to post & share active links
  - Real-time new message alerts
  - Team SecretMsg occasional game prompts
  - Daily Question of the Day (QOTD) reminders
- **Safety Controls → Hidden Words**: Create custom blocklists of words, phrases, and emojis to automatically reject unwanted messages at compose time or quarantine them in inbox.
- **Safety Controls → Block Users**: View and manage blocked sender devices with instant unblock toggles.
- **Safety Controls → Pause My Link**: Temporarily or permanently halt incoming submissions (1 hour, 6 hours, 24 hours, or indefinite) with friendly public pause notices.

### 2. Modular Feature Donation Plans (Supporter Perks)
Supporters can unlock standalone individual features or the full VIP bundle:
- **Verified Badge ($2)**: Official verified checkmark displayed on public boards, compose headers, and recipient profiles.
- **Viewer Hints ($3)**: Live viewer counter tracking real-time impressions on user links.
- **Sender Hints ($4)**: Clues and approximate device/context signals for received messages.
- **Complete VIP Pass ($7)**: All premium perks combined.

### 3. Platform Sanitization & Handle Validation
- Strict handle requirements: Board links and usernames must be **at least 4 characters** (alphanumeric, underscores, hyphens, dots).
- Edge and client-side sanitization against XSS, script injection, and malformed inputs.

### 4. Streamlined Navigation & Responsive Design
- Clean 2-item top navigation (`Explore Demo` + `Safety`) ensuring rock-solid stability and zero layout wrapping across mobile, tablet, and desktop screens.
- Comprehensive footer directories for all platform tools, guidelines, and legal disclosures.

---

## Repository Structure

This repository contains the **open-source client applications, mobile designs, and frontend packages**:
- **Mobile Web Pages & Screens** (`site/public`): 10+ mobile and desktop screens built with high-contrast accessibility, dark/light modes, and large legible typography.
- **Android App Links & Capacitor** (`apps/mobile-android`): Android application wrapper and deep linking configuration.

> [!NOTE]
> To protect platform stability, user data privacy, and prevent abuse, backend edge workers, database storage, and Stitch design system prototypes (`.stitch`) are maintained in an isolated private repository (`secretmsg-private`). This public client interacts with the edge services strictly via standard REST API contracts (`https://api.secretmsg.net`).

---

## Screens & Prototype Directory (`site/public/`)

1. **`landing.html`** — Minimalist Desktop/Mobile Landing Page (2-link header, direct board creation, instant handle claims).
2. **`index.html`** — Mobile Home & Explore (14,000+ viral templates, search, categories).
3. **`compose.html`** — Compose Anonymous Message (Input sanitization, pause enforcement, hidden word rejection).
4. **`dice.html`** — 3D Interactive Three.js Roulette Dice & Prompt Shuffle.
5. **`sticker-studio.html`** — 9:16 Instagram/Snapchat Story Sticker Exporter.
6. **`inbox.html`** — Anonymous Inbox (Quarantine tabs, real-time unread badges, viewer counter).
7. **`message-detail.html`** — Message Thread, Sender Hints unlock, double-blind replies, and Report/Block controls.
8. **`profile.html`** — Vanity Handle Hub, Verified Badge status, and Vector SVG QR Code.
9. **`supporters.html`** — Modular Feature Donation Wall ($2 Verified Badge, $3 Viewer Hints, $4 Sender Hints, $7 Complete VIP).
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

### 3. Android Mobile Application (`apps/mobile-android`)

Built with **Capacitor 6** with native hardware navigation, status bar theming, haptics, and social sharing:

```bash
# Sync web assets and Capacitor Android plugins
npm run android:sync

# Open in Android Studio
npm run android:open

# Or build debug APK directly via Gradle
npm run android:build
```

**Key Native Mobile Capabilities**:
- **Hardware Back Button Handling**: Intercepts Android back presses to dismiss active modals, overlays, and drawers before navigating back or prompting exit on the root screen.
- **Dynamic Status & System Bar Sync**: Automatically updates system status bar styling (`#0B0E14` dark / `#FFFFFF` light) in lockstep with user theme preferences.
- **Tactile Haptic Feedback**: Delivers subtle physical feedback on 3D dice roulette rolls, button taps, and link copying.
- **Native Social Share Sheet**: Triggers the native Android share drawer for sharing profile links and 9:16 story stickers to Instagram, Snapchat, and WhatsApp.
- **App Links & Deep Linking**: Auto-verifies `https://secretmsg.net/@handle`, `https://m.secretmsg.net`, and custom `secretmsg://` intents.

---


## Community & Issue Funding ([Polar.sh](https://polar.sh/janasco/secretmsg))

SecretMsg is funded transparently through **[Polar.sh](https://polar.sh/janasco/secretmsg)**:
- **Issue Funding**: Backers can pledge funding directly to GitHub issues.
- **Supporter Perks**: Donors unlock Verified Badges, Viewer Hints, and Sender Hints directly on the platform.

---

## License

This repository is licensed under the [MIT License](LICENSE).
