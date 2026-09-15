/**
 * Rank display helpers. The server (GET /api/me) is the source of truth and
 * sends the full breakdown; public profiles carry the bare tier string.
 * Unknown tiers fall back to Newcomer — never crash on new server tiers.
 */

import type { RankInfo, UserProfile } from './types';

export interface RankMeta {
  tier: string;
  name: string;
  emoji: string;
}

const RANK_TIERS: RankMeta[] = [
  { tier: 'newcomer', name: 'Newcomer', emoji: '🌱' },
  { tier: 'regular', name: 'Regular', emoji: '💬' },
  { tier: 'socialite', name: 'Socialite', emoji: '✨' },
  { tier: 'influencer', name: 'Influencer', emoji: '🔥' },
  { tier: 'icon', name: 'Icon', emoji: '👑' },
];

export function tierMeta(tier: string | null | undefined): RankMeta {
  const found = RANK_TIERS.find((t) => t.tier === tier);
  return found ?? RANK_TIERS[0];
}

/** Tier id from either rank shape the API returns. */
export function rankTierOf(user: UserProfile): string {
  const rank: RankInfo | string | null | undefined = user.rank;
  if (!rank) return 'newcomer';
  if (typeof rank === 'string') return rank;
  return rank.tier || 'newcomer';
}

/** Full breakdown when /api/me supplied it, else null (tier chip only). */
export function rankDetailOf(user: UserProfile): RankInfo | null {
  const rank = user.rank;
  if (!rank || typeof rank === 'string') return null;
  return rank;
}
