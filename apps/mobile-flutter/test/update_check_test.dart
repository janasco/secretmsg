import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/ritual/update_check.dart';

void main() {
  group('compareVersions', () {
    test('orders triples numerically, not lexicographically', () {
      expect(compareVersions('1.4.4', '1.4.10'), lessThan(0));
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.4.3', '1.4.3'), 0);
      expect(compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.4', '1.4.0'), 0);
    });
  });
}
