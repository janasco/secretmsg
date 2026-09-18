/**
 * Fallback hero art: deterministic gradient + emoji SVG per post, used until
 * real Pixabay photos land (blog-images.mjs overwrites image/credit then).
 * Keeps every post fully visual with zero external dependencies.
 */
import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const postsDir = join(root, 'content', 'posts');
const imgDir = join(root, 'public', 'blog-images');

const PALETTES = [
  ['#4F46E5', '#1E1B4B'], ['#78350F', '#1E1B4B'], ['#022C22', '#042F2E'],
  ['#831843', '#3B0764'], ['#0F111A', '#1E1B4B'], ['#7C2D12', '#431407'],
  ['#164E63', '#0C4A6E'], ['#3B0764', '#581C87'], ['#14532D', '#052E16'],
  ['#881337', '#4C0519'],
];
const EMOJI = ['💬', '🔥', '💡', '🛡️', '✨', '💘', '🎲', '🌙', '⚡', '💜', '🌟', '📝'];

function hash(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function fmGet(text, key) {
  const m = text.match(new RegExp(`^${key}:\\s*(.*)$`, 'm'));
  return m ? m[1].trim().replace(/^"|"$/g, '') : '';
}

mkdirSync(imgDir, { recursive: true });
const files = readdirSync(postsDir).filter((f) => f.endsWith('.md'));
let made = 0;
for (const file of files) {
  const slug = file.replace(/\.md$/, '');
  const dest = join(imgDir, `${slug}.svg`);
  if (existsSync(dest)) continue;
  const text = readFileSync(join(postsDir, file), 'utf8');
  const h = hash(slug);
  const [c1, c2] = PALETTES[h % PALETTES.length];
  const emoji = EMOJI[h % EMOJI.length];
  const title = (fmGet(text, 'title') || slug).slice(0, 60);
  const svg =
    `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">` +
    `<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1">` +
    `<stop offset="0" stop-color="${c1}"/><stop offset="1" stop-color="${c2}"/>` +
    `</linearGradient></defs>` +
    `<rect width="1200" height="630" fill="url(#g)"/>` +
    `<circle cx="1050" cy="90" r="180" fill="#ffffff" opacity="0.06"/>` +
    `<circle cx="120" cy="560" r="140" fill="#ffffff" opacity="0.05"/>` +
    `<text x="100" y="360" font-size="150">${emoji}</text>` +
    `<text x="100" y="470" font-family="Inter,Arial,sans-serif" font-size="44" font-weight="800" fill="#ffffff">${title.replace(/&/g, '&amp;').replace(/</g, '&lt;')}</text>` +
    `<text x="100" y="530" font-family="Inter,Arial,sans-serif" font-size="28" fill="#A5B4FC">secretmsg.net/blog</text>` +
    `</svg>`;
  writeFileSync(dest, svg);

  // Point the post at the fallback art (photo pipeline overwrites later).
  const updated = text.replace(/^image: ""$/m, `image: "/blog-images/${slug}.svg"`);
  if (updated !== text) {
    const withCredit = updated.replace(/^credit: ""$/m, 'credit: "SecretMsg Studio"');
    writeFileSync(join(postsDir, file), withCredit);
    made++;
  }
}
console.log(`fallback heroes: ${made} wired`);
