/**
 * Sticker Studio — design catalogue.
 *
 * Thirty-two designs. Every one pairs a *different typeface* with a different
 * composition archetype and a surface treatment, because the studio this
 * replaces varied only its background gradient: all seven of its themes shared
 * one layout and one type treatment, so switching theme changed almost nothing.
 *
 * Fonts are declared as data rather than as a stylesheet link so that only the
 * font the visitor actually picks is fetched. Loading all thirty-two up front
 * would put a couple of megabytes of woff2 in front of every visitor to a
 * prerendered page for artwork most of them never render.
 *
 * Note for editors: this file lives under src/ and Tailwind's content glob
 * scans it as raw text, so avoid writing bare Tailwind utility words (block,
 * inline, flex, grid, hidden, container, table, isolate, contents) in
 * identifiers or comments. A stray one emits a rule nothing uses and rehashes
 * the stylesheet. "region", "stack", "band" and "plate" say the same thing.
 */

export interface FontSpec {
  /** CSS family name, exactly as Google Fonts serves it. */
  family: string;
  weight: number;
  /** Slightly looser tracking suits wide faces, tighter suits condensed ones. */
  tracking?: number;
}

export interface Palette {
  /** Ordered top-to-bottom. Two entries means a flat fill. */
  bg: string[];
  /** Ink for the headline. */
  ink: string;
  /** Secondary ink for the board name and handle. */
  ink2: string;
  /** Accent for rules, chips and decoration. */
  accent: string;
  /** Ink used *on* accent fills. */
  onAccent: string;
  /** True when the canvas is light and light-mode rules should apply. */
  light?: boolean;
}

/**
 * Composition archetypes. These decide where the content sits vertically and
 * how it is framed; the renderer supplies the drawing.
 */
export type Archetype =
  | 'stack'
  | 'framed'
  | 'medallion'
  | 'banded'
  | 'plate'
  | 'poster'
  | 'terminal'
  | 'badge';

/** Surface treatments applied under and over the content. */
export type Decor = 'grain' | 'blobs' | 'grid' | 'scan' | 'shadow' | 'duotone' | 'chrome' | 'arch';

export interface StickerStyle {
  id: string;
  name: string;
  /** Shown in the UI so the choice is legible without rendering all 32. */
  vibe: string;
  font: FontSpec;
  palette: Palette;
  archetype: Archetype;
  decor: Decor;
}

export const ARCHETYPE_LABEL: Record<Archetype, string> = {
  stack: 'Centred stack',
  framed: 'Ruled frame',
  medallion: 'Medallion',
  banded: 'Banded',
  plate: 'Sticker plate',
  poster: 'Full poster',
  terminal: 'Terminal panel',
  badge: 'Badge',
};

export const DECOR_LABEL: Record<Decor, string> = {
  grain: 'Grain',
  blobs: 'Organic blobs',
  grid: 'Grid paper',
  scan: 'Scanlines',
  shadow: 'Hard shadow',
  duotone: 'Duotone ink',
  chrome: 'Chrome',
  arch: 'Arch shapes',
};

/* ------------------------------------------------------------------ fonts */

const F = (family: string, weight: number, tracking = 0): FontSpec => ({ family, weight, tracking });

/* ---------------------------------------------------------------- palettes */

const P = (
  id: string,
  bg: string[],
  ink: string,
  ink2: string,
  accent: string,
  onAccent: string,
  light = false,
): Palette & { id: string } => ({ id, bg, ink, ink2, accent, onAccent, light });

