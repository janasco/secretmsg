const ASSET_EXTENSIONS = new Set([
  'aab',
  'apk',
  'avif',
  'css',
  'csv',
  'eot',
  'gif',
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

const LEGAL_DOCUMENTS = new Set(['terms', 'privacy', 'cookies', 'disclaimer']);

function normalizedPath(pathname: string): string {
  const normalized = pathname.length > 1 ? pathname.replace(/\/+$/, '') : pathname;
  return normalized || '/';
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

export function isAssetRequest(pathname: string): boolean {
  const path = normalizedPath(pathname).toLowerCase();
  if (path === '/downloads' || path.startsWith('/downloads/')) return true;

  const segment = path.slice(path.lastIndexOf('/') + 1);
  const dot = segment.lastIndexOf('.');
  if (dot <= 0 || dot === segment.length - 1) return false;
  return ASSET_EXTENSIONS.has(segment.slice(dot + 1));
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
