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
  it('returns aggregate stats with no donor identities', () => {
    const data = offlineSupportersFallback();
    expect(data.stats).toBeDefined();
    expect(typeof data.stats.totalSupporters).toBe('number');
    expect(typeof data.stats.monthlyServerGoalPercent).toBe('number');
    expect(data).not.toHaveProperty('supporters');
  });
});