const PALETTES = {
  obsidian: P('obsidian', ['#0B0D12', '#151A24'], '#F7F8FA', '#98A2B3', '#8B7CFF', '#0A0B0F'),
  paper: P('paper', ['#F3EFE6'], '#16130E', '#6B6154', '#C0392B', '#FFFFFF', true),
  acid: P('acid', ['#FFE24A', '#FFD21E'], '#14120E', '#5C5240', '#14120E', '#FFE24A'),
  orchid: P('orchid', ['#6D28D9', '#A21CAF'], '#FFFFFF', '#E9D5FF', '#F0ABFC', '#2A0B45'),
  cobalt: P('cobalt', ['#0B2A6B', '#123C8F'], '#FFFFFF', '#BFDBFE', '#93C5FD', '#06183C'),
  forest: P('forest', ['#052E22', '#0A4634'], '#F0FDF4', '#A7F3D0', '#6EE7B7', '#03211A'),
  ember: P('ember', ['#7A1D0C', '#B4340F'], '#FFF7ED', '#FED7AA', '#FDBA74', '#3B0A04'),
  blush: P('blush', ['#FCE7F3', '#FBCFE8'], '#500724', '#9D174D', '#DB2777', '#FFFFFF', true),
  mono: P('mono', ['#0A0A0A'], '#FAFAFA', '#A1A1AA', '#22C55E', '#052E16'),
  sand: P('sand', ['#E7DCC8', '#D6C4A4'], '#2B2118', '#6F5C46', '#A16207', '#FFFBEB', true),
  arctic: P('arctic', ['#E0F2FE', '#BAE6FD'], '#0C4A6E', '#075985', '#0284C7', '#FFFFFF', true),
  lime: P('lime', ['#14532D', '#166534'], '#ECFDF5', '#A7F3D0', '#BEF264', '#052E16'),
  violetInk: P('violetInk', ['#1E1B4B', '#312E81'], '#EEF2FF', '#C7D2FE', '#A5B4FC', '#1E1B4B'),
  noir: P('noir', ['#111111', '#1C1C1C'], '#FFFFFF', '#8A8A8A', '#D4AF37', '#111111'),
  bubble: P('bubble', ['#FFE0EC', '#FFD1E0'], '#5B1030', '#9D174D', '#EC4899', '#FFFFFF', true),
  steel: P('steel', ['#1F2937', '#374151'], '#F9FAFB', '#D1D5DB', '#93C5FD', '#111827'),
  blood: P('blood', ['#2B0A0A', '#4A0F0F'], '#FEF2F2', '#FCA5A5', '#F87171', '#2B0A0A'),
  mint: P('mint', ['#ECFDF5', '#D1FAE5'], '#064E3B', '#047857', '#059669', '#FFFFFF', true),
  plum: P('plum', ['#3B0764', '#581C87'], '#FAF5FF', '#E9D5FF', '#D8B4FE', '#2A0B45'),
  citrus: P('citrus', ['#FFFBEB', '#FEF3C7'], '#78350F', '#92400E', '#EA580C', '#FFFFFF', true),
  slate: P('slate', ['#0F172A', '#1E293B'], '#F8FAFC', '#94A3B8', '#38BDF8', '#0F172A'),
  teal: P('teal', ['#042F2E', '#0F4C47'], '#F0FDFA', '#99F6E4', '#2DD4BF', '#042F2E'),
  cream: P('cream', ['#FFFDF8', '#F5EFE3'], '#1A1710', '#6B6154', '#D97706', '#FFFBEB', true),
  ink: P('ink', ['#111111'], '#FFFFFF', '#9CA3AF', '#F43F5E', '#111111'),
  denim: P('denim', ['#1E3A8A', '#1D4ED8'], '#EFF6FF', '#BFDBFE', '#FDE68A', '#172554'),
  grape: P('grape', ['#2E1065', '#4C1D95'], '#F5F3FF', '#DDD6FE', '#F472B6', '#1E0B3C'),
  coral: P('coral', ['#FFEDD5', '#FED7AA'], '#7C2D12', '#9A3412', '#EA580C', '#FFFFFF', true),
  moss: P('moss', ['#1A2E05', '#365314'], '#F7FEE7', '#D9F99D', '#A3E635', '#1A2E05'),
  pearl: P('pearl', ['#FAFAFA', '#F1F5F9'], '#111827', '#6B7280', '#111827', '#FAFAFA', true),
  rouge: P('rouge', ['#450A0A', '#7F1D1D'], '#FEF2F2', '#FCA5A5', '#FB923C', '#450A0A'),
} as const;

type PaletteKey = keyof typeof PALETTES;

/* ----------------------------------------------------------------- styles */

/* Thirty-two combinations. Font is unique to each; archetype and decor vary so
   no two read as the same card in a different colour. */

type Spec = [id: string, name: string, vibe: string, font: FontSpec, pal: PaletteKey, arch: Archetype, decor: Decor];

