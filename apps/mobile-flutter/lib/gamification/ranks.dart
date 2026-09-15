/// Activity ranks: client mirror of the server ladder (api/src/ranks.ts).
///
/// The server is the source of truth — it sends the tier plus the full
/// breakdown on GET /api/me and the tier name on public profiles. This file
/// only maps tiers to display metadata and parses the payload tolerantly
/// (unknown tiers fall back to Newcomer, never crash).
library;

class RankTierMeta {
  final String tier;
  final String name;
  final String emoji;
  final int min;

  const RankTierMeta({
    required this.tier,
    required this.name,
    required this.emoji,
    required this.min,
  });
}

const rankTiers = <RankTierMeta>[
  RankTierMeta(tier: 'newcomer', name: 'Newcomer', emoji: '🌱', min: 0),
  RankTierMeta(tier: 'regular', name: 'Regular', emoji: '💬', min: 20),
  RankTierMeta(tier: 'socialite', name: 'Socialite', emoji: '✨', min: 75),
  RankTierMeta(tier: 'influencer', name: 'Influencer', emoji: '🔥', min: 200),
  RankTierMeta(tier: 'icon', name: 'Icon', emoji: '👑', min: 500),
];

RankTierMeta tierByName(String? tier) {
  for (final t in rankTiers) {
    if (t.tier == tier) return t;
  }
  return rankTiers.first;
}

/// Position of [tier] on the ladder (higher = further). Unknown tiers rank lowest.
int tierOrder(String? tier) {
  final idx = rankTiers.indexWhere((t) => t.tier == tier);
  return idx < 0 ? -1 : idx;
}

class RankInfo {
  final String tier;
  final String name;
  final String emoji;
  final int score;
  final String? nextTier;
  final String? nextName;
  final int? nextScore;
  final double progress;

  const RankInfo({
    required this.tier,
    required this.name,
    required this.emoji,
    required this.score,
    this.nextTier,
    this.nextName,
    this.nextScore,
    this.progress = 0,
  });

  /// Points still needed for the next tier, or null at max rank.
  int? get pointsToNext =>
      nextScore == null ? null : (nextScore! - score).clamp(0, 1 << 30);

  factory RankInfo.parse(dynamic raw, {String fallbackTier = 'newcomer'}) {
    if (raw is String) {
      final meta = tierByName(raw);
      return RankInfo(tier: meta.tier, name: meta.name, emoji: meta.emoji, score: 0);
    }
    if (raw is Map) {
      final tier = raw['tier']?.toString() ?? fallbackTier;
      final meta = tierByName(tier);
      int asInt(dynamic v, int dflt) =>
          v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? dflt;
      double asDouble(dynamic v, double dflt) {
        if (v is num) return v.toDouble().clamp(0.0, 1.0);
        final p = double.tryParse(v?.toString() ?? '');
        return p == null ? dflt : p.clamp(0.0, 1.0);
      }

      return RankInfo(
        tier: meta.tier,
        name: raw['name']?.toString() ?? meta.name,
        emoji: raw['emoji']?.toString() ?? meta.emoji,
        score: asInt(raw['score'], 0),
        nextTier: raw['nextTier']?.toString() ?? raw['next_tier']?.toString(),
        nextName: raw['nextName']?.toString() ?? raw['next_name']?.toString(),
        nextScore: raw['nextScore'] != null || raw['next_score'] != null
            ? asInt(raw['nextScore'] ?? raw['next_score'], 0)
            : null,
        progress: asDouble(raw['progress'], 0),
      );
    }
    final meta = tierByName(fallbackTier);
    return RankInfo(tier: meta.tier, name: meta.name, emoji: meta.emoji, score: 0);
  }
}
