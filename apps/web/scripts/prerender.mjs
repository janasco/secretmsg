import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { DEFAULT_IMAGE, HOST, STATIC_ROUTES, canonicalUrl } from './site-manifest.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dist = join(root, 'dist');
const templatePath = join(dist, 'index.html');
const template = readFileSync(templatePath, 'utf8');
const rendererEntry = join(root, 'src', 'prerender-renderer.tsx');
const securityHeadersEntry = join(root, 'src', 'security-headers.ts');
const esbuildPath = join(root, '../../../node_modules/.bin/esbuild');

// src/ is TypeScript, so a node script cannot import it directly. Bundling the
// entry with esbuild and importing the result is how prerender.mjs already
// reaches the renderer, and it is how it reaches any other shared src/ module.
async function loadModule(entry) {
  const tempRoot = mkdtempSync(join('/tmp/opencode', 'secretmsg-prerender-'));
  const tempFile = join(tempRoot, 'module.cjs');
  try {
    execFileSync(esbuildPath, [
      entry,
      '--bundle',
      '--platform=node',
      '--format=cjs',
      `--outfile=${tempFile}`,
      `--alias:@=${join(root, 'src')}`,
    ], { stdio: 'inherit' });
    return await import(`${pathToFileURL(tempFile).href}?cacheBust=${Date.now()}`);
  } finally {
    rmSync(tempRoot, { recursive: true, force: true });
  }
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

function escapeJson(value) {
  return JSON.stringify(value)
    .replace(/&/g, '\\u0026')
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/\u2028/g, '\\u2028')
    .replace(/\u2029/g, '\\u2029');
}

function attribute(tag, name) {
  const match = tag.match(new RegExp(`\\b${name}\\s*=\\s*(?:"([^"]*)"|'([^']*)'|([^\\s>]+))`, 'i'));
  return match ? match[1] ?? match[2] ?? match[3] : null;
}

function isManagedSeoTag(tag) {
  const name = attribute(tag, 'name');
  const property = attribute(tag, 'property');
  const rel = attribute(tag, 'rel');
  return name === 'description' || name?.startsWith('twitter:') || property?.startsWith('og:') || property?.startsWith('article:') || rel?.split(/\s+/).includes('canonical');
}

function meta(attributeName, key, content) {
  return `<meta ${attributeName}="${escapeHtml(key)}" content="${escapeHtml(content)}" />`;
}

