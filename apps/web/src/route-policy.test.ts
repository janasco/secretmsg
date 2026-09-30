import { describe, expect, it, vi } from 'vitest';
import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { isAssetRequest, isClientRoute, isNoindexRoute, legacyRedirect, notFoundHtml, postSlug } from './route-policy';
import { POST_SLUGS_PATH } from './post-slugs';
import { CSP_REPORT_MAX_BYTES, CSP_REPORT_PATH, SECURITY_HEADERS } from './security-headers';
import { handleRequest, type WorkerEnv } from './worker';

const PUBLIC_DIR = resolve(__dirname, '..', 'public');

type SiteManifest = {
  HOST: string;
  STATIC_ROUTES: Array<{ path: string }>;
  /** Routes that require a session; deliberately not in STATIC_ROUTES. */
  ACCOUNT_ROUTES: string[];
};
type GlobImportMeta = ImportMeta & {
  glob: (pattern: string, options: { eager: boolean }) => Record<string, SiteManifest>;
};

const manifest = (import.meta as GlobImportMeta).glob(
  '../scripts/site-manifest.mjs',
  { eager: true },
)['../scripts/site-manifest.mjs'] as SiteManifest;

/**
 * The slugs blog.mjs published, which is the same array behind sitemap.xml,
 * feed.xml and the prerendered pages. A worker stub serves this as
 * dist/post-slugs.json so the tests exercise the same list the build emits.
 */
const LIVE_SLUGS: string[] = (JSON.parse(readFileSync(resolve(PUBLIC_DIR, 'blog-index.json'), 'utf8')) as Array<{ slug: string }>)
  .map((post) => post.slug);

/** Every URL the site publishes, as sitemap.xml lists them. */
const SITEMAP_LOCS: string[] = [...readFileSync(resolve(PUBLIC_DIR, 'sitemap.xml'), 'utf8')
  .matchAll(/<loc>([^<]*)<\/loc>/g)]
  .map((match) => match[1]);

const SITEMAP_PATHS: string[] = SITEMAP_LOCS.map((loc) => loc.slice(manifest.HOST.length) || '/');

/**
 * A post marked `scheduled` with a date in the future. blog.mjs ships it only
 * once that date has passed, so until then it is in no sitemap, no feed, no
 * blog index and no prerendered page, and /post/<slug> must not claim it exists.
 */
const SCHEDULED_SLUG = 'android-app-mastery-advanced';

function frontmatterOf(slug: string): Record<string, string> {
  const body = readFileSync(resolve(__dirname, '..', 'content', 'posts', `${slug}.md`), 'utf8');
  const block = body.match(/^---\n([\s\S]*?)\n---\n/);
  if (!block) throw new Error(`${slug}: frontmatter is missing`);
  const fields: Record<string, string> = {};
  for (const line of block[1].split('\n')) {
    const at = line.indexOf(':');
    fields[line.slice(0, at).trim()] = line.slice(at + 1).trim();
  }
  return fields;
}

function isSlugListRequest(input: Request | URL | string): boolean {
  const path = typeof input === 'string'
    ? input
    : input instanceof URL ? input.pathname : new URL(input.url).pathname;
  return path === POST_SLUGS_PATH;
}

function environment(slugs: string[] = LIVE_SLUGS): WorkerEnv {
  return {
    ASSETS: {
      fetch: vi.fn(async (input: Request | URL | string) => {
        if (isSlugListRequest(input)) {
          return new Response(JSON.stringify(slugs), {
            status: 200,
            headers: { 'content-type': 'application/json' },
          });
        }
        return new Response('<!doctype html><title>SPA</title>', {
          status: 200,
          headers: { 'content-type': 'text/html' },
        });
      }),
    },
  };
}

/** Subrequests for the SPA shell, as opposed to the post-slug list. */
function shellCalls(env: WorkerEnv): Request[] {
  return (env.ASSETS.fetch as ReturnType<typeof vi.fn>).mock.calls
    .map(([input]) => input)
    .filter((input): input is Request => input instanceof Request && !isSlugListRequest(input));
}

