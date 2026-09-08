export type ThemeMode = 'dark' | 'light';

const THEME_KEY = 'secretmsg_theme';

export function getSystemTheme(): ThemeMode {
  if (typeof window === 'undefined') return 'dark';
  return (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
}

export function getInitialTheme(): ThemeMode {
  if (typeof window === 'undefined') return 'dark';
  const saved = localStorage.getItem(THEME_KEY) as ThemeMode;
  if (saved === 'dark' || saved === 'light') return saved;
  return getSystemTheme();
}

export function applyAppTheme(theme: ThemeMode, persist = true): boolean {
  if (typeof window === 'undefined') return true;
  const isDark = theme === 'dark';

  if (isDark) {
    document.documentElement.classList.add('dark');
    document.documentElement.classList.remove('light');
  } else {
    document.documentElement.classList.remove('dark');
    document.documentElement.classList.add('light');
  }

  if (persist) {
    localStorage.setItem(THEME_KEY, theme);
  }
  return isDark;
}
