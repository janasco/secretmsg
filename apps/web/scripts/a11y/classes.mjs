/**
 * Tailwind class-token parsing.
 *
 * The only thing that matters here is being *right* about which tokens are
 * colour utilities, because a scanner that cries wolf gets switched off. The
 * design principle is: the palette is the authority. A token is a colour
 * utility if and only if its colour component resolves against the configured
 * palette (Tailwind defaults plus whatever `tailwind.config.js` extends).
 * That single rule is what keeps `text-[11px]`, `border-b-2`, `bg-gradient-to-r`
 * and `w-3.5` out of the report without a hand-maintained blacklist.
 */

/**
 * Prefixes that paint foreground (text/icon) colour. These are the tokens whose
 * theme blindness is a legibility defect rather than a cosmetic oddity.
 */
export const FOREGROUND_PREFIXES = ['text', 'fill', 'stroke', 'placeholder', 'decoration'];

/**
 * Prefixes that paint a surface: backgrounds, borders, rings, gradient stops.
 * Divider and outline prefixes paint a border; gradient stops paint a surface.
 */
export const SURFACE_PREFIXES = [
  'bg',
  'border',
  'border-x',
  'border-y',
  'border-t',
  'border-r',
  'border-b',
  'border-l',
  'border-s',
  'border-e',
  'divide',
  'divide-x',
  'divide-y',
  'outline',
  'ring',
  'ring-offset',
  'from',
  'via',
  'to',
];

/** Side/axis infixes that may sit between a surface prefix and the colour. */
const PREFIX_ALIASES = new Map([
  ['border-x', 'border'],
  ['border-y', 'border'],
  ['border-t', 'border'],
  ['border-r', 'border'],
  ['border-b', 'border'],
  ['border-l', 'border'],
  ['border-s', 'border'],
  ['border-e', 'border'],
  ['divide-x', 'divide'],
  ['divide-y', 'divide'],
]);

/**
 * Families that carry no hue. The site's light-mode remap system is built
 * entirely on remapping these, so an unremapped neutral surface is a defect
 * while an unremapped hue surface is usually a deliberate brand decision.
 */
export const NEUTRAL_FAMILIES = new Set([
  'slate',
  'gray',
  'zinc',
  'neutral',
  'stone',
  'white',
  'black',
]);

/** Split a token on `:` outside of `[...]`, so `[&:hover]:bg-x` stays intact. */
export function splitVariants(token) {
  const variants = [];
  let depth = 0;
  let current = '';
  for (const ch of token) {
    if (ch === '[') depth += 1;
    else if (ch === ']') depth -= 1;
    if (ch === ':' && depth === 0) {
      variants.push(current);
      current = '';
    } else {
      current += ch;
    }
  }
  variants.push(current);
  return { variants: variants.slice(0, -1), base: variants[variants.length - 1] };
}

/**
 * Separate an opacity modifier from a utility value. `bg-white/10` and
 * `bg-slate-900/[0.02]` are the same utility as `bg-white` / `bg-slate-900` with
 * a different alpha - which is the entire mechanism behind the defect this tool
 * exists for: they are *different class tokens*, so a CSS selector written
 * against the base token cannot match them.
 */
export function splitOpacity(value) {
  let depth = 0;
  for (let i = 0; i < value.length; i += 1) {
    const ch = value[i];
    if (ch === '[') depth += 1;
    else if (ch === ']') depth -= 1;
    else if (ch === '/' && depth === 0) {
      return { base: value.slice(0, i), modifier: value.slice(i + 1) };
    }
  }
  return { base: value, modifier: null };
}

/** Resolve an opacity modifier string to 0..1, or null if not interpretable. */
export function opacityValue(modifier) {
  if (modifier == null) return 1;
  if (/^\d{1,3}$/.test(modifier)) return Math.min(parseInt(modifier, 10), 100) / 100;
  const arbitrary = /^\[\s*([\d.]+)\s*\]$/.exec(modifier);
  if (arbitrary) {
    const n = parseFloat(arbitrary[1]);
    return Number.isNaN(n) ? null : n;
  }
  return null;
}

/** Resolve an arbitrary-value payload to an alpha, e.g. `[0.02]` -> 0.02. */
export function arbitraryToAlpha(content) {
  const n = parseFloat(content);
  return Number.isNaN(n) ? null : n;
}