function expectSecurityHeaders(response: Response): void {
  expect(response.headers.get('x-content-type-options')).toBe('nosniff');
  expect(response.headers.get('x-frame-options')).toBe('DENY');
  expect(response.headers.get('referrer-policy')).toBe('strict-origin-when-cross-origin');
  expect(response.headers.get('content-security-policy-report-only')).toBe(
    SECURITY_HEADERS['Content-Security-Policy-Report-Only'],
  );
}

describe('route policy', () => {
  it('identifies missing files without treating client routes as files', () => {
    expect(isAssetRequest('/downloads/secretmsg-android-v1.3.0-arm64.apk')).toBe(true);
    expect(isAssetRequest('/downloads/anything')).toBe(true);
    expect(isAssetRequest('/images/missing.PNG')).toBe(true);
    expect(isAssetRequest('/data/missing.json')).toBe(true);
    expect(isAssetRequest('/missing.html')).toBe(true);
    expect(isAssetRequest('/assets/missing.js.')).toBe(false);
    expect(isAssetRequest('/_redirects.tmp')).toBe(true);
    expect(isAssetRequest('/janasco')).toBe(false);
    expect(isAssetRequest('/reply/abc123')).toBe(false);
    expect(isAssetRequest('/post/scheduled-slug.js')).toBe(false);
    expect(isAssetRequest('/legal/terms.js')).toBe(false);
    expect(isAssetRequest('/nope.js')).toBe(true);
    expect(isAssetRequest('/missing.png')).toBe(true);
    expect(isAssetRequest('/foo', '?x=.js')).toBe(true);
  });

  it('allows every static and dynamic client route', () => {
    const clientRoutes = [
      '/', '/about', '/faq', '/contact', '/download', '/supporters', '/demo',
      '/login', '/delete-account', '/blog', '/p/safety',
      '/p/child-safety-policy', '/p/approach-to-safety', '/p/guide-to-online-safety',
      '/p/community-guidelines', '/p/safety-tools', '/p/resources', '/p/contact-us',
      '/p/terms', '/p/privacy', '/p/cookies', '/p/disclaimer', '/inbox', '/settings',
      // Account-only tools: still client routes, so the Worker serves the SPA
      // shell rather than 404ing. They are gated in the UI, not here.
      '/dice', '/sticker-studio',
    ];

    for (const route of clientRoutes) expect(isClientRoute(route)).toBe(true);
    for (const route of ['/reply/abc123', '/post/not-live', '/legal/terms.js', '/someuser', '/janasco']) {
      expect(isClientRoute(route)).toBe(true);
    }
  });

  it('maps legacy aliases to canonical trailing-slash URLs', () => {
    expect(legacyRedirect('/donors')).toBe('/supporters/');
    expect(legacyRedirect('/p/legal/privacy')).toBe('/p/privacy/');
    expect(legacyRedirect('/legal/terms/')).toBe('/p/terms/');
    expect(legacyRedirect('/p/privacy/')).toBeNull();
    expect(legacyRedirect('/legal/unknown')).toBeNull();
  });
});

