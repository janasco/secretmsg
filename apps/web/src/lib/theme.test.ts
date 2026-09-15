import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import {
  resolveTheme,
  getStoredTheme,
  systemPrefersDark,
  applyAppTheme,
  initTheme,
  THEME_KEY,
} from './theme';

describe('resolveTheme', () => {
  it('explicit choice wins over the OS', () => {
    expect(resolveTheme('dark', false)).toBe('dark');
    expect(resolveTheme('light', true)).toBe('light');
  });

  it('system/empty/unknown follows the OS', () => {
    expect(resolveTheme('system', true)).toBe('dark');
    expect(resolveTheme('system', false)).toBe('light');
    expect(resolveTheme(null, true)).toBe('dark');
    expect(resolveTheme(null, false)).toBe('light');
    expect(resolveTheme('garbage', true)).toBe('dark');
    expect(resolveTheme('garbage', false)).toBe('light');
  });
});

describe('no-DOM defaults', () => {
  it('falls back to system in SSR (no window)', () => {
    expect(getStoredTheme()).toBe('system');
    expect(systemPrefersDark()).toBe(true);
  });
});

describe('browser behavior (stubbed DOM)', () => {
  let store: Record<string, string>;
  let listeners: Array<() => void>;
  let matches = true;
  let toggled: Record<string, boolean>;
  let colorScheme = '';

  beforeEach(() => {
    store = {};
    listeners = [];
    toggled = {};
    (globalThis as any).window = {
      matchMedia: () => ({
        get matches() {
          return matches;
        },
        addEventListener: (_: string, fn: () => void) => listeners.push(fn),
        removeEventListener: (_: string, fn: () => void) => {
          listeners = listeners.filter((l) => l !== fn);
        },
      }),
    };
    (globalThis as any).localStorage = {
      getItem: (k: string) => (k in store ? store[k] : null),
      setItem: (k: string, v: string) => {
        store[k] = v;
      },
    };
    (globalThis as any).document = {
      documentElement: {
        classList: { toggle: (c: string, on: boolean) => (toggled[c] = on) },
        style: {
          set colorScheme(v: string) {
            colorScheme = v;
          },
        },
      },
      querySelector: () => null,
    };
  });

  afterEach(() => {
    delete (globalThis as any).window;
    delete (globalThis as any).localStorage;
    delete (globalThis as any).document;
  });

  it('persists explicit choice and paints dark', () => {
    expect(applyAppTheme('dark')).toBe('dark');
    expect(store[THEME_KEY]).toBe('dark');
    expect(toggled).toMatchObject({ dark: true, light: false });
    expect(colorScheme).toBe('dark');
  });

  it('system mode persists + resolves from OS', () => {
    matches = false;
    expect(applyAppTheme('system')).toBe('light');
    expect(store[THEME_KEY]).toBe('system');
    expect(getStoredTheme()).toBe('system');
  });

  it('initTheme follows OS changes only in system mode', () => {
    const seen: string[] = [];
    store[THEME_KEY] = 'system';
    const off = initTheme((r) => seen.push(r));
    matches = false;
    listeners.forEach((fn) => fn());
    expect(seen).toEqual(['light']);
    expect(toggled).toMatchObject({ dark: false, light: true });
    // Explicit override stops following the OS.
    applyAppTheme('dark');
    listeners.forEach((fn) => fn());
    expect(seen).toEqual(['light']);
    off();
    expect(listeners).toHaveLength(0);
  });
});
