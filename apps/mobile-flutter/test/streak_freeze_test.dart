import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/gamification/streaks.dart';

void main() {
  group('streak freeze', () {
    test('a freeze pauses the count instead of resetting', () {
      final r = applyMiss(storedCount: 12, freezes: 1);
      expect((r.count, r.freezes, r.froze), (12, 0, true));
    });

    test('without a freeze the streak resets to 1', () {
      final r = applyMiss(storedCount: 12, freezes: 0);
      expect((r.count, r.freezes, r.froze), (1, 0, false));
    });

    test('freezes cap at the max on earn', () {
      expect(earnFreeze(0), 1);
      expect(earnFreeze(1), 1);
      expect(earnFreeze(5, maxFreezes: 3), 3);
    });
  });

  group('streak repair', () {
    test('allowed within 48h with no recent repair', () {
      expect(
        canRepair(
          brokenAt: DateTime(2026, 9, 15, 10),
          now: DateTime(2026, 9, 16, 9),
          lastRepairAt: null,
        ),
        true,
      );
    });

    test('denied after 48h', () {
      expect(
        canRepair(
          brokenAt: DateTime(2026, 9, 13, 10),
          now: DateTime(2026, 9, 16, 9),
          lastRepairAt: null,
        ),
        false,
      );
    });

    test('denied when repaired within the last 30 days', () {
      expect(
        canRepair(
          brokenAt: DateTime(2026, 9, 15, 10),
          now: DateTime(2026, 9, 16, 9),
          lastRepairAt: DateTime(2026, 9, 1, 10),
        ),
        false,
      );
    });

    test('allowed again after 30 days since last repair', () {
      expect(
        canRepair(
          brokenAt: DateTime(2026, 9, 15, 10),
          now: DateTime(2026, 9, 16, 9),
          lastRepairAt: DateTime(2026, 7, 1, 10),
        ),
        true,
      );
    });
  });
}