describe('board URLs match the API username rule', () => {
  // api/src/random.ts isValidUsername: /^[a-z0-9_.-]{4,30}$/ — the same
  // normalisation on both sides, since the API lowercases a handle and
  // isClientRoute lowercases the path. A handle the API rejects with 400 must
  // not be a board URL, or the Worker advertises a board that cannot exist and
  // the board page's own API call comes back 400.
  it('accepts real handles', () => {
    for (const handle of ['janasco', 'lumen4821', 'abcd', 'some.user_name-1', 'a.bc', 'ab_cd', 'ab-cd', '____', '2026']) {
      expect(isClientRoute(`/${handle}`)).toBe(true);
      expect(isAssetRequest(`/${handle}`)).toBe(false);
    }
  });

  it('rejects handles shorter than four characters', () => {
    for (const handle of ['a', 'ab', 'abc', 'a.b', '_.', '...']) {
      expect(isClientRoute(`/${handle}`)).toBe(false);
      expect(isAssetRequest(`/${handle}`)).toBe(false);
    }
  });

  it('rejects handles longer than thirty characters and accepts exactly thirty', () => {
    const thirty = 'a'.repeat(30);
    const thirtyOne = 'a'.repeat(31);

    expect(isClientRoute(`/${thirty}`)).toBe(true);
    expect(isClientRoute(`/${thirtyOne}`)).toBe(false);
  });

  it('rejects characters outside the API charset without turning them into assets', () => {
    for (const handle of ['ab$cd', 'ab%20cd', 'ab+cd', 'ab cd', 'ab~cd', 'ab!cd', 'ab&cd']) {
      expect(isClientRoute(`/${handle}`)).toBe(false);
      expect(isAssetRequest(`/${handle}`)).toBe(false);
    }
  });

  it('still rejects dot-prefixed, dot-suffixed and asset-shaped segments', () => {
    expect(isClientRoute('/.janasco')).toBe(false);
    expect(isClientRoute('/janasco.')).toBe(false);
    expect(isClientRoute('/janasco.png')).toBe(false);
    expect(isAssetRequest('/janasco.png')).toBe(true);
  });
});

describe('the real route surface is untouched by the username rule', () => {
  // The safety property: a route that is a real file in dist is answered by the
  // asset layer before the Worker runs, so a classification change here can only
  // ever cost the Worker a 404. Every published URL must therefore still be a
  // client route and must not be mistaken for a missing asset.
  it('classifies all 238 prerendered and canonical pages as client routes', () => {
    // 238 = 216 blog posts + 22 static routes.
    //
    // It was 239 before `summer-break-boards-psychology` had its generated
    // output committed (see the chore(blog) commit), briefly 240, and is 238
    // now that /dice and /sticker-studio moved out of STATIC_ROUTES to sit
    // behind a session.
    expect(SITEMAP_PATHS.length).toBe(238);

    for (const path of SITEMAP_PATHS) {
      expect(isClientRoute(path), path).toBe(true);
      expect(isAssetRequest(path), path).toBe(false);
    }
  });

  it('covers every route in the site manifest and every account route', () => {
    const manifestPaths = manifest.STATIC_ROUTES.map((route) => route.path);

    for (const path of [...manifestPaths, '/inbox', '/settings']) {
      expect(isClientRoute(path), path).toBe(true);
    }
    // The manifest and the sitemap are generated from one list, so every static
    // route has to appear in the sitemap or a canonical page is going missing.
    for (const path of manifestPaths) {
      expect(SITEMAP_LOCS, path).toContain(path === '/' ? manifest.HOST : `${manifest.HOST}${path}/`);
    }
  });

  it('keeps every published post a client route under its canonical form', () => {
    for (const slug of LIVE_SLUGS) {
      expect(isClientRoute(`/post/${slug}`), slug).toBe(true);
      expect(isClientRoute(`/post/${slug}/`), slug).toBe(true);
      expect(isAssetRequest(`/post/${slug}`), slug).toBe(false);
    }
  });

  it('reads the post slug out of a canonical post URL and nothing else', () => {
    expect(postSlug('/post/summer-break-boards-mistakes')).toBe('summer-break-boards-mistakes');
    expect(postSlug('/post/summer-break-boards-mistakes/')).toBe('summer-break-boards-mistakes');
    expect(postSlug('/POST/Summer-Break-Boards-Mistakes')).toBe('summer-break-boards-mistakes');
    expect(postSlug('/post')).toBeNull();
    expect(postSlug('/post/')).toBeNull();
    expect(postSlug('/post/a/b')).toBeNull();
    expect(postSlug('/inbox')).toBeNull();
  });

  it('leaves bare /post and /reply on the username fallthrough', () => {
    // 'post' and 'reply' are legal handles, so isClientRoute cannot tell them
    // apart from a board. They stay 200 and the SPA renders the username route.
    expect(isClientRoute('/post')).toBe(true);
    expect(isClientRoute('/reply')).toBe(true);
  });
});

