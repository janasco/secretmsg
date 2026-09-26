const ASSET_EXTENSIONS = new Set([
  'aab',
  'apk',
  'avif',
  'css',
  'csv',
  'eot',
  'gif',
  'html',
  'ico',
  'jpeg',
  'jpg',
  'js',
  'json',
  'mjs',
  'cjs',
  'map',
  'mp3',
  'mp4',
  'ogg',
  'otf',
  'pdf',
  'png',
  'svg',
  'txt',
  'wasm',
  'wav',
  'webm',
  'webmanifest',
  'webp',
  'woff',
  'woff2',
  'xml',
  'zip',
]);

const STATIC_ROUTES = new Set([
  '/',
  '/about',
  '/faq',
  '/contact',
  '/download',
  '/supporters',
  '/demo',
  '/dice',
  '/sticker-studio',
  '/login',
  '/delete-account',
  '/blog',
  '/p/safety',
  '/p/child-safety-policy',
  '/p/approach-to-safety',
  '/p/guide-to-online-safety',
  '/p/community-guidelines',
  '/p/safety-tools',
  '/p/resources',
  '/p/contact-us',
  '/p/terms',
  '/p/privacy',
  '/p/cookies',
  '/p/disclaimer',
]);

const CLIENT_ROUTES = new Set([...STATIC_ROUTES, '/inbox', '/settings']);
const RESERVED_PATHS = new Set(['/_headers', '/_headers.tmp', '/_redirects', '/_redirects.tmp']);
const LEGAL_DOCUMENTS = new Set(['terms', 'privacy', 'cookies', 'disclaimer']);
// Account pages. They are not files in dist, so the Worker answers them with
// the SPA shell, and that shell is the generic index.html: it carries the
// homepage's canonical and no robots tag. Answering 200 for a page that is
// private by nature therefore leaves it indexable, and robots.txt alone cannot
// stop that — Disallow only asks well-behaved crawlers not to fetch a URL, it
// does not remove an already-indexed one and does nothing about a crawler that
// ignores it. X-Robots-Tag is the directive that says "do not put this in an
// index" at the point of serving, so these two carry it and nothing else does.
// /login is deliberately absent: it is prerendered, canonical and listed in
// sitemap.xml, so noindexing it would contradict the sitemap.
const NOINDEX_ROUTES = new Set(['/inbox', '/settings']);

function normalizedPath(pathname: string): string {
  const normalized = pathname.length > 1 ? pathname.replace(/\/+$/, '') : pathname;
  return normalized || '/';
}

function hasAssetExtension(segment: string): boolean {
  const dot = segment.lastIndexOf('.');
  return dot >= 0 && dot < segment.length - 1 && ASSET_EXTENSIONS.has(segment.slice(dot + 1).toLowerCase());
}

function isDynamicRoute(path: string, prefix: string): boolean {
  if (!path.startsWith(prefix)) return false;
  const segment = path.slice(prefix.length);
  return segment.length > 0 && !segment.includes('/') && !/[\u0000-\u001f\u007f?#\\]/.test(segment);
}

function isUsernameRoute(path: string): boolean {
  const segment = path.slice(1);
  if (hasAssetExtension(segment)) return false;
  // Same rule as the API's isValidUsername (secretmsg-private/api/src/random.ts):
  // 4-30 characters of [a-z0-9_.-]. The path is already lowercased by
  // isClientRoute, which is the same normalisation the API applies to a handle
  // (trim, lowercase, strip one leading @). The Worker used to accept any
  // single segment of those characters, so /a and /ab were served as boards the
  // API can never create: the board page then fails its own API call with 400.
  if (!/^[a-z0-9_.-]{4,30}$/.test(segment)) return false;
  // Dot-prefixed and dot-suffixed segments are not usernames here even though
  // the API would accept them. A leading dot makes the path a dotfile rather
  // than a board, and a trailing one is what the asset-extension check exists
  // to keep out of the shell. Both guards predate the length rule and are kept
  // so this change only removes routes, never adds them.
  return !segment.startsWith('.') && !segment.endsWith('.');
}

// The slug of a /post/:slug request, or null for anything else. The path is
// normalised and lowercased the same way isClientRoute does it, and blog.mjs
// only ever emits lowercase slugs, so the result compares directly against the
// build's post list. Trailing slashes are stripped, so /post/x/ and /post/x
// are the same request; /post and /post/ are not a post at all and return null,
// which leaves them on the username fallthrough exactly as before.
export function postSlug(pathname: string): string | null {
  const match = /^\/post\/([^/]+)$/.exec(normalizedPath(pathname).toLowerCase());
  return match ? match[1] : null;
}

export function isClientRoute(pathname: string): boolean {
  const path = normalizedPath(pathname).toLowerCase();
  if (CLIENT_ROUTES.has(path)) return true;
  if (isDynamicRoute(path, '/reply/')) return true;
  if (isDynamicRoute(path, '/post/')) return true;
  if (isDynamicRoute(path, '/legal/')) return true;
  return isUsernameRoute(path);
}

export function isNoindexRoute(pathname: string): boolean {
  return NOINDEX_ROUTES.has(normalizedPath(pathname).toLowerCase());
}

export function legacyRedirect(pathname: string): string | null {
  const path = normalizedPath(pathname);
  if (path === '/donors') return '/supporters/';

  const pLegal = /^\/p\/legal\/([^/]+)$/i.exec(path);
  if (pLegal && LEGAL_DOCUMENTS.has(pLegal[1].toLowerCase())) return `/p/${pLegal[1].toLowerCase()}/`;

  const legal = /^\/legal\/([^/]+)$/i.exec(path);
  if (legal && LEGAL_DOCUMENTS.has(legal[1].toLowerCase())) return `/p/${legal[1].toLowerCase()}/`;

  return null;
}

export function isAssetRequest(pathname: string, search = ''): boolean {
  const path = normalizedPath(pathname).toLowerCase();
  if (path === '/downloads' || path.startsWith('/downloads/')) return true;
  if (RESERVED_PATHS.has(path)) return true;
  if (Array.from(new URLSearchParams(search)).some(([key, value]) => hasAssetExtension(key) || hasAssetExtension(value))) return true;
  if (isDynamicRoute(path, '/reply/') || isDynamicRoute(path, '/post/') || isDynamicRoute(path, '/legal/')) return false;

  const segment = path.slice(path.lastIndexOf('/') + 1);
  if (hasAssetExtension(segment) && segment.endsWith('.html')) return true;
  if (isClientRoute(path)) return false;
  return hasAssetExtension(segment);
}

export const notFoundHtml = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>404 - SecretMsg</title>
<style>
body{margin:0;background:#020617;color:#e2e8f0;font:16px/1.5 system-ui,sans-serif;display:grid;min-height:100vh;place-items:center}
main{max-width:36rem;padding:2rem;text-align:center}a{color:#a5b4fc}
</style>
</head>
<body>
<main><h1>404 - File not found</h1><p>The requested file is no longer available.</p><p><a href="/">Return to SecretMsg</a></p></main>
</body>
</html>`;
