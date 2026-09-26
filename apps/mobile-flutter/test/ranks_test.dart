import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/gamification/ranks.dart';

void main() {
  group('tier ladder', () {
    test('has five tiers in ascending order', () {
      expect(rankTiers.map((t) => t.tier),
          ['newcomer', 'regular', 'socialite', 'influencer', 'icon']);
      for (var i = 1; i < rankTiers.length; i++) {
        expect(rankTiers[i].min, greaterThan(rankTiers[i - 1].min));
      }
    });

    test('tierByName falls back to newcomer', () {
      expect(tierByName('icon').name, 'Icon');
      expect(tierByName('nope').tier, 'newcomer');
      expect(tierByName(null).tier, 'newcomer');
    });

    test('tierOrder climbs with the ladder', () {
      expect(tierOrder('newcomer'), 0);
      expect(tierOrder('icon'), 4);
      expect(tierOrder('bogus'), -1);
      expect(tierOrder('regular') < tierOrder('socialite'), isTrue);
    });
  });

  group('RankInfo.parse', () {
    test('parses the full server payload', () {
      final rank = RankInfo.parse({
        'tier': 'socialite',
        'name': 'Socialite',
        'emoji': '✨',
        'score': 80,
        'nextTier': 'influencer',
        'nextName': 'Influencer',
        'nextScore': 200,
        'progress': 0.04,
      });
      expect(rank.tier, 'socialite');
      expect(rank.score, 80);
      expect(rank.nextTier, 'influencer');
      expect(rank.pointsToNext, 120);
    });

    test('parses a bare tier string (public profile)', () {
      final rank = RankInfo.parse('regular');
      expect(rank.tier, 'regular');
      expect(rank.name, 'Regular');
      expect(rank.nextTier, isNull);
      expect(rank.pointsToNext, isNull);
    });

    test('tolerates missing and malformed payloads', () {
      expect(RankInfo.parse(null).tier, 'newcomer');
      expect(RankInfo.parse('nope').tier, 'newcomer');
      expect(RankInfo.parse(<String, dynamic>{}).tier, 'newcomer');
      final clamped = RankInfo.parse({'tier': 'regular', 'progress': 9});
      expect(clamped.progress, 1.0);
    });
  });
}
