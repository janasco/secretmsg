import { describe, expect, it, vi } from 'vitest';
import { isAssetRequest, legacyRedirect } from './route-policy';
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

describe('route policy', () => {
  it('identifies missing files without treating client routes as files', () => {
    expect(isAssetRequest('/downloads/secretmsg-android-v1.3.0-arm64.apk')).toBe(true);
    expect(isAssetRequest('/downloads/anything')).toBe(true);
    expect(isAssetRequest('/images/missing.PNG')).toBe(true);
    expect(isAssetRequest('/data/missing.json')).toBe(true);
    expect(isAssetRequest('/janasco')).toBe(false);
    expect(isAssetRequest('/reply/abc123')).toBe(false);
    expect(isAssetRequest('/post/scheduled-slug')).toBe(false);
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
    expect(await response.text()).toContain('404 - File not found');
    expect(env.ASSETS.fetch).not.toHaveBeenCalled();
  });

  it('serves the SPA shell for dynamic client routes', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/post/scheduled-slug'), env);

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('text/html');
    expect(await response.text()).toContain('<title>SPA</title>');
  });

  it('permanently redirects legacy aliases', async () => {
    const env = environment();
    const response = await handleRequest(new Request('https://secretmsg.net/donors'), env);

    expect(response.status).toBe(301);
    expect(response.headers.get('location')).toBe('/supporters/');
    expect(env.ASSETS.fetch).not.toHaveBeenCalled();
  });
});
