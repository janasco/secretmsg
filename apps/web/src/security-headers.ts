// The site's security headers, defined once.
//
// They are applied in two places and neither one is optional:
//   * scripts/prerender.mjs turns this list into dist/_headers, which the asset
//     layer applies to every response.
//   * worker.ts sets them on the paths it answers, which with
//     run_worker_first=false is only the Worker-routed paths (/inbox,
//     /settings, /:username, /reply/:token, 404s and redirects) — static assets
//     and the prerendered pages are served before the Worker ever runs.
//
// Editing the Worker's copy alone therefore does nothing for most of the site,
// and editing _headers alone does nothing for the Worker-routed paths. Both read
// this list so the two cannot drift.
//
// Names are canonical-cased for _headers; header names are case-insensitive, so
// the Worker can set them unchanged.

// Where violation reports go. The Worker answers a POST on exactly this path
// (see cspReport in worker.ts) and nothing else, and the policy below names it,
// so the header and the handler cannot drift apart. A path rather than an
// absolute URL because the site answers on both secretmsg.net and
// www.secretmsg.net, and because a relative report-uri keeps the report on the
// origin the page was actually served from — including a local preview.
export const CSP_REPORT_PATH = '/__csp-report';

// The sink's other half of the contract, kept here so the Worker's limit and
// the test that exercises it read the same number. (A named export of a
// worker's entry module has to be a function or a handler class, so this
// cannot live in worker.ts.)
export const CSP_REPORT_MAX_BYTES = 8192;

// A REPORT-ONLY Content-Security-Policy, and deliberately nothing enforcing.
//
// Report-only cannot break the site, which is the only reason to be able to
// ship this at all: the API fails closed, so an enforcing policy with a wrong
// connect-src or frame-src takes down account signup, OTP requests, message
// sending and abuse reporting in one change. So this header exists to answer
// two questions with real traffic before any enforcing policy is considered:
//
//   (a) Do the 239 per-page <script type="application/ld+json"> blocks trigger
//       script-src violations? Their bodies are unique per page, so a hash-based
//       script-src would need 239 hashes — unmaintainable, which is why this
//       hinges on whether script-src applies to non-executable script types at
//       all. It does not, and it is not a browser quirk: HTML's "prepare the
//       script element" (4.12.1.1) sets a script's type only for a JavaScript
//       MIME type essence match, "module", "importmap" or "speculationrules",
//       and returns early for anything else — "No script is executed, and el's
//       type is left as null" — before it ever reaches the CSP inline-check.
//       application/ld+json is a data block, so it is never checked.
//       Consequence: the only script block the site executes itself is the
//       theme-flash IIFE in index.html, byte-identical on all 239 prerendered
//       pages, so ONE hash covers it. 'unsafe-inline' in script-src is not
//       needed, and the report data is what confirms that in real browsers.
//       If somebody later adds it as a shortcut, that is compatibility debt and
//       it is worse than useless here: 'unsafe-inline' silences exactly the
//       script-src reports this policy exists to produce, so it would turn
//       question (a) back into an unanswerable one. The whole cost of not
//       having it is one digest in this file, and a test that keeps the digest
//       honest. If a JSON-LD violation ever shows up in Workers Logs, stop and
//       re-read this comment rather than promoting the policy.
//
//   (b) Does Turnstile's api.js need 'unsafe-eval'? 'unsafe-eval' is
//       deliberately absent, so any eval/new Function from
//       https://challenges.cloudflare.com arrives as a script-src violation
//       with blocked-uri "eval". If reports show one, an enforcing policy has
//       no choice but 'unsafe-eval': without it the widget cannot render, and
//       because the API fails closed on a missing token, a broken widget
//       breaks signup, OTP, send and report at the same time. This is also why
//       'strict-dynamic' is not used: it is not a substitute for a report.
//
// Every source expression below was read off the built output, not assumed:
//   * script-src  'self' = /assets/*.js, the one bundle Vite emits. No on*
//     event-handler attribute is set on any element in src/, so there is no
//     script-src-attr check to satisfy.
//   * the sha256 is the theme-flash script, not a per-page scheme. A nonce is
//     not available here at all: it is per-request and these pages are static
//     files, so using one would mean abandoning prerendering.
//   * style-src  the Google Fonts stylesheet, plus 'unsafe-inline' — debt, and
//     it is real debt, not a placeholder: the prerendered markup carries
//     style attributes (Navbar's SVG <stop>, DicePage, SupportersPage,
//     SettingsPage, DemoPage) and the Worker's 404 page carries a <style>
//     block of its own, both governed by style-src. Removing it means moving to
//     style-src-attr/style-src-elem with hashes and rewriting those style
//     attributes as classes; that is its own change, not this one.
//   * img-src    'self' only: no external image exists. Blog post images are
//     absent or served from /blog-images, and there is no data: image anywhere
//     in the build.
//   * font-src   fonts.gstatic.com serves the Inter woff2 files the
//     fonts.googleapis.com stylesheet points at.
//   * connect-src  the API (src/lib/config.ts) and the same-origin fetches of
//     /blog-index.json and /posts/<slug>.json. Nothing else is contacted.
//   * frame-src  Turnstile renders its challenge in an iframe on
//     challenges.cloudflare.com. There is no other iframe in src/ or in the
//     build.
//   * worker-src is deliberately not set, so it falls back to default-src
//     'self'. Whether Turnstile spins up a worker — and whether it needs a
//     blob: one — is not knowable from the source, so it is left to arrive as a
//     worker-src violation and be read like the rest, rather than guessed at
//     with a directive nobody can justify.
//   * 'report-sample' is what makes the answers legible: without it a report
//     carries no snippet, and the only way to tell the theme IIFE from a
//     JSON-LD block would be counting line numbers per page. Reports arrive at
//     CSP_REPORT_PATH with a 40-character sample of the offending block.
//
// Not included on purpose: no enforcing Content-Security-Policy (the reason
// this whole block exists), no HSTS or any HTTPS-related directive (the site
// does not redirect HTTP to HTTPS yet — that is a Cloudflare dashboard change
// the operator makes separately, and shipping HSTS before it exists would
// strand http:// visitors), and no form-action (the site has forms but
// onSubmit handlers, never a form posting to another origin).
//
// Promotion criteria, when the reports have been read: promote only if (1) no
// report shows a JSON-LD or any other unexpected script-src violation, (2)
// no report shows blocked-uri "eval" that the fix is not a deliberate
// 'unsafe-eval', and (3) the digest below still matches the theme script in
// index.html (route-policy.test.ts asserts it, so a drifting theme script fails
// the gate rather than breaking first paint silently). Then copy this value
// onto a Content-Security-Policy header, keep the report-uri until the
// enforcing policy has been clean in production for a while, and delete the
// duplicate.
export const REPORT_ONLY_POLICY = [
  "default-src 'self'",
  // 'unsafe-eval' is absent on purpose: see (b) above.
  "script-src 'self' https://challenges.cloudflare.com 'sha256-HGMqB8B11KO5uO4ehX1lTBxK0KpaX8jV40o9tXw8NvM=' 'report-sample'",
  "style-src 'self' https://fonts.googleapis.com 'unsafe-inline'",
  "img-src 'self'",
  "font-src 'self' https://fonts.gstatic.com",
  "connect-src 'self' https://api.secretmsg.net",
  'frame-src https://challenges.cloudflare.com',
  "object-src 'none'",
  "base-uri 'self'",
  `report-uri ${CSP_REPORT_PATH}`,
].join('; ');

export const SECURITY_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Content-Security-Policy-Report-Only': REPORT_ONLY_POLICY,
} as const;
