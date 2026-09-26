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
export const SECURITY_HEADERS = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
} as const;
