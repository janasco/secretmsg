import { describe, expect, it, vi } from 'vitest';
import { isAssetRequest, isClientRoute, legacyRedirect } from './route-policy';
import { handleRequest, type WorkerEnv } from './worker';

function environment(): WorkerEnv {
  return {
    ASSETS: {
      fetch: vi.fn(async () => new Response('<!doctype html><title>SPA</title>', {
        status: 200,
        headers: { 'content-type': 'text/html' },
      })),
    },
  };
}

function expectSecurityHeaders(response: Response): void {
  expect(response.headers.get('x-content-type-options')).toBe('nosniff');
  expect(response.headers.get('x-frame-options')).toBe('DENY');
  expect(response.headers.get('referrer-policy')).toBe('strict-origin-when-cross-origin');
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
    const staticRoutes = [
      '/', '/about', '/faq', '/contact', '/download', '/supporters', '/demo', '/dice',
      '/sticker-studio', '/login', '/delete-account', '/blog', '/p/safety',
      '/p/child-safety-policy', '/p/approach-to-safety', '/p/guide-to-online-safety',
      '/p/community-guidelines', '/p/safety-tools', '/p/resources', '/p/contact-us',
      '/p/terms', '/p/privacy', '/p/cookies', '/p/disclaimer', '/inbox', '/settings',
    ];

    for (const route of staticRoutes) expect(isClientRoute(route)).toBe(true);
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
    ];

    for (const path of malformedPaths) {
      const env = environment();
      const response = await handleRequest(new Request(`https://secretmsg.net${path}`), env);
      expect(response.status).toBe(404);
      expect(env.ASSETS.fetch).not.toHaveBeenCalled();
    }
  });

  it('serves the SPA shell for dynamic client routes', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/post/scheduled-slug'), env);

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('text/html');
    expectSecurityHeaders(response);
    expect(await response.text()).toContain('<title>SPA</title>');
  });

  it('serves extension-like values below client-route prefixes but not bare asset paths', async () => {
    for (const path of ['/legal/terms.js', '/post/scheduled-slug.js']) {
      const env = environment();
      const response = await handleRequest(new Request(`https://secretmsg.net${path}`), env);
      expect(response.status).toBe(200);
      expect(env.ASSETS.fetch).toHaveBeenCalledOnce();
    }
  });

  it('preserves HEAD when fetching the SPA shell', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/reply/abc123', { method: 'HEAD' }), env);
    const fetchMock = env.ASSETS.fetch as ReturnType<typeof vi.fn>;
    const shellRequest = fetchMock.mock.calls[0][0] as Request;

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