function renderHead(page) {
  if (!/<head>/i.test(template)) throw new Error('Built index.html must have a head element');
  const tags = [
    `<title>${escapeHtml(page.title)}</title>`,
    meta('name', 'description', page.description),
    `<link rel="canonical" href="${escapeHtml(page.url)}" />`,
    meta('property', 'og:type', page.type === 'article' ? 'article' : 'website'),
    meta('property', 'og:site_name', 'SecretMsg'),
    meta('property', 'og:title', page.title),
    meta('property', 'og:description', page.description),
    meta('property', 'og:url', page.url),
    meta('property', 'og:image', page.image),
    meta('property', 'og:image:alt', page.title),
    meta('name', 'twitter:card', page.type === 'article' ? 'summary_large_image' : 'summary'),
    meta('name', 'twitter:title', page.title),
    meta('name', 'twitter:description', page.description),
    meta('name', 'twitter:image', page.image),
    ...(page.publishedTime ? [meta('property', 'article:published_time', page.publishedTime)] : []),
    `<script type="application/ld+json">${escapeJson(page.jsonLd)}</script>`,
  ].join('\n    ');

  return template.replace(/<head>([\s\S]*?)<\/head>/i, (_, head) => {
    const cleaned = head
      .replace(/<title>[\s\S]*?<\/title>/gi, '')
      .replace(/<script\b[^>]*type=["']application\/ld\+json["'][^>]*>[\s\S]*?<\/script>/gi, '')
      .replace(/<(?:meta|link)\b[^>]*>/gi, (tag) => (isManagedSeoTag(tag) ? '' : tag));
    return `<head>${cleaned}\n    ${tags}\n  </head>`;
  });
}

function renderNoscript(page) {
  const published = page.publishedTime
    ? `<p><time datetime="${escapeHtml(page.publishedTime)}">${escapeHtml(page.publishedTime.slice(0, 10))}</time></p>`
    : '';
  return `<noscript><main><h1>${escapeHtml(page.title)}</h1>${published}<p>${escapeHtml(page.description)}</p></main></noscript>`;
}

function outputPath(routePath) {
  if (routePath === '/') return templatePath;
  const segments = routePath.split('/').filter(Boolean);
  if (!routePath.startsWith('/') || segments.some((segment) => !segment || segment === '.' || segment === '..' || segment.includes('\\'))) {
    throw new Error(`Invalid static route: ${routePath}`);
  }
  return join(dist, ...segments, 'index.html');
}

function renderPage(page, routePath, body = '') {
  const rootPattern = /(<div\b[^>]*\bid\s*=\s*(?:"root"|'root'|root)[^>]*>)<\/div>/gi;
  const head = renderHead(page);
  const roots = head.match(rootPattern) ?? [];
  if (roots.length !== 1) throw new Error(`Expected one empty root div for ${routePath}, found ${roots.length}`);
  const html = head.replace(rootPattern, (_, open) => `${open}${renderNoscript(page)}${body}</div>`);
  const destination = outputPath(routePath);
  mkdirSync(dirname(destination), { recursive: true });
  writeFileSync(destination, html);
  return destination;
}

function staticJsonLd(route) {
  const data = {
    '@context': 'https://schema.org',
    '@type': route.type,
    name: route.title,
    description: route.description,
    url: canonicalUrl(route.path),
  };
  if (route.path === '/') return data;
  return { ...data, isPartOf: { '@type': 'WebSite', name: 'SecretMsg', url: HOST } };
}

const renderer = await loadModule(rendererEntry);
const staticFiles = [];
for (const route of STATIC_ROUTES) {
  const body = route.component ? renderer.renderManifestPage(route.path, route.component) : '';
  staticFiles.push(renderPage({
    ...route,
    url: canonicalUrl(route.path),
    image: DEFAULT_IMAGE,
    jsonLd: staticJsonLd(route),
  }, route.path, body));
}

const index = JSON.parse(readFileSync(join(dist, 'blog-index.json'), 'utf8'));
if (!Array.isArray(index)) throw new Error('dist/blog-index.json must contain an array');

const legacyRoutes = [
  ['/donors', '/supporters/'],
  ['/donors/', '/supporters/'],
  ...['terms', 'privacy', 'cookies', 'disclaimer'].flatMap((doc) => [
    [`/p/legal/${doc}`, `/p/${doc}/`],
    [`/p/legal/${doc}/`, `/p/${doc}/`],
    [`/legal/${doc}`, `/p/${doc}/`],
    [`/legal/${doc}/`, `/p/${doc}/`],
  ]),
];
// Browsers ask for /favicon.ico at the origin root on every page view whether or
// not any page references it, and it is not a file in dist, so without a rule it
// falls through to the Worker's HTML 404. logo.svg is the icon index.html already
// declares, so answer the implicit request with the one icon that ships instead of
// committing a second binary.
const faviconRoutes = [
  ['/favicon.ico', '/logo.svg'],
];
const redirectRoutes = [...legacyRoutes, ...faviconRoutes];
writeFileSync(join(dist, '_redirects'), `${redirectRoutes.map(([source, destination]) => `${source} ${destination} 301`).join('\n')}\n`);
// The asset layer serves most of the site without the Worker, so this file — not
// the Worker's copy of the headers — is what the site actually returns. Both come
// from src/security-headers.ts so they cannot drift apart.
const { SECURITY_HEADERS } = await loadModule(securityHeadersEntry);
writeFileSync(join(dist, '_headers'), `/*\n${Object.entries(SECURITY_HEADERS).map(([name, value]) => `  ${name}: ${value}`).join('\n')}\n`);

const postFiles = index.map((post) => {
  if (typeof post?.slug !== 'string' || !/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(post.slug)) {
    throw new Error(`Invalid post slug in blog index: ${post?.slug}`);
  }
  if (typeof post.title !== 'string' || !post.title.trim()) throw new Error(`${post.slug}: title is required`);
  if (typeof post.excerpt !== 'string' || !post.excerpt.trim()) throw new Error(`${post.slug}: excerpt is required`);
  const parsedDate = typeof post.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(post.date)
    ? new Date(`${post.date}T00:00:00.000Z`)
    : null;
  if (!parsedDate || Number.isNaN(parsedDate.getTime()) || parsedDate.toISOString().slice(0, 10) !== post.date) {
    throw new Error(`${post.slug}: invalid date`);
  }

  const fullPost = JSON.parse(readFileSync(join(dist, 'posts', `${post.slug}.json`), 'utf8'));
  if (fullPost.slug !== post.slug || fullPost.title !== post.title || fullPost.excerpt !== post.excerpt || fullPost.date !== post.date) {
    throw new Error(`${post.slug}: post JSON does not match blog index`);
  }

  const url = canonicalUrl(`/post/${post.slug}`);
  const image = typeof post.image === 'string' && post.image
    ? post.image.startsWith('http') ? post.image : `${HOST}${post.image}`
    : DEFAULT_IMAGE;
  const publishedTime = `${post.date}T12:00:00Z`;
  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BlogPosting',
    headline: post.title,
    description: post.excerpt,
    image: [image],
    datePublished: publishedTime,
    author: { '@type': 'Organization', name: 'SecretMsg', url: HOST },
    publisher: {
      '@type': 'Organization',
      name: 'SecretMsg',
      logo: { '@type': 'ImageObject', url: DEFAULT_IMAGE },
    },
    mainEntityOfPage: { '@type': 'WebPage', '@id': url },
  };
  return renderPage({
    title: `${post.title} - SecretMsg Blog`,
    description: post.excerpt,
    url,
    image,
    type: 'article',
    publishedTime,
    jsonLd,
  }, `/post/${post.slug}`);
});

console.log(`prerender: ${postFiles.length} posts + ${staticFiles.length} static routes -> ${postFiles.length + staticFiles.length} HTML files`);
