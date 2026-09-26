/**
 * Offline fallback for GET /api/supporters (offline / disconnected builds).
 * Support is a count, not an identity, so the offline shape is aggregate
 * numbers only. The client renders the Support page from `stats` alone.
 */

import type { SupportersData } from '@/lib/types';

export function offlineSupportersFallback(): SupportersData {
  return {
    stats: {
      totalSupporters: 0,
      monthlyServerGoalPercent: 0,
      currentMonth: '',
    },
  };
}
