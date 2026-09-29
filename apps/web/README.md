# SecretMsg Web Platform (`apps/web`)

A React 18 + Vite + Tailwind CSS single-page application, served from
**`secretmsg.net`** — the public portal (landing page, anonymous message
submission (`/:username`), dice prompt roulette (`/dice`), sticker studio
(`/sticker-studio`), demo, download, FAQ, blog, and the safety/legal page tree
(`/p/...`)) **and** the account hub (login, inbox (`/inbox`), double-blind
replies (`/reply/:token`), settings (`/settings`), supporters wall
(`/supporters`)). Single-host app: no subdomain deployments.

At build time the app is **prerendered to 239 static HTML files** — 215 blog
posts plus 24 static routes — and served by a Cloudflare static-assets Worker.

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
| `/supporters` | Funding model: ads in the app, one ad-free purchase, supporters **count** only |
| `/download` | Sideload APKs: version, per-ABI sizes, SHA-256, and the two-tracks-never-merge warning |
| `/about`, `/contact`, `/faq` | Static informational pages |
| `/delete-account` | Public self-service account deletion (full signed-in session required) |
| `/dice`, `/sticker-studio`, `/demo` | Public tools |
| `/blog`, `/post/:slug` | Blog index and posts |
| `/p/*` | Safety center and legal documents — **the canonical legal URLs** |
| `/legal/:doc` | Legacy alias; `LegalPage.tsx` forwards to the matching `/p/*` document |

> **Do not link to a bare `/privacy` or `/terms`.** The canonical legal
> documents live under `/p/` (`/p/privacy/`, `/p/terms/`, `/p/cookies/`,
> `/p/disclaimer/`). A bare `/privacy` matches the `/:username` route and
> returns the homepage shell, so a link written that way silently lands a
> reader on a board page rather than the policy.

The canonical policy text is authored in this app, in
`src/pages/PrivacyPage.tsx`, `src/pages/TermsPage.tsx`,
`src/pages/DisclaimerPage.tsx` and `src/pages/CookiesPage.tsx`. The Flutter app
carries its own copy of the same content in
`apps/mobile-flutter/lib/data/static_content.dart`. Where a markdown copy under
`LEGAL/` disagrees with those, **the shipped page is correct** — users and Play
reviewers see the page, not the markdown.

---

## Configuration

Variables are read at build time by Vite, with production defaults baked in (`src/lib/config.ts`):

| Variable | Default | Description |
|---|---|---|
| `VITE_API_URL` | `https://api.secretmsg.net` | Edge API endpoint |
| `VITE_PUBLIC_URL` | `https://secretmsg.net` | Public + account portal (single host) |
| `VITE_TURNSTILE_SITE_KEY` | — | Bot-screening site key, read in `TurnstileWidget.tsx` and `ComposeModal.tsx` (fail-closed: no key ⇒ sending disabled) |
| `VITE_USE_MOCK` | `false` | `true` enables the offline mock API for UI work without a backend |

Offline UI development: set `VITE_USE_MOCK=true` (e.g. in a local `apps/web/.env`,
templated on the repo-root `.env.example`) to use the mock adapter in
`src/lib/mockApi.ts` — no backend or credentials needed. Any other value (or
unset) targets the real API.

**There is no `VITE_DONATION_URL` and there is no `DonationModal`.** The Polar.sh
checkout, the donation button and the tiered supporter perks have all been
removed; funding is advertising in the Android app plus the one-time
`remove_ads` purchase. A stale `VITE_DONATION_URL` may still appear in
`.env.example`; nothing reads it.

---

## Pairing & Read-Only Sessions

`/login` defaults to **handle + PIN** sign-in, with tabs for new-account signup, backup-code recovery, **pairing-code redeem**, and legacy **email code** login. The mobile app's Settings screen can mint a short-lived (5-minute, TTL `PAIR_CODE_TTL_SECONDS` in the private API), single-use pairing code (`POST /api/auth/pair/create`), which this app redeems (`POST /api/auth/pair/redeem`) for a **read-only** session token. The UI reflects the restricted scope with a view-only banner and inline notes in place of write controls (reply, account deletion, the ad-free purchase) — those actions live on the signed-in device, and the API enforces the same rule with `403` on every write route. Reporting remains available from a paired session.

---

## Security Headers

Four headers ship, all defined once in `src/security-headers.ts` and applied
twice — `scripts/prerender.mjs` turns that list into `dist/_headers` for the
asset layer, and `src/worker.ts` sets it on the paths the Worker answers itself
(`/inbox`, `/settings`, `/:username`, `/reply/:token`, 404s, redirects, and the
CSP report endpoint). With `run_worker_first = false` the asset layer serves the
239 prerendered pages before the Worker runs, so `_headers` is what most of the
site actually returns; both paths read the same list, so they cannot drift.

