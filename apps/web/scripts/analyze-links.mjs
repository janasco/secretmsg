import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

const root = process.cwd();
const postsDir = join(root, 'content', 'posts');
const publicDir = join(root, 'public');
const today = new Date().toISOString().slice(0, 10);

function parseFm(text, filename) {
  const m = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) throw new Error(`${filename}: missing frontmatter`);
  const fm = {};
  for (const line of m[1].split('\n')) {
    const i = line.indexOf(':');
    if (i > 0) fm[line.slice(0, i).trim()] = line.slice(i + 1).trim().replace(/^"|"$/g, '');
  }
  return { fm, body: text.slice(m[0].length) };
}

function targetSlug(href) {
  return href.split(/[?#]/, 1)[0].replace(/^\/post\//, '').replace(/\/$/, '');
}

function markdownLinks(text) {
  const links = [];
  for (const match of text.matchAll(/\]\((\/post\/[^)]+)\)/g)) {
    links.push({ href: match[1], index: match.index + 2 });
  }
  return links;
}

function emittedLinks(text) {
  const links = [];
  for (const match of text.matchAll(/\/post\/[a-z0-9-]+/g)) {
    links.push({ href: match[0], index: match.index });
  }
  return links;
}

const files = readdirSync(postsDir).filter((f) => f.endsWith('.md')).sort();
const posts = files.map((file) => {
  const parsed = parseFm(readFileSync(join(postsDir, file), 'utf8'), file);
  return { file, ...parsed };
});
const live = new Set(
  posts
    .filter(({ fm }) => (fm.status === 'published' || fm.status === 'scheduled') && fm.date <= today)
    .map(({ fm }) => fm.slug),
);
const broken = [];
let total = 0;
for (const post of posts) {
  for (const link of markdownLinks(post.body)) {
    total += 1;
    const slug = targetSlug(link.href);
    if (!live.has(slug)) broken.push({ file: post.file, href: link.href, slug, status: post.fm.status, date: post.fm.date });
  }
}
console.log(`today: ${today}`);
console.log(`markdown files: ${files.length}`);
console.log(`live slugs: ${live.size}`);
console.log(`markdown /post links: ${total}`);
console.log(`broken markdown /post links: ${broken.length}`);
for (const link of broken) console.log(`${link.file}\t${link.href}\t${link.status}\t${link.date}`);

const renderedBroken = broken.filter((link) => live.has(posts.find((post) => post.file === link.file).fm.slug));
console.log(`broken rendered-source /post links: ${renderedBroken.length}`);
for (const link of renderedBroken) console.log(`rendered\t${link.file}\t${link.href}\t${link.status}\t${link.date}`);

if (process.argv.includes('--emitted')) {
  let emittedTotal = 0;
  const emittedBroken = [];
  const emittedFiles = [
    join(publicDir, 'blog-index.json'),
    ...readdirSync(join(publicDir, 'posts')).filter((f) => f.endsWith('.json')).map((f) => join(publicDir, 'posts', f)),
  ];
  for (const file of emittedFiles) {
    const text = readFileSync(file, 'utf8');
    for (const link of emittedLinks(text)) {
      emittedTotal += 1;
      const slug = targetSlug(link.href);
      if (!live.has(slug)) emittedBroken.push({ file, href: link.href, slug });
    }
  }
  console.log(`emitted /post links: ${emittedTotal}`);
  console.log(`broken emitted /post links: ${emittedBroken.length}`);
  for (const link of emittedBroken) console.log(`${link.file}\t${link.href}`);
}
