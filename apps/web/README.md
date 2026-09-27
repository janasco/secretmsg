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

## Security Headers

Four headers ship, all defined once in `src/security-headers.ts` and applied twice — `scripts/prerender.mjs` turns that list into `dist/_headers` for the asset layer, and `src/worker.ts` sets it on the paths the Worker answers itself (`/inbox`, `/settings`, `/:username`, `/reply/:token`, 404s, redirects). With `run_worker_first = false` the asset layer serves the 239 prerendered pages before the Worker runs, so `_headers` is what most of the site actually returns; both paths read the same list, so they cannot drift.

`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, and a **report-only** `Content-Security-Policy-Report-Only`.

### The report-only policy is a measurement, not a mitigation

There is deliberately **no** enforcing `Content-Security-Policy`. The API fails closed, so an enforcing policy with a wrong `connect-src` or `frame-src` breaks account signup, OTP requests, message sending and abuse reporting simultaneously. Report-only cannot break anything, and it exists to answer two questions that decide whether an enforcing policy is ever safe here:

| Question | How the reports answer it |
| --- | --- |
| (a) Do the 239 per-page `<script type="application/ld+json">` blocks trigger `script-src` violations? Their bodies are unique per page, so a hash-based `script-src` would need 239 hashes. | `script-src` carries **no** `'unsafe-inline'` — only the one `sha256` of the theme-flash script — so a JSON-LD block that *were* checked would appear as a violation. `'report-sample'` puts the first 40 characters of the offending block in the report, so the theme IIFE and a JSON-LD body are told apart by reading the log, not by counting line numbers. Per the HTML spec a JSON-LD block is a *data block*, which "prepare the script element" never passes to the CSP check, so the expected answer is: no violations at all. |
| (b) Does Turnstile's `api.js` need `'unsafe-eval'`? | `'unsafe-eval'` is deliberately absent, so any `eval`/`new Function` from `challenges.cloudflare.com` arrives as a `script-src` violation with `blocked-uri: "eval"`. If it does, an enforcing policy has to carry `'unsafe-eval'` — and that is a decision to make on purpose, because a widget that cannot render means no token means fail-closed 4xx on signup, OTP, send and report. |

The `'unsafe-inline'` in `style-src` **is** compatibility debt, recorded in `src/security-headers.ts`: the prerendered markup carries `style` attributes and the Worker's 404 page has a `<style>` block. Removing it means `style-src-attr`/`style-src-elem` with hashes and rewriting those attributes as classes — a separate change.

`img-src` is `'self'` because the build loads no external image; `font-src` and `style-src` carry the two Google Fonts hosts; `connect-src` is `'self'` plus `https://api.secretmsg.net`; `frame-src` is `challenges.cloudflare.com`, the only iframe the site creates; `object-src` is `'none'` and `base-uri` is `'self'`.

### Reading the violations

Reports are POSTed to `/__csp-report` and answered with `204` by the frontend Worker, which logs one line per report; Cloudflare Workers Logs is where they land. `wrangler tail`, or the dashboard's Logs tab, filtered on `csp-report`. The body is capped at 8 KiB, each field is truncated, the response body is empty and `no-store`, and nothing is stored or forwarded to the API.

**What the operator should do, and when:** after the policy has been live long enough to cover a normal week of traffic (the interesting paths are the ones that render Turnstile — `/login`, `/inbox`, the compose modal on a board, and the report form — so check those, not just the homepage), grep the logs for `blocked-uri":"eval"` and for any `script-src` report whose `sample` is not the theme IIFE. Then, and only then, consider promoting. If you promote, the criteria are: no unexpected `script-src` report, the `eval` question resolved one way or the other, and the `sha256` still matching the inline script in `index.html` — `npm test` fails if it has drifted, so a stale digest cannot reach production quietly. Copy `REPORT_ONLY_POLICY` onto a `Content-Security-Policy` header, keep the `report-uri` until the enforcing version has been clean for a while, then delete the duplicate. Do not remove the report-only header first and call it done.

No `Strict-Transport-Security` is set, and no HTTPS-related directive is used: the site does not redirect HTTP to HTTPS yet. That is a Cloudflare dashboard setting the operator enables separately, and HSTS must not ship before it.

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