describe('noindex classification', () => {
  it('covers the account routes only', () => {
    expect(isNoindexRoute('/inbox')).toBe(true);
    expect(isNoindexRoute('/settings')).toBe(true);
    expect(isNoindexRoute('/dice')).toBe(true);
    expect(isNoindexRoute('/sticker-studio')).toBe(true);
    expect(isNoindexRoute('/inbox/')).toBe(true);
    expect(isNoindexRoute('/SETTINGS')).toBe(true);
    expect(isNoindexRoute('/DICE')).toBe(true);
  });

  it('covers nothing that is published', () => {
    for (const path of ['/', '/about', '/login', '/blog', '/download', '/p/privacy', '/janasco', '/reply/abc123', '/post/summer-break-boards-mistakes']) {
      expect(isNoindexRoute(path), path).toBe(false);
    }
  });
});

/**
 * The account-only tools.
 *
 * The gate in the UI is a product affordance, not the control that keeps these
 * private. What actually keeps them private is that they are absent from
 * `site-manifest.mjs`'s STATIC_ROUTES: that list is walked by the prerenderer
 * (writing public HTML into dist) and by blog.mjs (writing sitemap.xml). A
 * route in it is already a fetchable file on disk before any JavaScript runs,
 * so a lock screen drawn over prerendered content protects nothing.
 *
 * These assertions are deliberately at the manifest level rather than on the
 * rendered route, because that is the layer where a future "small tidy-up,
 * move the tool back with the others" would quietly re-publish both pages with
 * every test still green.
 */
describe('account-only tools are not published', () => {
  const GATED = ['/dice', '/sticker-studio'];

  it('keeps them out of the prerendered route manifest', () => {
    const published = new Set(manifest.STATIC_ROUTES.map((r) => r.path));
    for (const route of GATED) {
      expect(published.has(route), `${route} must not be in STATIC_ROUTES`).toBe(false);
    }
  });

  it('keeps them out of the generated sitemap', () => {
    for (const route of GATED) {
      const expected = `${manifest.HOST}${route}/`;
      expect(SITEMAP_LOCS, `${route} must not be in sitemap.xml`).not.toContain(expected);
    }
  });

  it('still serves them as client routes so the Worker does not 404', () => {
    // Being unpublished must not mean unreachable: the SPA shell is what the
    // gate is rendered into.
    for (const route of GATED) {
      expect(isClientRoute(route), route).toBe(true);
      expect(isClientRoute(`${route}/`), route).toBe(true);
      expect(isAssetRequest(route), route).toBe(false);
    }
  });

  it('declares them as account routes in the manifest', () => {
    expect([...manifest.ACCOUNT_ROUTES].sort()).toEqual([...GATED].sort());
  });

  it('noindexes them, so a stale link is not indexed from anywhere', () => {
    for (const route of GATED) {
      expect(isNoindexRoute(route), route).toBe(true);
    }
  });
});

