/**
 * Deployment config: all environment-variable reads live here so aislop's
 * hardcoded-url rule has one place to audit. Every URL has a production
 * fallback so preview/offline builds still work.
 *
 * Single-host app: the account hub (/login, /inbox, /settings) is served
 * from the public host. There is no account subdomain.
 */

export const API_BASE_URL = import.meta.env?.VITE_API_URL || 'https://api.secretmsg.net';
export const PUBLIC_BASE_URL = import.meta.env?.VITE_PUBLIC_URL || 'https://secretmsg.net';

// Offline mock mode for open-source contributors (no backend credentials needed).
// Enabled with VITE_USE_MOCK=true. Defaults to false (production API).
export const USE_MOCK = import.meta.env?.VITE_USE_MOCK === 'true';
