/**
 * SecretMsg shared API types (imported by api.ts + mockApi.ts).
 */

export interface RankInfo {
  tier: string;
  name?: string;
  emoji?: string;
  score?: number;
  nextTier?: string | null;
  nextName?: string | null;
  nextScore?: number | null;
  progress?: number;
}

export interface UserProfile {
  id: string;
  username: string;
  display_name: string;
  email?: string;
  avatar_seed: string;
  bio?: string;
  is_premium: number;
  badge_title?: string | null;
  custom_slug_unlocked?: number;
  is_paused?: boolean;
  paused_until?: number | null;
  hidden_words?: string[];
  allow_hints?: number;
  /** Full breakdown on /api/me, bare tier string on public profiles. */
  rank?: RankInfo | string | null;
}

export interface AnonymousMessage {
  id: string;
  content: string;
  reply_content?: string | null;
  reply_at?: string | null;
  is_pinned: number;
  is_read: number;
  device_hint?: string | null;
  created_at: string;
}

/**
 * Aggregate support numbers only. There are no donor identities, aliases,
 * tiers, or notes: support is the anonymous `remove_ads` purchase, so the
 * API has nobody to name.
 */
export interface SupportersData {
  stats: {
    totalSupporters: number;
    monthlyServerGoalPercent: number;
    currentMonth: string;
  };
}

export interface BlockedSender {
  sender_fp_hash: string;
  created_at: string;
}