const SPECS: Spec[] = [
  ['ink-report', 'Ink Report', 'editorial / broadsheet', F('Playfair Display', 800, -0.02), 'paper', 'framed', 'grain'],
  ['noir-gold', 'Noir & Gold', 'quiet luxury', F('Cormorant Garamond', 300, 0.02), 'noir', 'stack', 'arch'],
  ['bodoni-crest', 'Bodoni Crest', 'fashion / didone', F('Bodoni Moda', 700, -0.01), 'pearl', 'medallion', 'grain'],
  ['grotesk-slab', 'Grotesk Slab', 'swiss / neutral', F('Archivo', 600, -0.01), 'steel', 'banded', 'grid'],
  ['acid-slab', 'Acid Slab', 'neubrutalism', F('Archivo Black', 400, -0.02), 'acid', 'poster', 'grid'],
  ['orchid-tag', 'Orchid Tag', 'y2k / holographic', F('Bricolage Grotesque', 800, -0.02), 'orchid', 'plate', 'chrome'],
  ['mono-tty', 'TTY Prompt', 'raw / terminal', F('JetBrains Mono', 700, -0.01), 'mono', 'terminal', 'scan'],
  ['forest-sigil', 'Forest Sigil', 'organic / calm', F('Fraunces', 900, -0.02), 'forest', 'medallion', 'blobs'],
  ['ember-rally', 'Ember Rally', 'poster / loud', F('Anton', 400, -0.01), 'ember', 'poster', 'grain'],
  ['blush-bloom', 'Blush Bloom', 'soft / romantic', F('Sanchez', 700, 0), 'blush', 'medallion', 'blobs'],
  ['cobalt-navy', 'Cobalt Navy', 'sport / clean', F('Unbounded', 700, -0.03), 'cobalt', 'badge', 'grid'],
  ['sand-cafe', 'Sand Cafe', 'indie print', F('Caveat', 700, 0), 'sand', 'stack', 'grain'],
  ['arctic-frost', 'Arctic Frost', 'clean / cool', F('Figtree', 800, -0.02), 'arctic', 'badge', 'arch'],
  ['lime-press', 'Lime Press', 'zine / riso', F('Syne', 800, -0.03), 'lime', 'poster', 'duotone'],
  ['violet-hush', 'Violet Hush', 'ambient / deep', F('Outfit', 800, -0.02), 'violetInk', 'stack', 'blobs'],
  ['blood-oath', 'Blood Oath', 'dramatic / heavy', F('Bebas Neue', 400, 0.02), 'blood', 'poster', 'grain'],
  ['mint-slip', 'Mint Slip', 'receipt / paper', F('Familjen Grotesk', 700, -0.01), 'mint', 'terminal', 'grain'],
  ['grape-jam', 'Grape Jam', 'y2k / glossy', F('Anybody', 800, -0.02), 'grape', 'plate', 'chrome'],
  ['coral-sun', 'Coral Sun', 'warm / friendly', F('Baloo 2', 800, -0.01), 'coral', 'medallion', 'blobs'],
  ['steel-plate', 'Steel Plate', 'industrial', F('Chivo', 900, -0.02), 'steel', 'badge', 'grid'],
  ['pearl-quote', 'Pearl Quote', 'minimal / type', F('DM Serif Display', 400, -0.01), 'pearl', 'stack', 'grain'],
  ['rouge-alert', 'Rouge Alert', 'loud / urgent', F('Righteous', 400, 0), 'rouge', 'poster', 'duotone'],
  ['teal-current', 'Teal Current', 'fluid / fresh', F('Sora', 700, -0.02), 'teal', 'framed', 'arch'],
  ['cream-letter', 'Cream Letter', 'vintage / soft', F('Instrument Serif', 400, 0), 'cream', 'framed', 'grain'],
  ['moss-field', 'Moss Field', 'outdoor / calm', F('Khand', 700, 0.01), 'moss', 'stack', 'blobs'],
  ['denim-badge', 'Denim Badge', 'sport / bold', F('Lilita One', 400, 0), 'denim', 'badge', 'grid'],
  ['plum-velvet', 'Plum Velvet', 'luxe / deep', F('Marcellus', 400, 0.02), 'plum', 'medallion', 'arch'],
  ['citrus-pop', 'Citrus Pop', 'bright / playful', F('Fredoka', 600, -0.01), 'citrus', 'poster', 'blobs'],
  ['slate-grid', 'Slate Grid', 'system / neutral', F('Manrope', 800, -0.02), 'slate', 'terminal', 'grid'],
  ['ember-brut', 'Ember Brut', 'neubrutal / warm', F('Gabarito', 700, -0.01), 'ember', 'plate', 'shadow'],
  ['pearl-mini', 'Pearl Mini', 'cute / rounded', F('Quicksand', 700, -0.01), 'bubble', 'medallion', 'grain'],
  ['slab-marker', 'Slab Marker', 'hand / personal', F('Permanent Marker', 400, 0.01), 'acid', 'stack', 'shadow'],
];

export const STICKER_STYLES: StickerStyle[] = SPECS.map(
  ([id, name, vibe, font, pal, archetype, decor]) => ({
    id,
    name,
    vibe,
    font,
    palette: PALETTES[pal],
    archetype,
    decor,
  }),
);

export const styleById = (id: string): StickerStyle =>
  STICKER_STYLES.find((s) => s.id === id) ?? STICKER_STYLES[0];

/* ----------------------------------------------------------------- fonts */

/** Fetch one family from Google Fonts, once. Resolves even on failure so a
    missing font degrades to a fallback rather than blocking the artwork. */
const requested = new Set<string>();

export function ensureFont(font: FontSpec): Promise<void> {
  if (typeof document === 'undefined') return Promise.resolve();
  const key = `${font.family}:${font.weight}`;
  if (requested.has(key)) return Promise.resolve();
  requested.add(key);

  const href =
    'https://fonts.googleapis.com/css2?family=' +
    encodeURIComponent(font.family).replace(/%20/g, '+') +
    ':wght@' +
    font.weight +
    '&display=swap';

  return new Promise<void>((resolve) => {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = href;
    link.onload = () => resolve();
    link.onerror = () => resolve();
    document.head.appendChild(link);
  })
    .then(() =>
      document.fonts
        .load(`${font.weight} 64px "${font.family}"`)
        .catch(() => null),
    )
    .then(() => document.fonts.ready)
    .then(() => undefined);
}

/** Warm the neighbouring styles so arrowing through the list feels instant. */
export function ensureFonts(fonts: FontSpec[]): Promise<void> {
  return Promise.all(fonts.map(ensureFont)).then(() => undefined);
}
