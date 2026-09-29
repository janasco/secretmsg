/**
 * Colour parsing, alpha compositing and WCAG 2.1 contrast.
 *
 * No dependencies, deliberately. The maths here is short enough that auditing
 * it by reading is cheaper than auditing a dependency, and the gate has to
 * work on a machine with an empty npm cache.
 *
 * All colours are represented as { r, g, b, a } with r/g/b in 0..255 (integers
 * are not required) and a in 0..1.
 */

const NAMED = {
  transparent: { r: 0, g: 0, b: 0, a: 0 },
  white: { r: 255, g: 255, b: 255, a: 1 },
  black: { r: 0, g: 0, b: 0, a: 1 },
};

function clamp(n, lo, hi) {
  return n < lo ? lo : n > hi ? hi : n;
}

/** Parse a CSS hex colour, with or without a leading '#'. 3/4/6/8 digits. */
export function parseHex(input) {
  const s = String(input).trim().replace(/^#/, '');
  if (!/^[0-9a-fA-F]+$/.test(s)) return null;
  const expand = (c) => parseInt(c + c, 16);
  let r;
  let g;
  let b;
  let a = 1;
  if (s.length === 3 || s.length === 4) {
    r = expand(s[0]);
    g = expand(s[1]);
    b = expand(s[2]);
    if (s.length === 4) a = expand(s[3]) / 255;
  } else if (s.length === 6 || s.length === 8) {
    r = parseInt(s.slice(0, 2), 16);
    g = parseInt(s.slice(2, 4), 16);
    b = parseInt(s.slice(4, 6), 16);
    if (s.length === 8) a = parseInt(s.slice(6, 8), 16) / 255;
  } else {
    return null;
  }
  return { r, g, b, a };
}

/** Parse `rgb(...)` / `rgba(...)` in both legacy comma and modern space syntax. */
export function parseRgbFunction(input) {
  const m = /^(rgba?)\(\s*([^)]*)\)$/i.exec(String(input).trim());
  if (!m) return null;
  const parts = m[2].split('/');
  const chan = parts[0].trim();
  const alphaRaw = parts.length > 1 ? parts[1].trim() : null;
  let nums;
  if (chan.includes(',')) {
    nums = chan.split(',').map((p) => p.trim());
  } else {
    nums = chan.split(/\s+/).filter(Boolean);
  }
  if (nums.length < 3) return null;
  const comp = (tok) => {
    if (tok.endsWith('%')) return (parseFloat(tok) / 100) * 255;
    return parseFloat(tok);
  };
  const r = comp(nums[0]);
  const g = comp(nums[1]);
  const b = comp(nums[2]);
  if ([r, g, b].some((n) => Number.isNaN(n))) return null;
  let a = 1;
  const atok = alphaRaw ?? (nums.length > 3 ? nums[3] : null);
  if (atok != null) {
    a = atok.endsWith('%') ? parseFloat(atok) / 100 : parseFloat(atok);
    if (Number.isNaN(a)) return null;
  }
  return { r, g, b, a: clamp(a, 0, 1) };
}

/**
 * Parse any colour literal this codebase actually contains.
 *
 * `vars` resolves `var(--token)` against a theme-state variable map. Without a
 * match, `var()` returns null rather than a guess: an unresolved variable means
 * the static answer would be fiction, and the caller reports that honestly.
 */
export function parseColor(input, vars = null) {
  if (input == null) return null;
  const s = String(input).trim();
  if (s === '') return null;
  const lower = s.toLowerCase();
  if (lower in NAMED) return { ...NAMED[lower] };

  if (lower.startsWith('var(')) {
    const name = /^var\(\s*(--[\w-]+)/.exec(lower)?.[1];
    if (!name || !vars) return null;
    if (!(name in vars)) return null;
    return parseColor(vars[name], vars);
  }

  if (lower.startsWith('#')) return parseHex(s);
  if (/^rgba?\(/i.test(s)) return parseRgbFunction(s);
  return null;
}

/** Serialize back to a hex string, for compact reporting. Alpha is dropped. */
export function toHex(c) {
  if (!c) return '?';
  const h = (n) => clamp(Math.round(n), 0, 255).toString(16).padStart(2, '0');
  return `#${h(c.r)}${h(c.g)}${h(c.b)}`;
}

/** Flatten a translucent colour onto an opaque backdrop (simple source-over). */
export function composite(fg, bg) {
  if (!fg) return null;
  if (!bg) return fg.a >= 1 ? { ...fg } : null;
  if (fg.a >= 1) return { ...fg };
  const a = fg.a + bg.a * (1 - fg.a);
  if (a === 0) return { r: 0, g: 0, b: 0, a: 0 };
  const mix = (f, b) => (f * fg.a + b * bg.a * (1 - fg.a)) / a;
  return { r: mix(fg.r, bg.r), g: mix(fg.g, bg.g), b: mix(fg.b, bg.b), a };
}

/** WCAG 2.1 relative luminance. */
export function relativeLuminance(c) {
  if (!c) return null;
  const chan = (v) => {
    const s = v / 255;
    return s <= 0.03928 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  };
  return 0.2126 * chan(c.r) + 0.7152 * chan(c.g) + 0.0722 * chan(c.b);
}

/**
 * WCAG 2.1 contrast ratio, 1..21. Both arguments must be opaque; use
 * `composite` first. Ratios are rounded to 2dp because that is the precision
 * a decision can actually be made at - the WCAG definition of "large text"
 * and the 4.5/3.0 thresholds are far coarser than that.
 */
export function contrastRatio(a, b) {
  const la = relativeLuminance(a);
  const lb = relativeLuminance(b);
  if (la == null || lb == null) return null;
  const [hi, lo] = la >= lb ? [la, lb] : [lb, la];
  return Math.round(((hi + 0.05) / (lo + 0.05)) * 100) / 100;
}

/**
 * Required WCAG 1.4.3 ratio for a run of text.
 *
 * `fontSizePx` and `bold` follow the WCAG definition of large text: >= 24px, or
 * >= 18.66px when bold. The site's body font-size is 17px (index.css sets
 * 1.0625rem), so `text-xs` and below are small text here, not large text -
 * a distinction worth being explicit about, because it is the difference
 * between a 4.5 and a 3.0 threshold.
 */
export function requiredRatio(fontSizePx, bold = false) {
  const large = fontSizePx >= 24 || (bold && fontSizePx >= 18.66);
  return large ? 3 : 4.5;
}

export function meetsAA(ratio, required) {
  return ratio != null && ratio >= required;
}

/** Picks the lower-contrast of two candidate backdrops (gradients, islands). */
export function worstPairing(ratios) {
  const known = ratios.filter((r) => r != null);
  if (known.length === 0) return null;
  return known.reduce((a, b) => (a <= b ? a : b));
}