function looksLikeArbitraryColour(content, palette) {
  if (/^#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(content)) return true;
  if (/^(rgb|rgba|hsl|hsla|hwb|lab|lch|oklab|oklch|color)\(/.test(content)) return true;
  if (content.startsWith('color:')) return true;
  const { base, modifier } = splitOpacity(content);
  return resolvePaletteEntry(base, palette) != null;
}

/** Look up `<family>` or `<family>-<shade>` against the palette. */
export function resolvePaletteEntry(base, palette) {
  if (!base) return null;
  if (typeof palette[base] === 'string') return { family: base, shade: null, hex: palette[base] };
  let best = null;
  for (let i = base.length - 1; i > 0; i -= 1) {
    if (base[i] !== '-') continue;
    const family = base.slice(0, i);
    const shade = base.slice(i + 1);
    const entry = palette[family];
    if (entry && typeof entry === 'object' && typeof entry[shade] === 'string') {
      if (!best || family.length > best.family.length) {
        best = { family, shade, hex: entry[shade] };
      }
    }
  }
  return best;
}

function stripImportant(token) {
  return token.endsWith('!') ? token.slice(0, -1) : token;
}

/**
 * Classify one raw class token.
 *
 * Returns null when the token is not a colour utility. Otherwise:
 *   { token, variants, prefix, family, shade, hex, modifier, opacity,
 *     arbitrary, isForeground, isSurface, isNeutral }
 */
/** All prefixes that can introduce a colour, longest first so `border-b` wins. */
const ALL_PREFIXES = [...SURFACE_PREFIXES, ...FOREGROUND_PREFIXES].sort((a, b) => b.length - a.length);

/** Split `<prefix>-<value>`; null when the token is not a colour-prefixed utility. */
function splitPrefix(base) {
  for (const prefix of ALL_PREFIXES) {
    if (base === prefix || base.startsWith(`${prefix}-`)) {
      return { prefix, value: base.slice(prefix.length + 1) };
    }
  }
  return null;
}

export function classifyClass(token, palette) {
  if (!token) return null;
  const cleaned = stripImportant(token.trim());
  if (cleaned === '') return null;

  const { variants, base } = splitVariants(cleaned);
  if (base === '') return null;

  const split = splitPrefix(base);
  if (!split) return null;
  const { prefix, value: rawValue } = split;
  const { base: value, modifier } = splitOpacity(rawValue);

  const isForeground = FOREGROUND_PREFIXES.includes(prefix);
  const isSurface = SURFACE_PREFIXES.includes(prefix);
  if (!isForeground && !isSurface) return null;

  // Arbitrary value: `text-[11px]` is a size, `bg-[#0f111a]` is a colour. The
  // distinction is made by the payload, never by the prefix.
  if (value.startsWith('[') && value.endsWith(']')) {
    const content = value.slice(1, -1);
    if (!looksLikeArbitraryColour(content, palette)) return null;
    const alphaFromModifier = modifier ? opacityValue(modifier) : null;
    const paletteEntry = resolvePaletteEntry(splitOpacity(content).base, palette);
    return {
      token: cleaned,
      variants,
      prefix,
      prefixGroup: prefix,
      arbitrary: content,
      family: paletteEntry?.family ?? null,
      shade: paletteEntry?.shade ?? null,
      hex: /^#/.test(content) ? content : paletteEntry?.hex ?? null,
      modifier,
      opacity: alphaFromModifier ?? arbitraryToAlpha(content) ?? 1,
      isForeground,
      isSurface,
      isNeutral: paletteEntry ? NEUTRAL_FAMILIES.has(paletteEntry.family) : false,
    };
  }

  const entry = resolvePaletteEntry(value, palette);
  if (!entry) return null;

  const alpha = modifier ? opacityValue(modifier) : null;
  return {
    token: cleaned,
    variants,
    prefix,
    family: entry.family,
    shade: entry.shade,
    hex: entry.hex,
    modifier,
    opacity: alpha ?? 1,
    arbitrary: null,
    isForeground,
    isSurface,
    isNeutral: NEUTRAL_FAMILIES.has(entry.family),
    prefixGroup: PREFIX_ALIASES.get(prefix) ?? prefix,
  };
}

/**
 * Which theme states can a token be active in?
 *
 * `dark:`-gated tokens cannot bypass a `.light`-scoped remap, because they are
 * not rendered in light mode at all. Getting this wrong produces a false
 * positive on every well-written dark-mode component, which is the fastest way
 * to make a linter get ignored.
 */
export function activeStates(variants) {
  if (variants.includes('dark') && !variants.includes('light')) return ['dark'];
  if (variants.includes('light') && !variants.includes('dark')) return ['light'];
  return ['light', 'dark'];
}

/**
 * The class token with any opacity modifier removed - i.e. the token a CSS
 * author would most likely have written the remap selector against.
 */
export function baseToken(info) {
  const { variants, base } = splitVariants(stripImportant(info.token));
  const { base: value } = splitOpacity(base);
  return [...variants, value].join(':');
}

/** The token family key: variants + prefix + colour, no opacity modifier. */
export function familyKey(info) {
  const { variants, base } = splitVariants(stripImportant(info.token));
  const { base: value } = splitOpacity(base);
  return [...variants, value].join(':');
}
