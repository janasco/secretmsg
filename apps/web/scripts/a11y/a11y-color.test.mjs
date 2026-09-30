/**
 * Acceptance tests for the a11y-colour tool.
 *
 * The headline test is the one that matters: a synthetic TSX snippet carrying
 * `text-amber-200/90` must be reported as a remap bypass. That is the exact
 * defect that shipped to production in ViewOnlyBanner (measured 1.10:1 in light
 * mode, 11.50:1 in dark) and it was invisible to a repo-wide grep for
 * `text-amber-200` because the shipped class was `text-amber-200/90`.
 *
 * The real line in ViewOnlyBanner.tsx is already fixed, so the regression is
 * reproduced here against the real `src/index.css` remap table rather than by
 * reintroducing the bug. That is deliberate: a test that only passes while a
 * known-bad class is present in the tree is not a test.
 */

import { describe, expect, it } from 'vitest';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { analyseContrast, analyseUsages, pageBackground } from './analyze.mjs';
import { TAILWIND_PALETTE } from './palette.generated.mjs';
import { parseComponentRules, parseCssVars, parseRemapTable, varsForState } from './remap.mjs';
import { buildElementModel, findColourUtilities } from './scan.mjs';
import { classifyClass } from './classes.mjs';
import { composite, contrastRatio, parseColor, parseRgbFunction, toHex } from './color.mjs';

const WEB_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');
const CSS = readFileSync(join(WEB_ROOT, 'src/index.css'), 'utf8');
const HTML = readFileSync(join(WEB_ROOT, 'index.html'), 'utf8');

