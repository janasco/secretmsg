import { describe, it, expect } from 'vitest';
import { getShareUrl } from '@/lib/links';
import { API_BASE_URL, PUBLIC_BASE_URL, USE_MOCK } from '@/lib/config';
import { offlineSupportersFallback } from '@/lib/fallbacks';

describe('config', () => {
  it('exposes production URL defaults', () => {
    expect(API_BASE_URL).toContain('http');
    expect(PUBLIC_BASE_URL).toContain('secretmsg.net');
  });

  it('mock mode defaults to false', () => {
    expect(USE_MOCK).toBe(false);
  });
});

describe('links', () => {
  it('builds a public share URL with encoded username', () => {
    expect(getShareUrl('lumen4821')).toBe(`${PUBLIC_BASE_URL}/lumen4821`);
    expect(getShareUrl('a b')).toContain('a%20b');
  });
});

describe('offlineSupportersFallback', () => {
  it('returns a demo wall with stats', () => {
    const data = offlineSupportersFallback();
    expect(data.supporters.length).toBeGreaterThan(0);
    expect(data.stats.totalSupporters).toBe(data.supporters.length);
    for (const s of data.supporters) {
      expect(s.id).toBeTruthy();
      expect(s.alias).toBeTruthy();
      expect(s.tier).toBeTruthy();
    }
  });
});
