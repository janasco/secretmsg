import { describe, it, expect } from 'vitest';
import {
  BOX_FONTS,
  BOX_PATTERNS,
  DEFAULT_BOX_THEME,
  boxFontStack,
  boxThemeVars,
  normalizeBoxTheme,
  patternClass,
  safeHex,
} from './box-theme';
import { REACTION_EMOJI, decodeReactionPayload, sealReactionPayload } from './box-api';

describe('box theme clamping', () => {
  it('accepts the platform default untouched', () => {
    expect(normalizeBoxTheme(DEFAULT_BOX_THEME)).toEqual(DEFAULT_BOX_THEME);
  });

  it('rejects non-hex colors and URLs, falling back to the default', () => {
    const theme = normalizeBoxTheme({
      mode: 'custom',
      background_dark: 'url(https://evil.example/font.woff2)',
      accent_dark: 'javascript:alert(1)',
      pattern: 'aurora;background:url(x)',
      font: 'comic-sans',
    });
    expect(theme.background_dark).toBe(DEFAULT_BOX_THEME.background_dark);
    expect(theme.accent_dark).toBe(DEFAULT_BOX_THEME.accent_dark);
    expect(theme.pattern).toBe('none');
    expect(theme.font).toBe('inter');
  });

  it('safeHex only passes 6-digit hex', () => {
    expect(safeHex('#AABBCC', '#000000')).toBe('#aabbcc');
    expect(safeHex('#abc', '#000000')).toBe('#000000');
    expect(safeHex('  #123456  ', '#000000')).toBe('#123456');
    expect(safeHex(123456, '#000000')).toBe('#000000');
  });

  it('maps allowlisted fonts to family stacks with no URLs', () => {
    for (const font of BOX_FONTS) {
      const stack = boxFontStack(font);
      expect(stack.length).toBeGreaterThan(0);
      expect(stack).not.toMatch(/url|https?:|@font-face/i);
    }
  });

  it('patternClass only ever returns an allowlisted class or empty', () => {
    for (const pattern of BOX_PATTERNS) {
      const cls = patternClass(pattern);
      if (pattern === 'none') expect(cls).toBe('');
      else expect(cls).toBe(`box-pattern-${pattern}`);
    }
  });

  it('theme vars are validated hex values only', () => {
    const vars = boxThemeVars(
      { ...DEFAULT_BOX_THEME, mode: 'custom', background_dark: '#112233', accent_dark: '#445566' },
      'dark',
    ) as Record<string, string>;
    expect(vars['--box-bg']).toBe('#112233');
    expect(vars['--box-accent']).toBe('#445566');
  });
});

describe('reaction payloads', () => {
  it('seals and opens only allowlisted emoji ids', () => {
    for (const emoji of REACTION_EMOJI) {
      expect(decodeReactionPayload(sealReactionPayload(emoji.id))).toBe(emoji.id);
    }
  });

  it('degrades unknown payloads to nothing (neutral placeholder)', () => {
    expect(decodeReactionPayload(btoa(JSON.stringify({ v: 1, e: 'thumbsdown' })))).toBeNull();
    expect(decodeReactionPayload(btoa('<img src=x onerror=alert(1)>'))).toBeNull();
    expect(decodeReactionPayload('not-base64!!')).toBeNull();
    expect(decodeReactionPayload(btoa(JSON.stringify({ v: 2, e: 'heart' })))).toBeNull();
  });

  it('inventory is the fixed six with no negative glyph', () => {
    expect(REACTION_EMOJI.map((e) => e.id)).toEqual(['heart', 'laugh', 'wow', 'sad', 'clap', 'fire']);
    expect(REACTION_EMOJI.map((e) => e.glyph).join('')).not.toContain('👎');
  });
});
