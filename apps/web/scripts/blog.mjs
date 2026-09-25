/**
 * Blog build pipeline: content/posts/*.md -> public JSON + SEO artifacts.
 * - public/blog-index.json   published/due posts metadata (newest first)
 * - public/posts/<slug>.json full post (HTML body + meta)
 * - public/sitemap.xml, public/feed.xml, public/robots.txt
 *
 * Status: published always ships; scheduled ships once date <= today (UTC);
 * drafts never ship. Run via `prebuild`.
 */
import { readdirSync, readFileSync, writeFileSync, mkdirSync, existsSync, rmSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const postsDir = join(root, 'content', 'posts');
const outIndex = join(root, 'public', 'blog-index.json');
const outPosts = join(root, 'public', 'posts');
const HOST = 'https://secretmsg.net';

const esc = (s) =>
  s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function parseFm(text, filename) {
  const m = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) throw new Error(`${filename}: frontmatter is missing or malformed`);
  const fm = {};
  for (const line of m[1].split('\n')) {
    const i = line.indexOf(':');
    if (i <= 0) throw new Error(`${filename}: invalid frontmatter line "${line}"`);
    const key = line.slice(0, i).trim();
    const raw = line.slice(i + 1).trim();
    if (raw.startsWith('[')) {
      if (!raw.endsWith(']')) throw new Error(`${filename}: frontmatter field "${key}" has malformed array syntax`);
      fm[key] = raw.slice(1, -1).split(',').map((s) => s.trim().replace(/^"|"$/g, '')).filter(Boolean);
    } else {
      fm[key] = raw.replace(/^"|"$/g, '');
    }
  }
  return { fm, body: text.slice(m[0].length) };
}

function requireString(fm, key, filename) {
  const value = fm[key];
  if (typeof value !== 'string' || !value.trim()) {
    throw new Error(`${filename}: frontmatter field "${key}" must be a non-empty string`);
  }
  return value;
}

function validateFrontmatter(fm, filename) {
  const slug = requireString(fm, 'slug', filename);
  requireString(fm, 'title', filename);
  const date = requireString(fm, 'date', filename);
  const status = requireString(fm, 'status', filename);
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(slug)) {
    throw new Error(`${filename}: frontmatter field "slug" must match ^[a-z0-9]+(?:-[a-z0-9]+)*$`);
  }
  const parsedDate = /^\d{4}-\d{2}-\d{2}$/.test(date)
    ? new Date(`${date}T00:00:00.000Z`)
    : null;
  if (!parsedDate || Number.isNaN(parsedDate.getTime()) || parsedDate.toISOString().slice(0, 10) !== date) {
    throw new Error(`${filename}: frontmatter field "date" must be a real calendar date in YYYY-MM-DD format`);
  }
  if (!['published', 'scheduled', 'draft'].includes(status)) {
    throw new Error(`${filename}: frontmatter field "status" must be published, scheduled, or draft`);
  }
  let readMinutes = 5;
  if (fm.readMinutes !== undefined) {
    if (typeof fm.readMinutes !== 'string' || !Number.isFinite(Number(fm.readMinutes)) || Number(fm.readMinutes) <= 0) {
      throw new Error(`${filename}: frontmatter field "readMinutes" must be a positive number`);
    }
    readMinutes = Number(fm.readMinutes);
  }
  if (fm.tags !== undefined && !Array.isArray(fm.tags)) {
    throw new Error(`${filename}: frontmatter field "tags" must be an array`);
  }
  return { slug, date, status, readMinutes, tags: fm.tags || [] };
}

/** Minimal markdown -> HTML (headings, bold, italic, quotes, lists, paragraphs). */
function slugify(s) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 60);
}
function mdToHtml(md) {
  const lines = md.split('\n');
  const headings = [];
  let html = '';
  let inList = false;
  const inline = (s) =>
    esc(s)
      .replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>')
      .replace(/\*([^*]+)\*/g, '<em>$1</em>')
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2">$1</a>');
  for (const line of lines) {
    const t = line.trim();
    if (t.startsWith('- ')) {
      if (!inList) {
        html += '<ul>';
        inList = true;
      }
      html += `<li>${inline(t.slice(2))}</li>`;
    } else {
      if (inList) {
        html += '</ul>';
        inList = false;
      }
      if (t.startsWith('## ')) {
        const text = t.slice(3);
        headings.push({ id: slugify(text), text });
        html += `<h2 id="${slugify(text)}">${inline(text)}</h2>`;
      }
      else if (t.startsWith('# ')) continue; // title lives in frontmatter
      else if (t.startsWith('> ')) html += `<blockquote>${inline(t.slice(2))}</blockquote>`;
      else if (t === '') continue;
      else html += `<p>${inline(t)}</p>`;
    }
  }
  if (inList) html += '</ul>';
  return { html, headings };
}

