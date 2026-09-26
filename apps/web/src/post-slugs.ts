// The set of post slugs that exist in this build, and the loader for it.
//
// blog.mjs publishes a post when its status is `published`, or `scheduled` with a
// date that has already passed. The array it publishes is what it writes to
// public/blog-index.json, what it turns into sitemap.xml and feed.xml, and what
// prerender.mjs prerenders one HTML page per entry from. So "is this post
// live" has exactly one answer in this repo, and the Worker needs that answer
// to decide a status code.
//
// Why the Worker needs it at all: the site runs with run_worker_first = false,
// so a /post/<slug> that has a prerendered page in dist is answered by the asset
// layer and the Worker never runs. The Worker only ever sees a /post/<slug> that
// has no page, and every one of those is a slug the build does not ship. Serving
// the SPA shell with a 200 for them is what makes a typo'd or invented URL look
// like a real article URL to a crawler.
//
// A post that is `scheduled` but not yet due is deliberately NOT in this set,
// because blog.mjs deliberately does not ship it either: it is absent from
// blog-index.json, from the sitemap, from the feed, and has no prerendered page.
// It therefore 404s until the first build on or after its date, at which point
// the same date comparison that keeps it out of the sitemap puts it in this set
// and prerenders its page, and the asset layer starts answering it. No manual
// step, and the status code cannot disagree with the sitemap.
//
// The set ships as dist/post-slugs.json, written by prerender.mjs alongside
// dist/_headers and dist/_redirects, and it is a generated *asset* rather than a
// generated .ts module on purpose: prerender.mjs runs as postbuild, so a module
// under src/ would not exist on a clean checkout and `tsc --noEmit` — which the
// verify script runs before the build — would fail on a fresh clone. It leaks
// nothing: the same URLs are already public in sitemap.xml.
export const POST_SLUGS_PATH = '/post-slugs.json';

export interface AssetFetcher {
  fetch(input: Request | URL | string): Promise<Response>;
}

// Keyed by the ASSETS binding rather than by a module-level variable so the
// cache is per environment: one entry per isolate in production, and a fresh
// cache for every stub in tests without a test-only reset hook.
const cache = new WeakMap<AssetFetcher, Promise<ReadonlySet<string> | null>>();

function parseSlugs(body: unknown): ReadonlySet<string> | null {
  if (!Array.isArray(body)) return null;
  const slugs = body.filter((slug): slug is string => typeof slug === 'string' && slug.length > 0);
  return slugs.length > 0 ? new Set(slugs) : null;
}

/**
 * Slugs the current build ships, cached per assets binding, or null when the
 * list cannot be read.
 *
 * `origin` supplies the absolute URL for the subrequest. The ASSETS binding
 * resolves a Request against a URL and will not resolve a bare relative string
 * on its own, so the path is made absolute against the request being answered.
 *
 * Null means "unknown", not "none", and the caller must not 404 on it: a build
 * that somehow lost the asset then serves the SPA shell with a 200 for every
 * /post/:slug that reaches the Worker, which is the behaviour that existed
 * before this list existed. A broken asset degrades the status code instead of
 * taking the blog's client routing offline.
 */
export function loadPostSlugs(assets: AssetFetcher, origin: URL): Promise<ReadonlySet<string> | null> {
  const cached = cache.get(assets);
  if (cached) return cached;
  const pending = assets.fetch(new Request(new URL(POST_SLUGS_PATH, origin)))
    .then((response) => (response.ok ? response.json() : null))
    .then(parseSlugs)
    .catch(() => null);
  cache.set(assets, pending);
  return pending;
}