describe('asset worker', () => {
  it('returns a real 404 for missing files', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/downloads/old.apk'), env);

    expect(response.status).toBe(404);
    expect(response.headers.get('content-type')).toBe('text/html; charset=utf-8');
    expectSecurityHeaders(response);
    expect(await response.text()).toContain('404 - File not found');
    expect(env.ASSETS.fetch).not.toHaveBeenCalled();
  });

  it('rejects malformed and non-route paths before the SPA fallback', async () => {
    const malformedPaths = [
      '/missing.html',
      '/foo%2Ejs',
      '/about.',
      '/assets/missing.js.',
      '/_redirects',
      '/_redirects.tmp',
      '/foo?x=.js',
      '/a',
      '/ab',
      '/abc',
      `/${'a'.repeat(31)}`,
    ];

    for (const path of malformedPaths) {
      const env = environment();
      const response = await handleRequest(new Request(`https://secretmsg.net${path}`), env);
      expect(response.status, path).toBe(404);
      expect(await response.text(), path).toContain('404 - File not found');
      expect(env.ASSETS.fetch).not.toHaveBeenCalled();
    }
  });

  it('serves the SPA shell for dynamic client routes', async () => {
    const env = environment();
    const response = await handleRequest(new Request(`https://secretmsg.net/post/${LIVE_SLUGS[0]}`), env);

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('text/html');
    expectSecurityHeaders(response);
    expect(await response.text()).toContain('<title>SPA</title>');
    expect(shellCalls(env)).toHaveLength(1);
  });

  it('serves extension-like values below client-route prefixes but not bare asset paths', async () => {
    // /post/x.js is a client route rather than an asset, but no slug can carry a
    // dot, so it is also a slug this build does not ship and 404s.
    expect(isAssetRequest('/legal/terms.js')).toBe(false);
    expect(isAssetRequest('/post/scheduled-slug.js')).toBe(false);

    const legal = await handleRequest(new Request('https://secretmsg.net/legal/terms.js'), environment());
    expect(legal.status).toBe(200);

    const post = await handleRequest(new Request('https://secretmsg.net/post/scheduled-slug.js'), environment());
    expect(post.status).toBe(404);
  });

  it('preserves HEAD when fetching the SPA shell', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/reply/abc123', { method: 'HEAD' }), env);
    const [shellRequest] = shellCalls(env);

    expect(response.status).toBe(200);
    expect(shellRequest.method).toBe('HEAD');
    expect(shellRequest.url).toBe('https://secretmsg.net/');
    expectSecurityHeaders(response);
  });

  it('keeps unsafe methods out of the SPA fallback', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/reply/abc123', { method: 'POST' }), env);

    expect(response.status).toBe(404);
    expect(env.ASSETS.fetch).not.toHaveBeenCalled();
    expectSecurityHeaders(response);
  });

  it('permanently redirects legacy aliases', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/donors'), env);

    expect(response.status).toBe(301);
    expect(response.headers.get('location')).toBe('/supporters/');
    expectSecurityHeaders(response);
    expect(env.ASSETS.fetch).not.toHaveBeenCalled();
  });
});

describe('post slugs this build does not ship', () => {
  it('serves a real post slug from the published list with a 200', async () => {
    const slug = LIVE_SLUGS.find((candidate) => candidate === 'summer-break-boards-mistakes') ?? LIVE_SLUGS[0];
    const env = environment([slug]);
    const response = await handleRequest(new Request(`https://secretmsg.net/post/${slug}`), env);

    expect(response.status).toBe(200);
    expect(response.headers.get('x-robots-tag')).toBeNull();
    expect(await response.text()).toContain('<title>SPA</title>');
  });

  it('404s an invented slug instead of passing it off as an article', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/post/this-post-does-not-exist'), env);

    expect(response.status).toBe(404);
    expect(response.headers.get('content-type')).toBe('text/html; charset=utf-8');
    expect(response.headers.get('cache-control')).toBe('no-store');
    expectSecurityHeaders(response);
    expect(await response.text()).toContain('404 - File not found');
    expect(shellCalls(env)).toHaveLength(0);
  });

  it('404s a scheduled post that is not yet published, and the build agrees', () => {
    const frontmatter = frontmatterOf(SCHEDULED_SLUG);
    const today = new Date().toISOString().slice(0, 10);

    expect(frontmatter.status).toBe('scheduled');
    expect(frontmatter.slug).toBe(SCHEDULED_SLUG);
    expect(frontmatter.date > today).toBe(true);
    // The status code cannot disagree with the sitemap: the slug is in no
    // published list because blog.mjs does not ship it either.
    expect(LIVE_SLUGS).not.toContain(SCHEDULED_SLUG);
    expect(SITEMAP_PATHS).not.toContain(`/post/${SCHEDULED_SLUG}/`);
  });

  it('starts shipping a scheduled post the moment its date passes', async () => {
    // The same frontmatter, one day past its date, is in the list and served.
    const slug = frontmatterOf(SCHEDULED_SLUG).slug;
    const env = environment([...LIVE_SLUGS, slug]);
    const response = await handleRequest(new Request(`https://secretmsg.net/post/${slug}`), env);

    expect(response.status).toBe(200);
  });

  it('serves the shell when the slug list cannot be read', async () => {
    // Missing asset, error status and a thrown subrequest all mean "unknown",
    // and unknown must not 404: the pre-existing behaviour is the fallback.
    const shells: Record<string, () => Promise<Response>> = {
      'error status': async () => new Response('nope', { status: 500 }),
      'non-JSON body': async () => new Response('<!doctype html><title>404</title>', { status: 200 }),
      'thrown subrequest': async () => { throw new Error('asset unavailable'); },
    };

    for (const [name, slugList] of Object.entries(shells)) {
      const env: WorkerEnv = {
        ASSETS: {
          fetch: vi.fn(async (input: Request | URL | string) => (isSlugListRequest(input)
            ? slugList()
            : new Response('<!doctype html><title>SPA</title>', { status: 200, headers: { 'content-type': 'text/html' } }))),
        },
      };
      const response = await handleRequest(new Request('https://secretmsg.net/post/this-post-does-not-exist'), env);

      expect(response.status, name).toBe(200);
      expect(await response.text(), name).toContain('<title>SPA</title>');
    }
  });
});

