/// Badge shelf: lifetime achievement catalog + evaluation.
///
/// Badges unlock from data the app already holds (profile counters, rank,
/// supporter flag, streak). Evaluation is pure (unit-tested); the unlocked
/// set persists per account in Session, and newly unlocked badges are
/// celebrated once via [newUnlocks].
library;

import 'ranks.dart';

/// A badge definition. [check] receives lifetime metrics + rank tier.
class BadgeDef {
  final String id;
  final String name;
  final String hint;
  final String emoji;

  const BadgeDef({
    required this.id,
    required this.name,
    required this.hint,
    required this.emoji,
  });
}

/// Lifetime metrics snapshot used for badge evaluation.
class LifetimeMetrics {
  final int received;
  final int replies;
  final int streak;
  final String rankTier;
  final bool isSupporter;

  const LifetimeMetrics({
    required this.received,
    required this.replies,
    required this.streak,
    required this.rankTier,
    required this.isSupporter,
  });
}

typedef BadgeCheck = bool Function(LifetimeMetrics m);

class _BadgeRule {
  final BadgeDef def;
  final BadgeCheck check;
  const _BadgeRule(this.def, this.check);
}

/// Closure factories can't be const, so the rule table is final.
final _badgeRules = <_BadgeRule>[
  _BadgeRule(
    const BadgeDef(id: 'first-message', name: 'Breaking the Ice', hint: 'Receive your first message', emoji: '💌'),
    _receivedAtLeast(1),
  ),
  _BadgeRule(
    const BadgeDef(id: 'chatterbox', name: 'Chatterbox', hint: 'Receive 25 messages', emoji: '📣'),
    _receivedAtLeast(25),
  ),
  _BadgeRule(
    const BadgeDef(id: 'magnet', name: 'People Magnet', hint: 'Receive 100 messages', emoji: '🧲'),
    _receivedAtLeast(100),
  ),
  _BadgeRule(
    const BadgeDef(id: 'quick-wit', name: 'Quick Wit', hint: 'Send your first reply', emoji: '⚡'),
    _repliesAtLeast(1),
  ),
  _BadgeRule(
    const BadgeDef(id: 'conversationalist', name: 'Conversationalist', hint: 'Send 10 replies', emoji: '💬'),
    _repliesAtLeast(10),
  ),
  _BadgeRule(
    const BadgeDef(id: 'oracle', name: 'Oracle', hint: 'Send 50 replies', emoji: '🔮'),
    _repliesAtLeast(50),
  ),
  _BadgeRule(
    const BadgeDef(id: 'streak-3', name: 'Warming Up', hint: '3-day check-in streak', emoji: '🔥'),
    _streakAtLeast(3),
  ),
  _BadgeRule(
    const BadgeDef(id: 'streak-7', name: 'Creature of Habit', hint: '7-day check-in streak', emoji: '📅'),
    _streakAtLeast(7),
  ),
  _BadgeRule(
    const BadgeDef(id: 'streak-30', name: 'Unstoppable', hint: '30-day check-in streak', emoji: '🌋'),
    _streakAtLeast(30),
  ),
  _BadgeRule(
    const BadgeDef(id: 'rank-regular', name: 'Rising Regular', hint: 'Reach Regular rank', emoji: '🌱'),
    _rankAtLeast('regular'),
  ),
  _BadgeRule(
    const BadgeDef(id: 'rank-socialite', name: 'Scene Favorite', hint: 'Reach Socialite rank', emoji: '✨'),
    _rankAtLeast('socialite'),
  ),
  _BadgeRule(
    const BadgeDef(id: 'rank-influencer', name: 'Crowd Puller', hint: 'Reach Influencer rank', emoji: '🎤'),
    _rankAtLeast('influencer'),
  ),
  _BadgeRule(
    const BadgeDef(id: 'rank-icon', name: 'Living Legend', hint: 'Reach Icon rank', emoji: '👑'),
    _rankAtLeast('icon'),
  ),
  _BadgeRule(
    const BadgeDef(id: 'supporter', name: 'Patron', hint: 'Support SecretMsg', emoji: '💛'),
    _isSupporter(),
  ),
];

BadgeCheck _receivedAtLeast(int n) => (LifetimeMetrics m) => m.received >= n;
BadgeCheck _repliesAtLeast(int n) => (LifetimeMetrics m) => m.replies >= n;
BadgeCheck _streakAtLeast(int n) => (LifetimeMetrics m) => m.streak >= n;
BadgeCheck _rankAtLeast(String tier) =>
    (LifetimeMetrics m) => tierOrder(m.rankTier) >= tierOrder(tier);
BadgeCheck _isSupporter() => (LifetimeMetrics m) => m.isSupporter;

/// All badge definitions (the shelf), in display order.
List<BadgeDef> get badgeCatalog => [for (final r in _badgeRules) r.def];

/// Ids of all badges unlocked by [m].
Set<String> evaluateBadges(LifetimeMetrics m) {
  final out = <String>{};
  for (final r in _badgeRules) {
    if (r.check(m)) out.add(r.def.id);
  }
  return out;
}

/// Newly unlocked badge defs (in catalog order) given the stored set.
List<BadgeDef> newUnlocks(Set<String> unlocked, Set<String> stored) {
  final fresh = unlocked.difference(stored);
  return [for (final r in _badgeRules) if (fresh.contains(r.def.id)) r.def];
}

BadgeDef? badgeById(String id) {
  for (final r in _badgeRules) {
    if (r.def.id == id) return r.def;
  }
  return null;
}
