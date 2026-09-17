import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/ritual/reminders.dart';

void main() {
  group('nextSaturday10', () {
    test('lands on Saturday 10:00', () {
      // Wednesday 2026-09-16 15:00 -> Saturday 2026-09-19 10:00.
      final at = nextSaturday10(DateTime(2026, 9, 16, 15, 0));
      expect(at.weekday, DateTime.saturday);
      expect((at.hour, at.minute), (10, 0));
      expect((at.year, at.month, at.day), (2026, 9, 19));
    });

    test('same Saturday morning stays today', () {
      final at = nextSaturday10(DateTime(2026, 9, 19, 8, 30));
      expect((at.year, at.month, at.day, at.hour), (2026, 9, 19, 10));
    });

    test('Saturday after 10:00 rolls a week out', () {
      final at = nextSaturday10(DateTime(2026, 9, 19, 11, 0));
      expect((at.year, at.month, at.day), (2026, 9, 26));
    });
  });

  group('inQuietHours', () {
    test('covers 22:00-08:00', () {
      expect(inQuietHours(DateTime(2026, 9, 16, 23, 0)), true);
      expect(inQuietHours(DateTime(2026, 9, 16, 7, 59)), true);
      expect(inQuietHours(DateTime(2026, 9, 16, 8, 0)), false);
      expect(inQuietHours(DateTime(2026, 9, 16, 21, 30)), false);
    });
  });
}
