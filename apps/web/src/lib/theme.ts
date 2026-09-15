/**
 * secretmsg.net theme: System (default) / Dark / Light.
 *
 * Default is the OS preference (`prefers-color-scheme`), read live via
 * matchMedia — including a listener so an OS change while the tab is open
 * re-themes instantly when the user hasn't picked an explicit override.
 * An explicit Dark/Light choice persists in localStorage (`secretmsg_theme`)
 * and wins over the OS value. The pre-paint snippet in index.html must use
 * the same key/values or first paint flashes the wrong mode.
 */

export type ThemeMode = 'dark' | 'light' | 'system';
export type ResolvedTheme = 'dark' | 'light';

export const THEME_KEY = 'secretmsg_theme';
const DARK_META = '#0f111a';
const LIGHT_META = '#f8fafc';

export function systemPrefersDark(): boolean {
  if (typeof window === 'undefined' || !window.matchMedia) return true;
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
}

/** Pure: resolve a stored mode + OS value to a concrete theme. Unit-tested. */
export function resolveTheme(stored: string | null, systemDark: boolean): ResolvedTheme {
  if (stored === 'light') return 'light';
  if (stored === 'dark') return 'dark';
  return systemDark ? 'dark' : 'light';
}

export function getStoredTheme(): ThemeMode {
  if (typeof window === 'undefined') return 'system';
  const saved = localStorage.getItem(THEME_KEY);
  if (saved === 'dark' || saved === 'light' || saved === 'system') return saved;
  return 'system';
}

export function getInitialTheme(): ThemeMode {
  return getStoredTheme();
}

export function getResolvedTheme(): ResolvedTheme {
  return resolveTheme(
    typeof window === 'undefined' ? null : localStorage.getItem(THEME_KEY),
    systemPrefersDark(),
  );
}

function paintTheme(resolved: ResolvedTheme): void {
  if (typeof document === 'undefined') return;
  const root = document.documentElement;
  root.classList.toggle('dark', resolved === 'dark');
  root.classList.toggle('light', resolved !== 'dark');
  root.style.colorScheme = resolved;
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute('content', resolved === 'dark' ? DARK_META : LIGHT_META);
}

/** Apply a mode (persisting it) and paint immediately. Returns the resolved theme. */
export function applyAppTheme(mode: ThemeMode, persist = true): ResolvedTheme {
  if (typeof window !== 'undefined' && persist) {
    localStorage.setItem(THEME_KEY, mode);
  }
  const resolved = resolveTheme(
    mode === 'system' ? null : mode,
    systemPrefersDark(),
  );
  paintTheme(resolved);
  return resolved;
}

/**
 * Initialize theme on boot: paint the stored (or system) theme and subscribe
 * to OS changes while the stored mode is `system`. Returns an unsubscribe fn.
 */
export function initTheme(onChange?: (resolved: ResolvedTheme) => void): () => void {
  paintTheme(getResolvedTheme());
  if (typeof window === 'undefined' || !window.matchMedia) return () => {};
  const mq = window.matchMedia('(prefers-color-scheme: dark)');
  const listener = () => {
    if (getStoredTheme() !== 'system') return;
    const resolved = resolveTheme(null, mq.matches);
    paintTheme(resolved);
    onChange?.(resolved);
  };
  if (typeof mq.addEventListener === 'function') {
    mq.addEventListener('change', listener);
    return () => mq.removeEventListener('change', listener);
  }
  // Legacy Safari (<14): addListener/removeListener.
  const legacy = mq as unknown as {
    addListener: (fn: () => void) => void;
    removeListener: (fn: () => void) => void;
  };
  if (typeof legacy.addListener === 'function') {
    legacy.addListener(listener);
    return () => legacy.removeListener(listener);
  }
  return () => {};
}
