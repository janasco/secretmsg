# SecretMsg Web Platform (`apps/web`)

A React 18 + Vite + Tailwind CSS single-page application, served from **`secretmsg.net`** — the public portal (landing page, anonymous message submission (`/:username`), dice prompt roulette (`/dice`), sticker studio (`/sticker-studio`), demo, safety/legal page tree (`/p/...`)) **and** the account hub (login, inbox (`/inbox`), double-blind replies (`/reply/:token`), settings (`/settings`), supporters wall (`/supporters`)). Single-host app: no subdomain deployments.

---

## Routes

| Route | Purpose |
|---|---|
| `/` | Public landing page |
| `/:username` | Public anonymous message submission |
| `/login` | Sign in with handle + PIN (default), new account, PIN recovery, pairing-code redeem, or legacy email code |
| `/inbox` | Authenticated inbox (view counts, timestamps, quarantine) |
| `/reply/:token` | Double-blind anonymous reply thread |
| `/settings` | Profile, preferences, filtered words, pause, browser pairing |
| `/supporters` | Supporter perks & donation unlocks |
| `/dice`, `/sticker-studio`, `/demo` | Public tools |
| `/p/*`, `/legal/:doc` | Safety center and legal documents |

---

## Configuration

Variables are read at build time by Vite, with production defaults baked in (`src/lib/config.ts`):

| Variable | Default | Description |
|---|---|---|
| `VITE_API_URL` | `https://api.secretmsg.net` | Edge API endpoint |
| `VITE_PUBLIC_URL` | `https://secretmsg.net` | Public + account portal (single host) |
| `VITE_TURNSTILE_SITE_KEY` | — | Bot-screening site key, used by `ComposeModal` (fail-closed: no key ⇒ sending disabled) |
| `VITE_USE_MOCK` | `false` | `true` enables the offline mock API for UI work without a backend |
| `VITE_DONATION_URL` | `https://polar.sh/janasco/secretmsg` | Donation/checkout link used by `DonationModal` |

Offline UI development: set `VITE_USE_MOCK=true` (e.g. in a local `.env`) to use the mock adapter in `src/lib/mockApi.ts` — no backend or credentials needed. Any other value (or unset) targets the real API.

---

## Pairing & Read-Only Sessions

`/login` defaults to **handle + PIN** sign-in, with tabs for new-account signup, backup-code recovery, **pairing-code redeem**, and legacy **email code** login. The mobile app's Settings screen can mint a short-lived, single-use code (`POST /api/auth/pair/create`), which this app redeems (`POST /api/auth/pair/redeem`) for a **read-only** session token. The UI reflects the restricted scope with a view-only banner and inline notes in place of write controls (reply, donation, account deletion) — those actions live on the signed-in device, and the API enforces the same rule with `403` on every write route. Reporting remains available from a paired session.

---

## Development

```bash
# from the repository root (apps/web is a workspace member)
npm install
npm run dev        # Vite dev server (default http://localhost:5173)
npm run build      # tsc + vite production build
npm run preview    # serve the production build locally
npm run typecheck  # tsc --noEmit
npm test           # vitest unit tests (src/lib/*.test.ts)
```

---

## Deployment

```bash
npm run build
# publish dist/ to the static host (secretmsg.net serves the whole SPA).
```

Single host serves the whole bundle with client-side routing (`BrowserRouter`). Retired: the former `app.`/`m.` subdomains are removed — no per-host deployment mapping remains.
