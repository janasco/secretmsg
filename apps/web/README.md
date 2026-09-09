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
- **`api.secretmsg.net`**: The backend REST API.
- **`m.secretmsg.net`**: Legacy mobile web prototype (hostname decommissioned).

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
| `VITE_TURNSTILE_SITE_KEY` | `0x4AAAAAAEsIItNVg9CO0YY9` | Bot-screening site key |
| `VITE_USE_MOCK` | `false` | Real database mode (hard-locked in production) |

---

## Deployment

To deploy this application for the custom domain `app.secretmsg.net`:

```bash
# 1. Build the production bundle
npm run build

# 2. Publish the dist/ directory to your static host
# (e.g. upload dist/ via your hosting provider's CLI or dashboard)

# 3. In your hosting provider's dashboard:
# Add custom domain: app.secretmsg.net
```