> **A header that works on `/settings` but not on `/blog` is not a bug.** The
> 239 prerendered pages are answered by the asset layer, and headers set in
> `worker.ts` do not cover them. Edit the one list and both paths follow.

`X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`,
`Referrer-Policy: strict-origin-when-cross-origin`, and a **report-only**
`Content-Security-Policy-Report-Only`. There is deliberately **no** enforcing
`Content-Security-Policy` and **no** `Strict-Transport-Security`.

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

### HTTPS and HSTS

Cloudflare's **"Always Use HTTPS" is enabled**: a plaintext `http://` request
returns a `301` to `https://`, so plaintext exposure is closed.

`Strict-Transport-Security` is nevertheless **not set, and must not be added
yet**. HSTS is still pending because Always Use HTTPS was only recently turned
on; shipping HSTS before the redirect has been stable for a while would strand
any `http://` visitor whose browser had cached the header, and browsers ignore
it on first contact anyway. The one loose end on the transport side is that **no
`www`→apex redirect is configured**, so `www.secretmsg.net` currently serves
`200` rather than redirecting to `secretmsg.net` — the site is reachable on two
hosts, which splits caches and lets the same content be addressed two ways.
Note that `src/security-headers.ts` deliberately uses a *path* for `report-uri`
(`/__csp-report`) rather than an absolute URL precisely because the site
currently answers on both hosts.

---

## Advertising and `ads.txt`

The website serves **no ads**: no ad SDK, no ad exchange, no ad script, no
advertising cookies, and no ad or cross-site tracking code. Advertising exists
only inside the Android app (a Google AdMob banner and an optional rewarded
video), gated by the `remove_ads` entitlement.

Two seller-authorization files are published at the site root and are live:

| File | Purpose |
|---|---|
| `public/ads.txt` | Authorizes the seller for inventory on the domain |
| `public/app-ads.txt` | Authorizes the seller for the app in its store listing (`net.secretmsg.android_app`) |

Both currently declare `google.com, pub-1165824705893364, DIRECT,
f08c47fec0942fa0` — the `pub-` ID matches the AdMob publisher the Android build
is configured with, and the two files carry the same publisher. `src/ads-txt.test.ts`
is a named check in the gate: it parses both files, asserts the four-field seller
record shape, validates the publisher ID format, and pins the certification ID,
so an edit that breaks either file fails `bash scripts/verify.sh` rather than
silently reducing ad fill. These files are public by design and must never carry
secrets.

---

## Development

```bash
# from the repository root (apps/web is a workspace member)
npm install
npm run dev        # Vite dev server (default http://localhost:5173)
npm run build      # tsc + vite production build + prerender (postbuild)
npm run preview    # serve the production build locally
npm run typecheck  # tsc --noEmit
npm test           # vitest — 110 tests
npm run a11y       # colour-remap bypass + contrast scan (also a gate check)
```

`npm run build` is `tsc && vite build`, and `postbuild` runs
`scripts/prerender.mjs`, which is what emits the 239 static HTML pages and
`dist/_headers`.

**Test counts** (verified 2026-09-29): 110 web tests, 162 Flutter tests in
`apps/mobile-flutter`, 48 API tests in the private repo. The web suite is not
only `src/lib/*.test.ts` — it also covers `src/ads-txt.test.ts`,
`src/blog-pipeline.test.ts`, `src/route-policy.test.ts` and
`scripts/a11y/a11y-color.test.mjs`, which is where the security-header and
route-policy assertions live.

---

## Deployment

`npm run build` then deploy from the repository root with:

```bash
bash scripts/deploy-frontend.sh
```

That copies `apps/web/dist` to `/tmp/fe-dist`, generates a wrangler config with
the `ASSETS` binding and **`run_worker_first = false`**, and deploys. Do not
flip `run_worker_first` to "fix" a routing problem: the flag is the reason the
asset layer answers the 239 prerendered pages and the APKs before the Worker
runs, and it is what makes `dist/_headers` the effective header source for most
of the site. The Worker only executes for `/inbox`, `/settings`, `/:username`,
`/reply/:token`, 404s, redirects and the CSP report endpoint.

Running the build re-stamps `public/sitemap.xml`, `public/feed.xml`,
`public/robots.txt` and `public/blog-index.json` with new `lastmod` values
derived from source mtimes, so `git status` will show those as modified after a
build. That churn is expected and is not by itself a change to commit.

Single host serves the whole bundle with client-side routing (`BrowserRouter`).
Retired: the former `app.`/`m.` subdomains are removed — no per-host deployment
mapping remains.