/** The project's real remap table, built the same way the CLI builds it. */
const STATES = [...new Set([...HTML.matchAll(/classList\.toggle\(\s*["'`]([a-zA-Z-]+)["'`]/g)].map((m) => m[1]))];
const TABLE = parseRemapTable(CSS, STATES);
const VARS = parseCssVars(CSS);
const CTX = {
  webRoot: WEB_ROOT,
  css: CSS,
  html: HTML,
  states: STATES,
  table: TABLE,
  components: parseComponentRules(CSS),
  palette: { ...TAILWIND_PALETTE, dark: { 950: '#08090d', 900: '#0f1116', 850: '#161922', 800: '#1e222d', 700: '#2b3242' } },
  vars: {
    light: varsForState(VARS, 'light'),
    dark: varsForState(VARS, 'dark'),
  },
  bodyClasses: /<body[^>]*class="([^"]*)"/.exec(HTML)?.[1].split(/\s+/) ?? [],
  darkMode: 'class',
};

/** Run the two usage checks over a synthetic file, exactly as the CLI does. */
function scan(source, file = 'src/Synthetic.tsx') {
  return analyseUsages(findColourUtilities(source, CTX.palette, file), CTX);
}

describe('acceptance: the defect that shipped', () => {
  it('reports text-amber-200/90 as a remap bypass, with file:line', () => {
    const source = `
      export const Banner: React.FC = () => (
        <div className="bg-amber-500/10 border-b border-amber-500/20">
          <div className="text-[11px] sm:text-xs text-amber-200/90">View-only.</div>
        </div>
      );
    `;
    const { bypasses } = scan(source);

    expect(bypasses).toHaveLength(1);
    const [finding] = bypasses;
    expect(finding.token).toBe('text-amber-200/90');
    expect(finding.base).toBe('text-amber-200');
    expect(finding.file).toBe('src/Synthetic.tsx');
    expect(finding.line).toBe(4);
    expect(finding.rule).toBe('remap-bypass');
    // The point of the finding: the base class *is* remapped, which is why a
    // grep for `text-amber-200` finds the table entry and stops there.
    expect(TABLE.byToken.has('text-amber-200')).toBe(true);
    expect(finding.remapLine).toBeGreaterThan(0);
  });

  it('does not flag the plain remapped class it bypassed', () => {
    const { bypasses } = scan(`
      export const Ok: React.FC = () => <p className="text-amber-200">Fine.</p>;
    `);
    expect(bypasses).toEqual([]);
  });

  it('measures the bypass at roughly the contrast the bug actually had', () => {
    // Reproduce the shipped geometry: an amber-tinted band on the page, and the
    // opacity-modified text class on top of it. The reported light-mode number
    // should be in the same catastrophic band as the 1.10:1 that was shipped.
    const source = `
      export const Banner: React.FC = () => (
        <div className="bg-amber-500/10">
          <div className="text-amber-200/90">View-only.</div>
        </div>
      );
    `;
    const model = buildElementModel(source);
    model.nodes.forEach((n) => { n.file = 'src/Synthetic.tsx'; });
    const { results } = analyseContrast(model, CTX);
    const finding = results.find((r) => r.token === 'text-amber-200/90');
    expect(finding).toBeDefined();
    expect(finding.themes.light.pass).toBe(false);
    expect(finding.themes.light.ratio).toBeLessThan(2);
    expect(finding.themes.dark.pass).toBe(true);

    // Same snippet with the plain class: light mode is remapped and passes.
    const okModel = buildElementModel(`
      export const Banner: React.FC = () => (
        <div className="bg-amber-500/10">
          <div className="text-amber-200">View-only.</div>
        </div>
      );
    `);
    okModel.nodes.forEach((n) => { n.file = 'src/Synthetic.tsx'; });
    const okResults = analyseContrast(okModel, CTX).results
      .filter((r) => r.token === 'text-amber-200');
    // The remapped class is never a *bypass*. It may still miss AA marginally —
    // it did at #4.0:1 on the old canvas — in which case it appears in the
    // results and must be an order of magnitude better than the bypass. It may
    // also now clear AA entirely, in which case `analyseContrast` emits no
    // result for it at all (see analyze.mjs: results are only pushed when
    // something fails), and that is the better outcome. Both are acceptable;
    // what must never happen is the remap being bypassed.
    expect(okResults.every((r) => !r.themes.light.unresolved)).toBe(true);
    const bypassLight = finding.themes.light.ratio;
    const okLight = okResults[0]?.themes.light.ratio;
    if (okLight !== undefined) {
      expect(okLight).toBeGreaterThan(bypassLight * 2);
      expect(okLight).toBeGreaterThanOrEqual(3.5);
    }
  });
});

describe('remap-bypass detection', () => {
  it('flags an opacity-modified background whose base is remapped', () => {
    // The table remaps bg-dark-900 at /90 /80 /70 /60 /50. /40 is absent.
    const { bypasses } = scan('<div className="bg-dark-900/40" />');
    expect(bypasses.map((b) => b.token)).toEqual(['bg-dark-900/40']);
    expect(bypasses[0].base).toBe('bg-dark-900');
  });

  it('does not flag a background alpha the table does list', () => {
    const { bypasses } = scan('<div className="bg-dark-900/70" />');
    expect(bypasses).toEqual([]);
  });

  it('reports an unlisted alpha as a sibling gap when there is no base rule', () => {
    // `bg-white` itself is never remapped, only specific alphas of it, so
    // bg-white/[0.04] has nothing to opt out of - it is an unlisted neighbour.
    const { bypasses, siblingGaps } = scan('<div className="bg-white/[0.04]" />');
    expect(bypasses).toEqual([]);
    expect(siblingGaps.map((g) => g.token)).toEqual(['bg-white/[0.04]']);
    expect(siblingGaps[0].siblings).toContain('bg-white/5');
  });

  it('does not flag an arbitrary alpha the remap table does cover', () => {
    // index.css:156 lists `.light .bg-white\/\[0\.02\]` explicitly.
    const { bypasses } = scan('<div className="bg-white/[0.02]" />');
    expect(bypasses).toEqual([]);
  });

  it('does not flag a class whose base has no remap at all', () => {
    // Nothing to bypass: there is no rule for `text-sky-400` to opt out of.
    const { bypasses } = scan('<p className="text-sky-400/80" />');
    expect(bypasses).toEqual([]);
  });

  it('does not flag a dark:-gated class, which cannot render in light mode', () => {
    const { bypasses } = scan('<p className="text-amber-800 dark:text-amber-200/90" />');
    expect(bypasses).toEqual([]);
  });

  it('flags the dark:-gated form only when it is the sole colour', () => {
    // Still not a bypass: the light mode colour is simply absent, which is a
    // different (and separately reported) problem.
    const { bypasses } = scan('<p className="dark:text-amber-200/90" />');
    expect(bypasses).toEqual([]);
  });

  it('handles a variant-prefixed remap', () => {
    // index.css:213 remaps `.light .hover\:text-amber-200:hover`.
    const { bypasses } = scan('<a className="hover:text-amber-200/70" />');
    expect(bypasses.map((b) => b.base)).toEqual(['hover:text-amber-200']);
  });

  it('ignores arbitrary values that are sizes, not colours', () => {
    const { bypasses } = scan('<p className="text-[11px] leading-[1.4] w-[3px] bg-[#0f111a]" />');
    // `text-[11px]` and `leading-[1.4]` are not colour utilities at all. The
    // arbitrary hex background is a colour but has no remap to bypass.
    expect(bypasses).toEqual([]);
  });

  it('ignores prose comments, which Tailwind also scans as raw text', () => {
    const { bypasses } = scan([
      '// Historically this used text-amber-200/90, which bypassed the remap.',
      'export const A = () => <p className="text-amber-200" />;',
    ].join('\n'));
    expect(bypasses).toEqual([]);
  });
});

describe('colour utility classification', () => {
  const c = (token) => classifyClass(token, CTX.palette);

  it('separates opacity-modifier from arbitrary-value forms', () => {
    expect(c('text-amber-200/90')).toMatchObject({ family: 'amber', shade: '200', opacity: 0.9, modifier: '90' });
    expect(c('bg-slate-900/[0.02]')).toMatchObject({ family: 'slate', opacity: 0.02, modifier: '[0.02]' });
    expect(c('text-[11px]')).toBeNull();
    expect(c('bg-[#0f111a]')).toMatchObject({ arbitrary: '#0f111a', isSurface: true });
    expect(c('w-[3px]')).toBeNull();
  });

  it('rejects utilities that only look like colour utilities', () => {
    for (const token of ['border-b-2', 'bg-gradient-to-r', 'from-indigo-500', 'rounded-xl', 'p-4', 'shadow-lg']) {
      const info = c(token);
      // Gradient stops ARE colour utilities; nothing else in this list is.
      if (token.startsWith('from-')) expect(info?.family).toBe('indigo');
      else expect(info).toBeNull();
    }
  });

  it('resolves the custom palette the project extends', () => {
    expect(c('bg-dark-950')).toMatchObject({ family: 'dark', shade: '950', hex: '#08090d' });
  });
});

describe('colour maths', () => {
  it('parses hex, short hex, alpha hex and modern rgb syntax', () => {
    expect(parseColor('#fff')).toMatchObject({ r: 255, g: 255, b: 255, a: 1 });
    expect(parseColor('#f59e0b')).toMatchObject({ r: 245, g: 158, b: 11 });
    expect(parseColor('#00000080').a).toBeCloseTo(0.502, 2);
    expect(parseRgbFunction('rgba(248, 250, 252, 0.85)')).toMatchObject({ r: 248, g: 250, b: 252, a: 0.85 });
    expect(parseRgbFunction('rgb(9 10 15 / 0.5)')).toMatchObject({ r: 9, g: 10, b: 15, a: 0.5 });
    expect(parseColor('not-a-colour')).toBeNull();
  });

  it('resolves var() through the theme variable map, and refuses otherwise', () => {
    expect(parseColor('var(--bg-main)', CTX.vars.light)).toMatchObject({ r: 251, g: 251, b: 253 });
    expect(parseColor('var(--bg-main)', CTX.vars.dark)).toMatchObject({ r: 8, g: 9, b: 13 });
    expect(parseColor('var(--nope)', CTX.vars.light)).toBeNull();
    expect(parseColor('var(--bg-main)')).toBeNull();
  });

  it('matches the WCAG 2.1 reference ratios', () => {
    const white = parseColor('#ffffff');
    const black = parseColor('#000000');
    expect(contrastRatio(white, black)).toBe(21);
    expect(contrastRatio(white, white)).toBe(1);
    // Canonical example pair from the WCAG text.
    expect(contrastRatio(parseColor('#777777'), white)).toBe(4.48);
  });

  it('composites alpha source-over, and refuses to guess without a backdrop', () => {
    const half = parseColor('rgba(0, 0, 0, 0.5)');
    expect(toHex(composite(half, parseColor('#ffffff')))).toBe('#808080');
    expect(composite(parseColor('rgba(0,0,0,0.5)'), null)).toBeNull();
  });
});

describe('contrast resolution against the real project', () => {
  it('derives the page background from <body> in index.html, per theme', () => {
    expect(toHex(pageBackground(CTX, 'light'))).toBe('#fbfbfd');
    expect(toHex(pageBackground(CTX, 'dark'))).toBe('#08090d');
  });

  it('reads both theme states out of the inline bootstrap script', () => {
    expect(STATES).toEqual(['dark', 'light']);
    expect(CTX.darkMode).toBe('class');
  });

  it('resolves the glass card surface, which is a component class not a utility', () => {
    expect(CTX.components.has('glass-panel')).toBe(true);
    const colour = parseColor(CTX.components.get('glass-panel').props.background.value, CTX.vars.light);
    expect(colour).toMatchObject({ r: 255, g: 255, b: 255, a: 0.85 });
  });

  it('measures a text run on a glass card in both themes', () => {
    const model = buildElementModel(`
      export const Card: React.FC = () => (
        <div className="glass-panel p-5">
          <p className="text-sm text-slate-300">Body copy.</p>
        </div>
      );
    `);
    model.nodes.forEach((n) => { n.file = 'src/Synthetic.tsx'; });
    const { results, unresolved } = analyseContrast(model, CTX);
    // text-slate-300 is remapped in light mode and fine in both, so nothing is
    // reported - the important part is that it resolved at all.
    expect(unresolved).toEqual([]);
    const failing = results.filter((r) => r.token === 'text-slate-300' && r.themes.light.pass === false);
    expect(failing).toEqual([]);
  });

  it('finds a genuine light-mode failure: an unremapped light text colour', () => {
    // index.css remaps .text-rose-300 and .text-rose-400 but not
    // .text-rose-200, so a rose-200 alert is legible on dark paper and
    // invisible on light paper. Same shape as the shipped defect.
    const model = buildElementModel(`
      export const Alert: React.FC = () => (
        <div className="glass-panel p-6">
          <div className="bg-rose-500/10 border border-rose-500/30 text-xs text-rose-200">Failed</div>
        </div>
      );
    `);
    model.nodes.forEach((n) => { n.file = 'src/Synthetic.tsx'; });
    const { results } = analyseContrast(model, CTX);
    const finding = results.find((r) => r.token === 'text-rose-200');
    expect(finding).toBeDefined();
    expect(finding.themes.light.pass).toBe(false);
    expect(finding.themes.dark.pass).toBe(true);
  });
});

describe('unremapped surface detection', () => {
  it('reports a neutral surface with no remap as a defect', () => {
    const { unremapped } = scan('<div className="bg-white" />');
    const finding = unremapped.find((f) => f.token === 'bg-white');
    expect(finding.verdict).toBe('defect');
  });

  it('does not report a neutral surface the remap table does cover', () => {
    const { unremapped } = scan('<div className="bg-dark-900/60 border-white/10" />');
    expect(unremapped.map((f) => f.token)).not.toContain('bg-dark-900/60');
  });

  it('treats a hue surface and a gradient stop as by-design inventory, not findings', () => {
    // index.css states coloured surfaces are deliberately not remapped, so these
    // are counted and reported but must not be able to fail the gate.
    const { unremapped, byDesign } = scan('<div className="bg-indigo-500/10 bg-gradient-to-r from-indigo-500 to-purple-700" />');
    expect(unremapped).toEqual([]);
    expect(byDesign.length).toBeGreaterThan(0);
    for (const finding of byDesign) {
      expect(finding.verdict).toBe('by-design');
      expect(finding.reason).toBeTruthy();
    }
  });

  it('records a reason with every judgement, by-design included', () => {
    // A verdict with no written reason is indistinguishable from a bug in the
    // tool, so the report always carries the argument.
    const { unremapped, byDesign } = scan('<div className="bg-black/80 border-white bg-white hover:bg-slate-100" />');
    expect(unremapped.map((f) => f.token)).toEqual(['bg-white']);
    expect(byDesign.map((f) => f.token).sort()).toEqual(['bg-black/80', 'border-white', 'hover:bg-slate-100']);
    for (const finding of [...unremapped, ...byDesign]) expect(finding.reason).toBeTruthy();
    expect(unremapped[0].verdict).toBe('defect');
    expect(byDesign.find((f) => f.token === 'bg-black/80').verdict).toBe('by-design');
  });
});

describe('the real repository is not silently broken by this tool', () => {
  const real = scan(readFileSync(join(WEB_ROOT, 'src/components/ViewOnlyBanner.tsx'), 'utf8'),
    'src/components/ViewOnlyBanner.tsx');

  it('reports no remap bypass in the already-fixed ViewOnlyBanner', () => {
    expect(real.bypasses).toEqual([]);
  });

  it('reports no remap bypass anywhere in src/', async () => {
    // The whole point of the gate. If this fails, a component has opted out of
    // the light-mode remap the way ViewOnlyBanner did, and the tree carries the
    // same defect class that shipped.
    const { listSourceFiles } = await import('./project.mjs');
    const { readFileSync: read } = await import('node:fs');
    const offenders = [];
    for (const file of listSourceFiles(join(WEB_ROOT, 'src'))) {
      const rel = file.slice(WEB_ROOT.length + 1);
      const { bypasses: found } = scan(read(file, 'utf8'), rel);
      for (const b of found) offenders.push(`${rel}:${b.line} ${b.token}`);
    }
    expect(offenders).toEqual([]);
  });
});
