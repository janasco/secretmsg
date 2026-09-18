/**
 * SEO artifacts, generated from src/lib/blog.ts on every build (`prebuild`).
 * - public/sitemap.xml  (static routes + every post)
 * - public/feed.xml      (RSS 2.0 of the blog)
 * - public/robots.txt    (allow all + sitemap pointer)
 *
 * Parses the BlogPost literals directly so publishing stays a one-file edit:
 * add the post to blog.ts and these regenerate automatically.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const pub = join(root, 'public');
const HOST = 'https://secretmsg.net';

const STATIC_ROUTES = [
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
  '/blog',
  '/p/safety',
  '/p/guide-to-online-safety',
  '/p/community-guidelines',
  '/p/terms',
  '/p/privacy',
  '/p/cookies',
  '/p/disclaimer',
];

const esc = (s) =>
  s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');

function readPosts() {
  const src = readFileSync(join(root, 'src/lib/blog.ts'), 'utf8');
  const posts = [];
  const re =
    /slug:\s*'([^']+)'[\s\S]*?title:\s*'([^']+)'[\s\S]*?excerpt:\s*'([^']+)'[\s\S]*?date:\s*'([^']+)'/g;
  let m;
  while ((m = re.exec(src)) !== null) {
    posts.push({ slug: m[1], title: m[2], excerpt: m[3], date: m[4] });
  }
  return posts;
}

function rfc822(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 12)).toUTCString();
}

const posts = readPosts();
if (posts.length === 0) throw new Error('seo: no posts parsed from blog.ts');

const latest = posts.map((p) => p.date).sort().at(-1);

const sitemapUrls = [
  ...STATIC_ROUTES.map((r) => ({ loc: `${HOST}${r}`, lastmod: latest })),
  ...posts.map((p) => ({ loc: `${HOST}/post/${p.slug}`, lastmod: p.date })),
];
writeFileSync(
  join(pub, 'sitemap.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    sitemapUrls
      .map((u) => `  <url><loc>${u.loc}</loc><lastmod>${u.lastmod}</lastmod></url>`)
      .join('\n') +
    `\n</urlset>\n`,
);

const items = [...posts]
  .sort((a, b) => (a.date < b.date ? 1 : -1))
  .map(
    (p) => `    <item>\n` +
      `      <title>${esc(p.title)}</title>\n` +
      `      <link>${HOST}/post/${p.slug}</link>\n` +
      `      <guid isPermaLink="true">${HOST}/post/${p.slug}</guid>\n` +
      `      <pubDate>${rfc822(p.date)}</pubDate>\n` +
      `      <description>${esc(p.excerpt)}</description>\n` +
      `    </item>`,
  )
  .join('\n');
writeFileSync(
  join(pub, 'feed.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>\n` +
    `<rss version="2.0">\n` +
    `  <channel>\n` +
    `    <title>SecretMsg Blog</title>\n` +
    `    <link>${HOST}/blog</link>\n` +
    `    <description>Notes on honest messaging, privacy, and anonymous culture.</description>\n` +
    `    <language>en-us</language>\n` +
    `${items}\n` +
    `  </channel>\n` +
    `</rss>\n`,
);

writeFileSync(join(pub, 'robots.txt'), `User-agent: *\nAllow: /\n\nSitemap: ${HOST}/sitemap.xml\n`);

console.log(`seo: ${posts.length} posts -> sitemap.xml, feed.xml, robots.txt`);
