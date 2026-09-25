import { describe, expect, it } from 'vitest';
import { isAssetRequest, legacyRedirect } from './route-policy';

type SiteManifest = {
  HOST: string;
  STATIC_ROUTES: Array<{ path: string }>;
  canonicalUrl: (path: string) => string;
};

type GlobImportMeta = ImportMeta & {
  glob: (pattern: string, options: { eager: boolean }) => Record<string, SiteManifest>;
};

const manifestModules = (import.meta as GlobImportMeta).glob(
  '../scripts/site-manifest.mjs',
  { eager: true },
);
const manifest = manifestModules['../scripts/site-manifest.mjs'] as SiteManifest;

describe('blog pipeline invariants', () => {
  it('keeps route manifest paths unique', () => {
    const paths = manifest.STATIC_ROUTES.map((route) => route.path);

    expect(new Set(paths).size).toBe(paths.length);
  });

  it('canonicalizes the root and every other path with one trailing slash', () => {
    expect(manifest.canonicalUrl('/')).toBe(manifest.HOST);
    expect(manifest.canonicalUrl('/about')).toBe(`${manifest.HOST}/about/`);
    expect(manifest.canonicalUrl('/about/')).toBe(`${manifest.HOST}/about/`);
  });

  it('maps only supported legacy aliases to canonical paths', () => {
    expect(legacyRedirect('/donors')).toBe('/supporters/');
    expect(legacyRedirect('/donors/')).toBe('/supporters/');
    expect(legacyRedirect('/p/legal/privacy')).toBe('/p/privacy/');
    expect(legacyRedirect('/p/legal/privacy/')).toBe('/p/privacy/');
    expect(legacyRedirect('/legal/terms')).toBe('/p/terms/');
    expect(legacyRedirect('/legal/terms/')).toBe('/p/terms/');
    expect(legacyRedirect('/p/privacy/')).toBeNull();
    expect(legacyRedirect('/legal/unknown')).toBeNull();
  });

  it('classifies missing asset extensions without classifying real routes', () => {
    expect(isAssetRequest('/downloads/missing.apk')).toBe(true);
    expect(isAssetRequest('/images/missing.png')).toBe(true);
    expect(isAssetRequest('/scripts/missing.js')).toBe(true);
    expect(isAssetRequest('/about/')).toBe(false);
  });
});
