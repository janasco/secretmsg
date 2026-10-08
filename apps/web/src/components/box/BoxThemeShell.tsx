import React, { useMemo, useState } from 'react';
import { Moon, Sun } from 'lucide-react';
import { applyAppTheme, getResolvedTheme, type ResolvedTheme } from '@/lib/theme';
import {
  boxFontClass,
  boxFontStack,
  boxThemeVars,
  normalizeBoxTheme,
  patternClass,
  type BoxTheme,
} from './box-theme';
import { PlatformStrip } from './PlatformStrip';
import './box-theme.css';

interface BoxThemeShellProps {
  theme: Partial<BoxTheme> | null | undefined;
  handle: string;
  children: React.ReactNode;
}

/**
 * Renders the themed public box surface.
 *
 * - The theme is clamped through normalizeBoxTheme before touching a style;
 *   only validated `#rrggbb` values ever reach CSS custom properties.
 * - Font choice is a class from the fixed allowlist. No font URL, no
 *   `@font-face`, no user CSS — the box-page CSP is `font-src 'self'`.
 * - The visitor gets a visible light/dark toggle; the initial value follows
 *   their system/app preference. Pattern animation is disabled by CSS under
 *   `prefers-reduced-motion`.
 */
export const BoxThemeShell: React.FC<BoxThemeShellProps> = ({ theme, handle, children }) => {
  const safeTheme = useMemo(() => normalizeBoxTheme(theme ?? {}), [theme]);
  const [resolved, setResolved] = useState<ResolvedTheme>(() => getResolvedTheme());

  const toggle = () => {
    const next: ResolvedTheme = resolved === 'dark' ? 'light' : 'dark';
    setResolved(applyAppTheme(next));
  };

  return (
    <div
      className={`box-page ${boxFontClass(safeTheme.font)} min-h-[60vh] px-4 py-8 sm:py-12`}
      style={{ ...boxThemeVars(safeTheme, resolved), fontFamily: boxFontStack(safeTheme.font) }}
      data-box-theme-mode={safeTheme.mode}
      data-box-theme-resolved={resolved}
    >
      <div className={`box-pattern-layer ${patternClass(safeTheme.pattern)}`} aria-hidden="true" />
      <div className="mx-auto max-w-lg">
        <div className="mb-2 flex justify-end">
          <button
            type="button"
            onClick={toggle}
            className="box-theme-toggle inline-flex items-center gap-1.5 rounded-lg border border-white/10 bg-black/30 px-2.5 py-1.5 text-[11px] text-slate-300 hover:bg-white/5"
            aria-label={resolved === 'dark' ? 'Switch to light mode' : 'Switch to dark mode'}
          >
            {resolved === 'dark' ? <Sun className="h-3.5 w-3.5" /> : <Moon className="h-3.5 w-3.5" />}
            {resolved === 'dark' ? 'Light' : 'Dark'}
          </button>
        </div>
        <PlatformStrip handle={handle} />
        {children}
      </div>
    </div>
  );
};
