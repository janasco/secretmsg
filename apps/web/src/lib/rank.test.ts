import { describe, it, expect } from 'vitest';
import { tierMeta, rankTierOf, rankDetailOf } from './rank';
import type { UserProfile } from './types';

const base = {
  id: 'u1',
  username: 'tester',
  display_name: 'Tester',
  avatar_seed: 'tester',
  is_premium: 0,
} as UserProfile;

describe('tierMeta', () => {
  it('maps known tiers and falls back to newcomer', () => {
    expect(tierMeta('icon')).toMatchObject({ name: 'Icon', emoji: '👑' });
    expect(tierMeta('bogus').tier).toBe('newcomer');
    expect(tierMeta(null).tier).toBe('newcomer');
    expect(tierMeta(undefined).tier).toBe('newcomer');
  });
});

describe('rankTierOf', () => {
  it('reads both rank shapes', () => {
    expect(rankTierOf(base)).toBe('newcomer');
    expect(rankTierOf({ ...base, rank: 'regular' })).toBe('regular');
    expect(
      rankTierOf({ ...base, rank: { tier: 'socialite', score: 80 } }),
    ).toBe('socialite');
    expect(rankTierOf({ ...base, rank: null })).toBe('newcomer');
  });
});

describe('rankDetailOf', () => {
  it('returns breakdown only when /api/me supplied it', () => {
    expect(rankDetailOf(base)).toBeNull();
    expect(rankDetailOf({ ...base, rank: 'regular' })).toBeNull();
    const detail = { tier: 'regular', score: 30, progress: 0.2 };
    expect(rankDetailOf({ ...base, rank: detail })).toEqual(detail);
  });
});