function sanitizeInternalLinks(md, liveSlugs) {
  return md.replace(/\[([^\]]+)\]\((\/post\/[^)]+)\)/g, (match, label, href) => {
    const slug = href.split(/[?#]/, 1)[0].replace(/^\/post\//, '');
    return liveSlugs.has(slug) ? match : label;
  });
}

function rfc822(iso) {
  const [y, m, d] = iso.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d, 12)).toUTCString();
}

const STATIC_ROUTES = [
  '/', '/about', '/faq', '/contact', '/download', '/supporters', '/demo',
  '/dice', '/sticker-studio', '/login', '/delete-account', '/blog',
  '/p/safety', '/p/child-safety-policy', '/p/approach-to-safety',
  '/p/guide-to-online-safety', '/p/community-guidelines', '/p/safety-tools',
  '/p/resources', '/p/contact-us', '/p/terms', '/p/privacy', '/p/cookies', '/p/disclaimer',
];

const today = new Date().toISOString().slice(0, 10);
const files = readdirSync(postsDir).filter((f) => f.endsWith('.md')).sort();
const duePosts = [];
for (const file of files) {
  const { fm, body } = parseFm(readFileSync(join(postsDir, file), 'utf8'), file);
  const validated = validateFrontmatter(fm, file);
  const due = validated.status === 'published' || (validated.status === 'scheduled' && validated.date <= today);
  if (due) duePosts.push({ fm, body, validated });
}
const liveSlugs = new Set(duePosts.map(({ validated }) => validated.slug));
const published = [];
for (const { fm, body, validated } of duePosts) {
  const rendered = mdToHtml(sanitizeInternalLinks(body, liveSlugs));
  published.push({
    slug: validated.slug,
    title: fm.title,
    excerpt: fm.excerpt || '',
    date: validated.date,
    readMinutes: validated.readMinutes,
    tags: validated.tags,
    image: fm.image_r2 || fm.image || '',
    credit: fm.credit || '',
    credit_url: fm.credit_url || '',
    html: rendered.html,
    headings: rendered.headings,
  });
}
published.sort((a, b) => b.date.localeCompare(a.date) || a.slug.localeCompare(b.slug));

// Related posts: top 3 by shared tags (then recency), computed once here.
for (const p of published) {
  const scored = published
    .filter((q) => q.slug !== p.slug)
    .map((q) => ({
      q,
      shared: q.tags.filter((t) => p.tags.includes(t)).length,
    }))
    .filter((s) => s.shared > 0)
    .sort((a, b) => b.shared - a.shared || b.q.date.localeCompare(a.q.date) || a.q.slug.localeCompare(b.q.slug))
    .slice(0, 3)
    .map((s) => ({ slug: s.q.slug, title: s.q.title, image: s.q.image }));
  p.related = scored;
}

mkdirSync(outPosts, { recursive: true });
// Clear stale post files (slugs may be removed).
for (const f of readdirSync(outPosts).filter((f) => f.endsWith('.json'))) rmSync(join(outPosts, f));
const index = published.map(({ html, headings, related, ...meta }) => meta);
writeFileSync(outIndex, JSON.stringify(index));
for (const p of published) writeFileSync(join(outPosts, `${p.slug}.json`), JSON.stringify(p));

const latest = published.length ? published[0].date : today;
const sitemapUrls = [
  ...STATIC_ROUTES.map((r) => ({ loc: `${HOST}${r}`, lastmod: latest })),
  ...published.map((p) => ({ loc: `${HOST}/post/${p.slug}`, lastmod: p.date })),
];
writeFileSync(
  join(root, 'public', 'sitemap.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n` +
    sitemapUrls.map((u) => `  <url><loc>${esc(u.loc)}</loc><lastmod>${esc(u.lastmod)}</lastmod></url>`).join('\n') +
    `\n</urlset>\n`,
);
writeFileSync(
  join(root, 'public', 'feed.xml'),
  `<?xml version="1.0" encoding="UTF-8"?>\n<rss version="2.0">\n  <channel>\n` +
    `    <title>SecretMsg Blog</title>\n    <link>${esc(`${HOST}/blog`)}</link>\n` +
    `    <description>Notes on honest messaging, privacy, and anonymous culture.</description>\n    <language>en-us</language>\n` +
    published.slice(0, 50).map((p) =>
      `    <item>\n      <title>${esc(p.title)}</title>\n      <link>${esc(`${HOST}/post/${p.slug}`)}</link>\n` +
      `      <guid isPermaLink="true">${esc(`${HOST}/post/${p.slug}`)}</guid>\n      <pubDate>${rfc822(p.date)}</pubDate>\n      <description>${esc(p.excerpt)}</description>\n    </item>`).join('\n') +
    `\n  </channel>\n</rss>\n`,
);
writeFileSync(join(root, 'public', 'robots.txt'), `User-agent: *\nAllow: /\n\nSitemap: ${HOST}/sitemap.xml\n`);
console.log(`blog: ${published.length} live of ${files.length} files -> index, posts, sitemap, feed, robots`);
