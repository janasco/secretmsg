export type ThemeMode = 'dark' | 'light' | 'system';

const THEME_KEY = 'secretmsg_theme';

export function getInitialTheme(): ThemeMode {
  if (typeof window === 'undefined') return 'system';
  return (localStorage.getItem(THEME_KEY) as ThemeMode) || 'system';
}

export function applyAppTheme(theme: ThemeMode): boolean {
  if (typeof window === 'undefined') return true;
  const isDark =
    theme === 'dark' ||
    (theme === 'system' && window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches);

  if (isDark) {
    document.documentElement.classList.add('dark');
    document.documentElement.classList.remove('light');
  } else {
    document.documentElement.classList.remove('dark');
    document.documentElement.classList.add('light');
  }

  localStorage.setItem(THEME_KEY, theme);
  return isDark;
}
