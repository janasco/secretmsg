/**
 * Blog image pipeline: Pixabay -> local -> (later) R2 + cdn.secretmsg.net.
 *
 * Usage:
 *   node scripts/blog-images.mjs                 # fetch missing images to public/blog-images/
 *   node scripts/blog-images.mjs --upload-r2     # also upload to R2 + fill image_r2 (needs R2 enabled)
 *
 * Env (secretmsg-private/.env.production):
 *   PIXABAY_API_KEY   Pixabay API key
 *   R2_BUCKET         R2 bucket for blog images (e.g. secretmsg-cdn)
 *   CDN_BASE          public base, default https://cdn.secretmsg.net
 *
 * Attribution is mandatory per Pixabay terms: photographer + source URL are
 * written into frontmatter and rendered under every hero image.
 */
import { readdirSync, readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const postsDir = join(root, 'content', 'posts');
const imgDir = join(root, 'public', 'blog-images');
const uploadR2 = process.argv.includes('--upload-r2');
const PIXABAY_KEY = (process.env.PIXABAY_API_KEY || '').trim().replace(/^"|"$/g, '');
const R2_BUCKET = (process.env.R2_BUCKET || '').trim().replace(/^"|"$/g, '');
const CDN_BASE = (process.env.CDN_BASE || 'https://cdn.secretmsg.net').trim().replace(/^"|"$/g, '').replace(/\/$/, '');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function parseFm(text) {
  const m = text.match(/^---\n([\s\S]*?)\n---\n/);
  if (!m) return null;
  const fm = {};
  for (const line of m[1].split('\n')) {
    const i = line.indexOf(':');
    if (i > 0) fm[line.slice(0, i).trim()] = line.slice(i + 1).trim().replace(/^"|"$/g, '');
  }
  return { fm, end: m[0].length };
}

function dumpFm(fm, order) {
  const lines = ['---'];
  for (const k of order) {
    if (fm[k] !== undefined) {
      const v = fm[k];
      lines.push(/[:#\n]/.test(v) || v === '' ? `${k}: "${v.replace(/"/g, "'")}"` : `${k}: ${v}`);
    }
  }
  for (const k of Object.keys(fm)) {
    if (!order.includes(k)) lines.push(`${k}: "${fm[k]}"`);
  }
  lines.push('---', '');
  return lines.join('\n');
}

async function pixabaySearch(query) {
  const url = 'https://pixabay.com/api/?' + new URLSearchParams({
    key: PIXABAY_KEY,
    q: query,
    image_type: 'photo',
    orientation: 'landscape',
    per_page: '5',
    safesearch: 'true',
  });
  const res = await fetch(url);
  if (!res.ok) throw new Error(`pixabay ${res.status}`);
  const data = await res.json();
  const hits = (data.hits || []).filter((h) => h.webformatURL && h.user && h.pageURL);
  return hits[0] || null;
}

async function download(url, dest) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`download ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  writeFileSync(dest, buf);
  return buf.length;
}

function r2Put(local, remote) {
  execSync(
    `node /opt/secretmsg/node_modules/wrangler/bin/wrangler.js r2 object put ${R2_BUCKET}/${remote} --file=${local} --remote`,
    { stdio: 'pipe' },
  );
}

async function main() {
  mkdirSync(imgDir, { recursive: true });
  const files = readdirSync(postsDir).filter((f) => f.endsWith('.md'));
  const order = ['title', 'slug', 'date', 'status', 'tags', 'excerpt', 'pixabay', 'readMinutes', 'image', 'image_r2', 'credit', 'credit_url'];
  let fetched = 0, skipped = 0, failed = 0;
  for (const file of files) {
    const path = join(postsDir, file);
    const text = readFileSync(path, 'utf8');
    const parsed = parseFm(text);
    if (!parsed) continue;
    const { fm, end } = parsed;
    const slug = fm.slug || file.replace(/\.md$/, '');
    const localName = `${slug}.jpg`;
    const localPath = join(imgDir, localName);
    let dirty = false;

    if ((!fm.image || !existsSync(localPath)) && fm.pixabay) {
      if (!PIXABAY_KEY) {
        console.log(`no-key skip ${slug}`);
        failed++;
        continue;
      }
      try {
        const hit = await pixabaySearch(fm.pixabay);
        if (!hit) throw new Error('no hits');
        await download(hit.webformatURL, localPath);
        fm.image = `/blog-images/${localName}`;
        fm.credit = hit.user;
        fm.credit_url = hit.pageURL;
        dirty = true;
        fetched++;
        await sleep(400); // Pixabay rate courtesy
      } catch (e) {
        console.log(`fail ${slug} (${fm.pixabay}): ${e.message}`);
        failed++;
        continue;
      }
    } else {
      skipped++;
    }

    if (uploadR2 && existsSync(localPath)) {
      if (!R2_BUCKET) {
        console.log('R2_BUCKET not set; skipping upload. Enable R2 + set bucket first.');
        process.exitCode = 1;
        break;
      }
      try {
        r2Put(localPath, `blog/${localName}`);
        fm.image_r2 = `${CDN_BASE}/blog/${localName}`;
        dirty = true;
      } catch (e) {
        console.log(`r2 fail ${slug}: enable R2 on the account first.`);
        process.exitCode = 1;
        break;
      }
    }

    if (dirty) writeFileSync(path, dumpFm(fm, order) + text.slice(end));
  }
  console.log(`images: ${fetched} fetched, ${skipped} skipped, ${failed} failed of ${files.length}`);
}

main();
