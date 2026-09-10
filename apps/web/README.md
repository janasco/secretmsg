# SecretMsg Web Platform (`apps/web`)

A React 18 + Vite + Tailwind CSS single-page application. **One codebase, two deployments:**

- **`secretmsg.net`** — the public portal: landing page, anonymous message submission (`/:username`), dice prompt roulette (`/dice`), sticker studio (`/sticker-studio`), demo, and the safety/legal page tree (`/p/...`).
- **`app.secretmsg.net`** — the authenticated account hub: login, inbox (`/inbox`), double-blind replies (`/reply/:token`), settings (`/settings`), and the supporters wall (`/supporters`).

---

## Routes

| Route | Purpose |
|---|---|
| `/` | Public landing page |
| `/:username` | Public anonymous message submission |
| `/login` | Sign in with a pairing code (default) or email OTP |
| `/inbox` | Authenticated inbox (view counts, timestamps, quarantine) |
| `/reply/:token` | Double-blind anonymous reply thread |
| `/settings` | Profile, preferences, filtered words, pause, browser pairing |
| `/supporters` | Supporter perks & donation unlocks |
| `/dice`, `/sticker-studio`, `/demo` | Public tools |
| `/p/*`, `/legal/:doc` | Safety center and legal documents |

---

## Configuration

Variables are read at build time by Vite, with production defaults baked in (`src/lib/api.ts`):

| Variable | Default | Description |
|---|---|---|
| `VITE_API_URL` | `https://api.secretmsg.net` | Edge API endpoint |
| `VITE_PUBLIC_URL` | `https://secretmsg.net` | Public message submission portal |
| `VITE_ACCOUNT_APP_URL` | `https://app.secretmsg.net` | Account management portal |
| `VITE_TURNSTILE_SITE_KEY` | — | Bot-screening site key, used by `ComposeModal` |

Offline UI development: a mock API adapter lives in `src/lib/mockApi.ts`, toggled by the `USE_MOCK` constant at the top of `src/lib/api.ts` (hardcoded `false` in production; not an environment variable). Flip it locally to build UI without a backend.

---

## Pairing & Read-Only Sessions

`/login` defaults to **pairing mode**: the mobile app's Settings screen can mint a short-lived, single-use code (`POST /api/auth/pair/create`), which this app redeems (`POST /api/auth/pair/redeem`) for a **read-only** session token. The UI reflects the restricted scope with a view-only banner and inline notes in place of write controls (reply, donation, account deletion) — those actions live on the signed-in device, and the API enforces the same rule with `403` on every write route. Reporting remains available from a paired session.

---

## Development

```bash
# from the repository root (apps/web is a workspace member)
npm install
npm run dev        # Vite dev server (default http://localhost:5173)
npm run build      # tsc + vite production build
npm run preview    # serve the production build locally
```

---

## Deployment

```bash
npm run build
# publish dist/ to the static host, then map the custom domains:
#   secretmsg.net and app.secretmsg.net -> dist/
```

Both hostnames serve the same bundle; the app is a single SPA with client-side routing (`BrowserRouter`).
