import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/gamification/badges.dart';
import 'package:secretmsg_mobile/gamification/challenges.dart';
import 'package:secretmsg_mobile/gamification/progress.dart';
import 'package:secretmsg_mobile/gamification/ranks.dart';
import 'package:secretmsg_mobile/gamification/streaks.dart';
import 'package:secretmsg_mobile/api/models.dart';

UserProfile _user({int received = 0, int replies = 0, String tier = 'newcomer', int score = 0, bool supporter = false}) {
  return UserProfile(
    id: 'u1',
    username: 'tester',
    displayName: 'Tester',
    receivedCount: received,
    repliesCount: replies,
    isPremium: supporter ? 1 : 0,
    rank: RankInfo(tier: tier, name: tier, emoji: 'x', score: score),
  );
}

void main() {
  group('streaks', () {
    test('first check-in starts at 1', () {
      final r = rollStreak(storedLastDay: null, storedCount: 0, today: '2026-09-15');
      expect((r.count, r.lastDay), (1, '2026-09-15'));
    });

    test('same day keeps count', () {
      final r = rollStreak(storedLastDay: '2026-09-15', storedCount: 4, today: '2026-09-15');
      expect(r.count, 4);
    });

    test('consecutive day increments', () {
      final r = rollStreak(storedLastDay: '2026-09-14', storedCount: 4, today: '2026-09-15');
      expect((r.count, r.lastDay), (5, '2026-09-15'));
    });

    test('missed day resets', () {
      final r = rollStreak(storedLastDay: '2026-09-10', storedCount: 9, today: '2026-09-15');
      expect((r.count, r.lastDay), (1, '2026-09-15'));
    });

    test('month boundary counts as consecutive', () {
      final r = rollStreak(storedLastDay: '2026-08-31', storedCount: 2, today: '2026-09-01');
      expect(r.count, 3);
    });
  });

  group('challenges', () {
    test('rotation is deterministic and stable', () {
      final a = challengesForDay(42).map((c) => c.id).toList();
      final b = challengesForDay(42).map((c) => c.id).toList();
      expect(a, b);
      expect(a.length, 3);
      expect(a.toSet().length, 3);
    });

    test('progress and completion', () {
      const def = ChallengeDef(id: 'x', title: 't', hint: 'h', emoji: 'e', metric: 'replies_today', goal: 2);
      const m = DayMetrics(receivedToday: 0, repliesToday: 1, streak: 1, score: 0);
      expect(challengeProgress(def, m), 0.5);
      expect(challengeDone(def, m), isFalse);
      const m2 = DayMetrics(receivedToday: 0, repliesToday: 2, streak: 1, score: 0);
      expect(challengeDone(def, m2), isTrue);
    });

    test('day rollover resets deltas and snapshots current', () {
      final r = rollDayDeltas(
        snapshotDate: '2026-09-14', snapReceived: 5, snapReplies: 2,
        currentReceived: 9, currentReplies: 4, today: '2026-09-15',
      );
      expect((r.receivedToday, r.repliesToday), (0, 0));
      expect((r.snapReceived, r.snapReplies), (9, 4));
    });

    test('same-day deltas accumulate', () {
      final r = rollDayDeltas(
        snapshotDate: '2026-09-15', snapReceived: 5, snapReplies: 2,
        currentReceived: 8, currentReplies: 3, today: '2026-09-15',
      );
      expect((r.receivedToday, r.repliesToday), (3, 1));
    });
  });

  group('badges', () {
    test('catalog is unique and ordered', () {
      final ids = badgeCatalog.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(ids.length, greaterThan(10));
    });

    test('fresh account unlocks nothing', () {
      const m = LifetimeMetrics(received: 0, replies: 0, streak: 1, rankTier: 'newcomer', isSupporter: false);
      expect(evaluateBadges(m), isEmpty);
    });

    test('milestones unlock in order', () {
      const m = LifetimeMetrics(received: 30, replies: 12, streak: 8, rankTier: 'regular', isSupporter: true);
      final got = evaluateBadges(m);
      expect(got, containsAll(['first-message', 'chatterbox', 'quick-wit', 'conversationalist', 'streak-3', 'streak-7', 'rank-regular', 'supporter']));
      expect(got, isNot(contains('magnet')));
      expect(got, isNot(contains('oracle')));
      expect(got, isNot(contains('rank-icon')));
    });

    test('newUnlocks diffs against stored set', () {
      const m = LifetimeMetrics(received: 1, replies: 0, streak: 1, rankTier: 'newcomer', isSupporter: false);
      final fresh = newUnlocks(evaluateBadges(m), {'first-message'});
      expect(fresh, isEmpty);
      final fresh2 = newUnlocks(evaluateBadges(m), <String>{});
      expect(fresh2.map((b) => b.id), ['first-message']);
    });
  });

  group('progress orchestration', () {
    test('fresh account: streak 1, no celebrations', () {
      final u = _user();
      final p = evaluateProgress(user: u, today: '2026-09-15', dayNumber: 10);
      expect(p.streak, 1);
      expect(p.metrics.receivedToday, 0);
      expect(p.freshBadges, isEmpty);
      expect(p.freshChallenges, isEmpty);
      expect(p.streakDoc['userId'], 'u1');
    });

    test('foreign stored docs reset instead of inheriting', () {
      final u = _user(received: 2);
      final p = evaluateProgress(
        user: u, today: '2026-09-15', dayNumber: 10,
        streakDoc: {'userId': 'other', 'count': 30, 'last': '2026-09-14'},
        dayDoc: {'userId': 'other', 'date': '2026-09-15', 'received': 100, 'replies': 50},
        badgesDoc: {'userId': 'other', 'ids': ['oracle']},
      );
      expect(p.streak, 1);
      expect(p.metrics.receivedToday, 0);
      expect(p.unlockedBadgeIds, isNot(contains('oracle')));
    });

    test('completions surface once, then go quiet', () {
      final u = _user(received: 1, replies: 2);
      final first = evaluateProgress(user: u, today: '2026-09-15', dayNumber: 10);
      expect(first.freshBadges.map((b) => b.id), contains('first-message'));
      // Simulate persisted state: second evaluation celebrates nothing new.
      final second = evaluateProgress(
        user: u, today: '2026-09-15', dayNumber: 10,
        streakDoc: first.streakDoc, dayDoc: first.dayDoc, badgesDoc: first.badgesDoc,
        seenDoneIds: first.doneIds,
      );
      expect(second.freshBadges, isEmpty);
      expect(second.freshChallenges, isEmpty);
    });
  });
}