describe('routes whose status must not move', () => {
  it('keeps every shareable and account URL on a 200', async () => {
    for (const path of ['/janasco', '/lumen4821', '/inbox', '/settings', '/reply/abc123', '/post', '/reply']) {
      const env = environment();
      const response = await handleRequest(new Request(`https://secretmsg.net${path}`), env);

      expect(response.status, path).toBe(200);
      expect(await response.text(), path).toContain('<title>SPA</title>');
    }
  });
});

describe('robots headers', () => {
  it('noindexes /inbox and /settings', async () => {
    for (const path of ['/inbox', '/settings']) {
      const response = await handleRequest(new Request(`https://secretmsg.net${path}`), environment());

      expect(response.status, path).toBe(200);
      expect(response.headers.get('x-robots-tag'), path).toBe('noindex');
      expectSecurityHeaders(response);
    }
  });

  it('adds no robots header to anything else the Worker answers', async () => {
    for (const path of ['/', '/about', '/janasco', '/reply/abc123', '/post', `/post/${LIVE_SLUGS[0]}`]) {
      const response = await handleRequest(new Request(`https://secretmsg.net${path}`), environment());

      expect(response.status, path).toBe(200);
      expect(response.headers.get('x-robots-tag'), path).toBeNull();
    }
  });

  it('adds no robots header to the 404 answers', async () => {
    const notFound = await handleRequest(new Request('https://secretmsg.net/post/this-post-does-not-exist'), environment());
    const missing = await handleRequest(new Request('https://secretmsg.net/downloads/old.apk'), environment());

    expect(notFound.headers.get('x-robots-tag')).toBeNull();
    expect(missing.headers.get('x-robots-tag')).toBeNull();
  });
});

const POLICY = SECURITY_HEADERS['Content-Security-Policy-Report-Only'];

function directive(policy: string, name: string): string {
  const found = policy.split(';').map((part) => part.trim()).find((part) => part.startsWith(`${name} `));
  if (found === undefined) throw new Error(`No ${name} directive in the report-only policy`);
  return found;
}

/** Every script element in the markup with no src, i.e. the ones with a body. */
function inlineScriptBodies(html: string): string[] {
  return [...html.matchAll(/<script([^>]*)>([\s\S]*?)<\/script>/g)]
    .filter(([, attributes]) => !/\bsrc\s*=/.test(attributes))
    .map(([, , body]) => body);
}

const REPORT_BODY = JSON.stringify({
  'csp-report': {
    'document-uri': 'https://secretmsg.net/p/privacy/',
    'effective-directive': 'script-src',
    'violated-directive': 'script-src',
    'blocked-uri': 'eval',
    disposition: 'report',
    'source-file': 'https://challenges.cloudflare.com/turnstile/v0/api.js',
    'line-number': 1,
    sample: '\n      (function(){\n        // Must matc',
  },
});

