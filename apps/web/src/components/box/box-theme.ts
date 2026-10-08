/**
 * Public box page theming — client-side model.
 *
 * The server (api/src/social.ts) is authoritative: it accepts only an enum or
 * `#rrggbb`, gates color pairs at WCAG AA, and stores a small fixed record.
 * This module is the defensive client half: anything invalid that still
 * arrives (old data, a modified server, a mock) is clamped to the platform
 * default before it can reach a style attribute.
 *
 * There is no font URL, no file upload, no CSS field and no `@font-face`
 * anywhere in this module or the components that consume it. Fonts are
 * allowlisted Google Fonts family IDs that SecretMsg self-hosts as subsetted
 * woff2; the box-page CSP must be `font-src 'self'`.
 */

import type { CSSProperties } from 'react';

export const BOX_PATTERNS = ['none', 'dots', 'grid', 'waves', 'confetti', 'aurora'] as const;
export type BoxPattern = (typeof BOX_PATTERNS)[number];

export const BOX_FONTS = ['inter', 'lora', 'space-grotesk', 'bitter', 'ibm-plex-sans'] as const;
export type BoxFont = (typeof BOX_FONTS)[number];

export interface BoxTheme {
  mode: 'platform' | 'custom';
  background_light: string;
  background_dark: string;
  accent_light: string;
  accent_dark: string;
  pattern: BoxPattern;
  font: BoxFont;
  reactions_enabled: number;
}

export const DEFAULT_BOX_THEME: BoxTheme = {
  mode: 'platform',
  background_light: '#f8fafc',
  background_dark: '#0b1020',
  accent_light: '#4f46e5',
  accent_dark: '#818cf8',
  pattern: 'none',
  font: 'inter',
  reactions_enabled: 1,
};

const HEX_RE = /^#[0-9a-f]{6}$/i;

/** Returns a validated lowercase hex color, or the fallback. Never trusts input. */
export function safeHex(value: unknown, fallback: string): string {
  return typeof value === 'string' && HEX_RE.test(value.trim()) ? value.trim().toLowerCase() : fallback;
}

function safeEnum<T extends string>(value: unknown, allowed: readonly T[], fallback: T): T {
  return typeof value === 'string' && (allowed as readonly string[]).includes(value) ? (value as T) : fallback;
}

/** Clamps a server payload into a value that is safe to put into inline styles. */
export function normalizeBoxTheme(input: unknown): BoxTheme {
  const raw = (input ?? {}) as Record<string, unknown>;
  return {
    mode: raw.mode === 'custom' ? 'custom' : 'platform',
    background_light: safeHex(raw.background_light, DEFAULT_BOX_THEME.background_light),
    background_dark: safeHex(raw.background_dark, DEFAULT_BOX_THEME.background_dark),
    accent_light: safeHex(raw.accent_light, DEFAULT_BOX_THEME.accent_light),
    accent_dark: safeHex(raw.accent_dark, DEFAULT_BOX_THEME.accent_dark),
    pattern: safeEnum(raw.pattern, BOX_PATTERNS, DEFAULT_BOX_THEME.pattern),
    font: safeEnum(raw.font, BOX_FONTS, DEFAULT_BOX_THEME.font),
    reactions_enabled: raw.reactions_enabled === 0 || raw.reactions_enabled === false ? 0 : 1,
  };
}

/** CSS custom properties for the themed subtree. Values are validated hex. */
export function boxThemeVars(theme: BoxTheme, resolved: 'light' | 'dark'): CSSProperties {
  const background = resolved === 'dark' ? theme.background_dark : theme.background_light;
  const accent = resolved === 'dark' ? theme.accent_dark : theme.accent_light;
  return {
    '--box-bg': background,
    '--box-accent': accent,
  } as CSSProperties;
}

/** Family names only. The files are self-hosted; no URL is ever interpolated. */
export function boxFontStack(font: BoxFont): string {
  switch (font) {
    case 'lora':
      return "'Lora', Georgia, 'Times New Roman', serif";
    case 'space-grotesk':
      return "'Space Grotesk', 'Inter', ui-sans-serif, system-ui, sans-serif";
    case 'bitter':
      return "'Bitter', Georgia, serif";
    case 'ibm-plex-sans':
      return "'IBM Plex Sans', 'Inter', ui-sans-serif, system-ui, sans-serif";
    case 'inter':
    default:
      return "'Inter', ui-sans-serif, system-ui, sans-serif";
  }
}

export function patternClass(pattern: BoxPattern): string {
  return pattern === 'none' ? '' : `box-pattern-${pattern}`;
}

export function boxFontClass(font: BoxFont): string {
  return `box-font-${font}`;
}
