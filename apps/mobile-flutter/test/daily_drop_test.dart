import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/ritual/daily_drop.dart';

void main() {
  group('drop pick', () {
    test('is deterministic for the same day', () {
      final day = DateTime(2026, 9, 17, 8, 30);
      expect(dropIndexForDay(day, 100), dropIndexForDay(DateTime(2026, 9, 17, 23, 59), 100));
    });

    test('advances day to day across midnight', () {
      // Pool of 7 over consecutive days must not repeat the index.
      final before = dropIndexForDay(DateTime(2026, 9, 17, 23, 59), 7);
      final after = dropIndexForDay(DateTime(2026, 9, 18, 0, 1), 7);
      expect(after, (before + 1) % 7);
    });

    test('always lands inside the pool', () {
      for (var m = 1; m <= 12; m++) {
        final i = dropIndexForDay(DateTime(2027, m, 15, 12), 53);
        expect(i, inInclusiveRange(0, 52));
      }
    });

    test('rejects empty pools', () {
      expect(() => dropIndexForDay(DateTime(2026, 9, 17), 0), throwsArgumentError);
    });
  });

  group('drop expiry', () {
    test('expires at local midnight', () {
      expect(dropExpiresAt(DateTime(2026, 9, 17, 8, 30)), DateTime(2026, 9, 18));
      expect(dropExpiresAt(DateTime(2026, 9, 17, 23, 59, 59)), DateTime(2026, 9, 18));
    });

    test('time left is positive and shrinks to midnight', () {
      final morning = dropTimeLeft(DateTime(2026, 9, 17, 8, 0));
      final night = dropTimeLeft(DateTime(2026, 9, 17, 23, 0));
      expect(morning, const Duration(hours: 16));
      expect(night, const Duration(hours: 1));
      expect(night < morning, true);
    });

    test('DST spring-forward day still expires at midnight', () {
      // America/New_York 2026-03-08 clocks jump 02:00 -> 03:00; the calendar
      // day is 23 h long. Midnight math must not drift the pick.
      final before = dropIndexForDay(DateTime(2026, 3, 7, 12), 50);
      final dstDay = dropIndexForDay(DateTime(2026, 3, 8, 12), 50);
      final after = dropIndexForDay(DateTime(2026, 3, 9, 12), 50);
      expect(dstDay, (before + 1) % 50);
      expect(after, (dstDay + 1) % 50);
    });
  });

  group('drop done', () {
    test('matches on calendar day only', () {
      expect(isDropDone('2026-09-17', DateTime(2026, 9, 17, 9)), true);
      expect(isDropDone('2026-09-16', DateTime(2026, 9, 17, 9)), false);
      expect(isDropDone(null, DateTime(2026, 9, 17, 9)), false);
      expect(isDropDone('', DateTime(2026, 9, 17, 9)), false);
    });
  });

  group('countdown label', () {
    test('formats h/m/s tiers', () {
      expect(dropCountdownLabel(const Duration(hours: 4, minutes: 12)), '4h 12m');
      expect(dropCountdownLabel(const Duration(minutes: 38, seconds: 5)), '38m 05s');
      expect(dropCountdownLabel(const Duration(seconds: 52)), '52s');
    });
  });
}