describe('the report-only CSP', () => {
  // Every answer the policy exists to produce, as assertions rather than as
  // prose in a comment that drifts.
  it('is report-only, and there is no enforcing policy anywhere', () => {
    expect(SECURITY_HEADERS).not.toHaveProperty('Content-Security-Policy');
    expect(POLICY).toContain(`report-uri ${CSP_REPORT_PATH}`);
    expect(POLICY).not.toContain('Strict-Transport-Security');
  });

  it('allows exactly the origins the built site loads from', () => {
    expect(directive(POLICY, 'default-src')).toBe("default-src 'self'");
    expect(directive(POLICY, 'connect-src')).toBe("connect-src 'self' https://api.secretmsg.net");
    expect(directive(POLICY, 'font-src')).toBe("font-src 'self' https://fonts.gstatic.com");
    expect(directive(POLICY, 'frame-src')).toBe('frame-src https://challenges.cloudflare.com');
    expect(directive(POLICY, 'img-src')).toBe("img-src 'self'");
    expect(directive(POLICY, 'object-src')).toBe("object-src 'none'");
    expect(directive(POLICY, 'base-uri')).toBe("base-uri 'self'");
  });

  it('keeps script-src free of unsafe-inline and unsafe-eval', () => {
    // 'unsafe-inline' would swallow the very violations that answer (a), and
    // 'unsafe-eval' has to stay absent for (b) to be observable at all. If
    // either is added, the report data stops answering the question.
    const scriptSrc = directive(POLICY, 'script-src');

    expect(scriptSrc).toContain("'self'");
    expect(scriptSrc).toContain('https://challenges.cloudflare.com');
    expect(scriptSrc).toContain("'report-sample'");
    expect(scriptSrc).not.toContain("'unsafe-inline'");
    expect(scriptSrc).not.toContain("'unsafe-eval'");
    expect(scriptSrc).not.toContain("'strict-dynamic'");
    expect(scriptSrc).not.toContain("'nonce-");
  });

  it('pins the only in-page script in index.html and nothing else', () => {
    // The theme-flash IIFE is the sole in-page script the build ships, and it is
    // byte-identical on all 239 pages, so one hash covers the whole site. The
    // per-page JSON-LD blocks are data blocks, which HTML's "prepare the script
    // element" never passes to the CSP inline-check. If this test fails, the
    // digest in the policy is stale and the enforcing promotion would break
    // first paint.
    const [themeScript] = inlineScriptBodies(readFileSync(resolve(__dirname, '..', 'index.html'), 'utf8'));
    const digest = `sha256-${createHash('sha256').update(themeScript, 'utf8').digest('base64')}`;

    expect(themeScript).toContain('secretmsg_theme');
    expect(directive(POLICY, 'script-src')).toContain(`'${digest}'`);
    expect([...directive(POLICY, 'script-src').matchAll(/'sha256-[^']+'/g)]).toHaveLength(1);
  });

  it('admits the style block the Worker 404 page ships', () => {
    // notFoundHtml has a <style> block and the prerendered markup has style
    // attributes, so style-src needs 'unsafe-inline'. Recorded here so that it
    // is a known quantity rather than a surprise.
    expect(notFoundHtml).toContain('<style>');
    expect(directive(POLICY, 'style-src')).toBe("style-src 'self' https://fonts.googleapis.com 'unsafe-inline'");
  });
});

describe('the CSP report sink', () => {
  function captureLog(): { lines: unknown[][]; restore: () => void } {
    const spy = vi.spyOn(console, 'log').mockImplementation(() => {});
    return { lines: spy.mock.calls, restore: () => spy.mockRestore() };
  }

  function report(body: string, contentType = 'application/csp-report'): Request {
    return new Request(`https://secretmsg.net${CSP_REPORT_PATH}`, {
      method: 'POST',
      headers: { 'content-type': contentType },
      body,
    });
  }

  it('accepts a report the way a browser sends one', async () => {
    const log = captureLog();
    try {
      const env = environment();
      const response = await handleRequest(report(REPORT_BODY), env);

      expect(response.status).toBe(204);
      expect(await response.text()).toBe('');
      expect(response.headers.get('cache-control')).toBe('no-store');
      expectSecurityHeaders(response);
      expect(env.ASSETS.fetch).not.toHaveBeenCalled();

      expect(log.lines).toHaveLength(1);
      const [tag, payload] = log.lines[0] as [string, string];
      expect(tag).toBe('csp-report');
      expect(payload).toContain('https://secretmsg.net/p/privacy/');
      expect(payload).toContain('"blocked-uri":"eval"');
      expect(payload).toContain('Must matc');
    } finally {
      log.restore();
    }
  });

  it('never reflects the report back and never logs more than it reads', async () => {
    const log = captureLog();
    try {
      const oversized = JSON.stringify({ 'csp-report': { 'document-uri': 'https://secretmsg.net/', sample: 'x'.repeat(4000) } });
      const response = await handleRequest(report(oversized), environment());

      expect(response.status).toBe(204);
      expect(await response.text()).toBe('');
      const [, payload] = log.lines[0] as [string, string];
      expect(payload.length).toBeLessThan(oversized.length);
      expect(payload).not.toContain('x'.repeat(300));
    } finally {
      log.restore();
    }
  });

  it('takes the report-uri media type and nothing else', async () => {
    const log = captureLog();
    try {
      const response = await handleRequest(report(REPORT_BODY, 'application/csp-report; charset=utf-8'), environment());

      expect(response.status).toBe(204);
      expect(log.lines).toHaveLength(1);

      // report-to's application/reports+json is not accepted, because the
      // policy does not ask for it: a rejected report is visible in the browser
      // console, which is the right outcome for a sink that is not listening.
      const reports = await handleRequest(report(REPORT_BODY, 'application/reports+json'), environment());
      expect(reports.status).toBe(415);
      expect(log.lines).toHaveLength(1);
    } finally {
      log.restore();
    }
  });

  it('caps the body, so a report cannot be used to push data at us', async () => {
    const log = captureLog();
    try {
      const response = await handleRequest(report(JSON.stringify({ 'csp-report': { sample: 'x'.repeat(CSP_REPORT_MAX_BYTES) } })), environment());

      expect(response.status).toBe(413);
      expect(await response.text()).toBe('');
      expect(response.headers.get('cache-control')).toBe('no-store');
      expect(log.lines).toHaveLength(0);
    } finally {
      log.restore();
    }
  });

  it('is not a general-purpose write endpoint', async () => {
    const log = captureLog();
    try {
      const response = await handleRequest(report('not json at all', 'text/plain'), environment());

      expect(response.status).toBe(415);
      expect(await response.text()).toBe('');
      expect(log.lines).toHaveLength(0);
    } finally {
      log.restore();
    }
  });

  it('leaves every other path and method exactly as it was', async () => {
    const log = captureLog();
    try {
      const elsewhere = await handleRequest(new Request('https://secretmsg.net/reply/abc123', { method: 'POST' }), environment());
      expect(elsewhere.status).toBe(404);

      // A report-shaped POST to any other path is still the 404 it always was:
      // the sink is one path, not a write endpoint.
      const otherPath = new Request('https://secretmsg.net/janasco', {
        method: 'POST',
        headers: { 'content-type': 'application/csp-report' },
        body: REPORT_BODY,
      });
      expect((await handleRequest(otherPath, environment())).status).toBe(404);

      // GET on the report path is still routing, not a sink, so no board URL is
      // reserved by the endpoint.
      const env = environment();
      const page = await handleRequest(new Request(`https://secretmsg.net${CSP_REPORT_PATH}`), env);
      expect(page.status).toBe(200);
      expect(await page.text()).toContain('<title>SPA</title>');
      expect(log.lines).toHaveLength(0);
    } finally {
      log.restore();
    }
  });
});
