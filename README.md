# SecretMsg (`secretmsg`)

> The open-source client application for SecretMsg — an anonymous question & message sharing platform built for Instagram Stories, TikTok, and direct links. Featuring real-time 3D dice roulette, viral TBH templates, and one-tap story stickers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Web & Android](https://img.shields.io/badge/Platform-Web%20%7C%20Android-green.svg)]()
[![Open Source](https://img.shields.io/badge/Open%20Source-Transparent%20%26%20Private-black.svg)]()
[![Polar.sh: Issue Funding](https://img.shields.io/badge/Fund%20Issues-Polar.sh-blueviolet.svg)](https://polar.sh/janasco/secretmsg)

**SecretMsg** is an open-source, privacy-first anonymous messaging and viral TBH platform running on [`secretmsg.net`](https://secretmsg.net). Anyone can receive candid questions, compliments, and social feedback via a personalized public link without revealing sender identity.

This repository contains the **open-source client applications, mobile designs, and frontend packages**:
- **React + Vite Web App** (`apps/web`): Production client interface with responsive cards, OTP authentication, and story card exporters.
- **Mobile Design System & Screens** (`site/public`): 9 mobile screens built with the **Stitch Loop** featuring crisp white accents on dark obsidian canvas.
- **Android App Links & Capacitor** (`apps/mobile-android`): Android application wrapper and deep linking configuration.
- **Design Tokens & Constitution** (`.stitch`): Semantic design system tokens and screen constitution.

> [!NOTE]
> To protect platform stability, user data privacy, and prevent bot abuse, backend edge infrastructure (Cloudflare Workers, D1 database schemas, Turnstile verification, and Polar webhook processors) is maintained in an isolated private repository. This public client interacts with the edge platform strictly via standard REST API contracts (`https://api.secretmsg.net`).

---

## Quick Start (Local Development)

### 1. Prerequisites
- **Node.js**: v18.0.0 or later
- **npm**: v9.0.0 or later

### 2. Installation
Clone the repository and install dependencies:

```bash
git clone https://github.com/janasco/secretmsg.git
cd secretmsg
npm install
```

### 3. Environment Configuration
Copy the template environment file:

```bash
cp .env.example apps/web/.env
```

| Variable | Description | Default |
|---|---|---|
| `VITE_API_URL` | Edge API endpoint | `https://api.secretmsg.net` |
| `VITE_APP_URL` | Public web app domain | `https://secretmsg.net` |
| `VITE_USE_MOCK` | Offline mock mode (No API required) | `true` or `false` |
| `VITE_TURNSTILE_SITE_KEY` | Cloudflare Turnstile public key | `1x00000000000000000000AA` |

### 4. Running the Web App

#### Option A: Offline Mock Mode (Recommended for UI & Design Contributors)
If you do not have an API backend running, enable mock mode in `apps/web/.env`:
```ini
VITE_USE_MOCK="true"
```
Then start the development server:
```bash
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser. All features (composing messages, reading inbox, double-blind replies, and supporter wall) will work locally using browser storage!

#### Option B: Live Edge API Mode
Set `VITE_USE_MOCK="false"` in `apps/web/.env`. The client will connect directly to `https://api.secretmsg.net`.

---

## Mobile Screen Prototypes (`site/public/`)

The mobile application prototype consists of 9 fully-linked screens:
1. **`index.html`** — Home & Explore (Live search, categories, viral templates)
2. **`compose.html`** — Compose Anonymous Message (Prompt filler, vibes, double-blind reply token)
3. **`dice.html`** — TBH Roulette & 3D Interactive Three.js Dice
4. **`sticker-studio.html`** — 9:16 Instagram/Snapchat Story Sticker Exporter
5. **`inbox.html`** — Secret Inbox & Message Previews
6. **`message-detail.html`** — Message Thread & Double-Blind Reply
7. **`profile.html`** — Vanity Handle Hub & Vector SVG QR Code
8. **`supporters.html`** — Supporters Wall & Polar.sh Perks
9. **`settings.html`** — Privacy & Security Vault (Zero-Log Guarantee, nuclear data wipes)

You can preview them directly in any browser or with:
```bash
npx serve site/public
```

---

## Architecture & File Tree

```
secretmsg-public/
├── .env.example               # Safe environment configuration template
├── .gitignore                 # Exclusion rules
├── README.md                  # Main documentation
├── CONTRIBUTING.md            # Guidelines for open source contributors
├── LICENSE                    # MIT License
├── LEGAL/
│   ├── TERMS_OF_SERVICE.md    # Terms of Service
│   ├── PRIVACY_POLICY.md      # Zero-Log Privacy Policy
│   └── DISCLAIMER.md          # Open-Source Disclaimer
├── apps/
│   ├── web/                   # React 18 + Vite + Tailwind CSS web application
│   │   ├── src/
│   │   │   ├── components/    # Story cards, Compose modals, QR modal, Toast
│   │   │   ├── pages/         # Landing, SendMessage, Inbox, Settings, Legal
│   │   │   └── lib/           # ApiClient and MockApiClient
│   │   └── package.json
│   └── mobile-android/        # Capacitor Android configuration & App Links
├── site/
│   └── public/                # 9 Stitch Loop mobile HTML/CSS/JS screens
└── .stitch/                   # Design system tokens and screen constitution
```

---

## Community & Issue Funding ([Polar.sh](https://polar.sh/janasco/secretmsg))

SecretMsg is funded transparently through **[Polar.sh](https://polar.sh/janasco/secretmsg)**:
- **Issue Funding**: Backers can pledge funding directly to GitHub issues (e.g. native iOS app, new sticker themes, or encryption tools).
- **Supporter Perks**: Donors receive custom vanity handles and community wall recognition.

---

## Security & Reporting

To report security vulnerabilities, abuse vectors, or UI bugs, please review our [Security Policy](LEGAL/PRIVACY_POLICY.md) or open an issue on GitHub.

---

## License

This repository is licensed under the [MIT License](LICENSE).
