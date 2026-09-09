# SecretMsg Account Management App (`app.secretmsg.net`)

This application is the dedicated, authenticated account management portal for the [SecretMsg](https://secretmsg.net) platform.

---

## Domain Architecture

- **`app.secretmsg.net`**: The application built from this directory (`apps/web`). It manages:
  - Board authentication & login (`/login`)
  - Anonymous message inbox feed with view counts & timestamps (`/inbox`)
  - Message details & double-blind anonymous replies (`/reply/:token`)
  - Profile customization & verified badges (`/settings`)
  - Word filters, blocklist, and link pause controls (`/settings`)
  - Story card & sticker generation studio
  - Supporter perks & Polar.sh donation unlocks (`/supporters`)
- **`secretmsg.net`**: The public web portal (landing page, public message submission `/:username`, viral TBH templates, and legal/safety documentation).
- **`api.secretmsg.net`**: Cloudflare D1 + Worker Edge API.
- **`m.secretmsg.net`**: Mobile web application and Capacitor Android app target.

---

## Share Link Handling

When a user copies their personal board link inside `app.secretmsg.net`, the link copied to their clipboard points directly to:
```
https://secretmsg.net/{username}
```
This guarantees that friends and social media followers arrive at the public, friction-free anonymous message submission page on `secretmsg.net`, while the user manages their messages in private on `app.secretmsg.net`.

---

## Configuration (`.env`)

| Variable | Default Value | Description |
|---|---|---|
| `VITE_API_URL` | `https://api.secretmsg.net` | Edge API endpoint |
| `VITE_PUBLIC_URL` | `https://secretmsg.net` | Public message submission portal |
| `VITE_ACCOUNT_APP_URL` | `https://app.secretmsg.net` | Account management portal |
| `VITE_TURNSTILE_SITE_KEY` | `0x4AAAAAAEsIItNVg9CO0YY9` | Cloudflare Turnstile bot verification |
| `VITE_USE_MOCK` | `false` | Real database mode (hard-locked in production) |

---

## Cloudflare Pages Deployment for `app.secretmsg.net`

To deploy this application to Cloudflare Pages for the custom domain `app.secretmsg.net`:

```bash
# 1. Build the production bundle
npm run build

# 2. Deploy dist/ directory to Cloudflare Pages
npx wrangler pages deploy dist --project-name=secretmsg-app --branch=main

# 3. In Cloudflare Dashboard > Workers & Pages > secretmsg-app:
# Add custom domain: app.secretmsg.net
```
