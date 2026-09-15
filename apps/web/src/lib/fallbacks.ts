/**
 * Offline fallback for GET /api/supporters (offline / disconnected builds).
 * The live API returns `seeded:true` with an empty wall; the client keeps a
 * small demo wall so the Supporters page still renders offline.
 */

import type { SupportersData } from './types';

export function offlineSupportersFallback(): SupportersData {
  return {
    supporters: [
      {
        id: 'demo-1',
        alias: 'Anonymous Guardian',
        tier: 'Golden Guardian',
        note: 'Love the true zero-tracking privacy on SecretMsg. Keep it open!',
        createdAt: new Date(Date.now() - 3600000 * 4).toISOString(),
      },
      {
        id: 'demo-2',
        alias: 'Coffee Lover #42',
        tier: 'Coffee Backer',
        note: 'Super smooth UI. Coffee on me for server hosting ☕',
        createdAt: new Date(Date.now() - 3600000 * 26).toISOString(),
      },
      {
        id: 'demo-3',
        alias: 'Secret Admirer 🤫',
        tier: 'Silver Patron',
        note: 'Sent this to my crush and they replied! Thank you!',
        createdAt: new Date(Date.now() - 3600000 * 48).toISOString(),
      },
      {
        id: 'demo-4',
        alias: 'Anonymous Supporter',
        tier: 'Bronze Supporter',
        note: 'Supporting independent open-source web platforms.',
        createdAt: new Date(Date.now() - 3600000 * 72).toISOString(),
      },
    ],
    stats: {
      totalSupporters: 4,
      monthlyServerGoalPercent: 100,
      currentMonth: 'September 2026',
    },
  };
}
