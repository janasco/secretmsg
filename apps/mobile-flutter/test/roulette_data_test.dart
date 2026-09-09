import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/data/roulette_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('asset loads with every category', () async {
    final categories = await RouletteData.load();

    expect(categories.length, 7, reason: 'six real categories plus the synthesized "all"');
    expect(categories.first.key, RouletteData.allKey);
    expect(categories.first.label, RouletteData.allLabel);
    expect(
      categories.map((c) => c.key).toList(),
      ['all', 'crush', 'spicy', 'secrets', 'chaotic', 'realtalk', 'latenight'],
      reason: 'order drives the chip order on the dice screen',
    );
  });

  test('"all" is rebuilt as the exact concatenation of the others', () async {
    final categories = await RouletteData.load();
    final all = categories.first;
    final rest = categories.skip(1).expand((c) => c.prompts).toList();

    // The asset used to ship a second verbatim copy of every prompt under
    // "all". Rebuilding it has to reproduce the old list exactly, order included.
    expect(all.prompts.length, 9000);
    expect(rest.length, 9000);
    expect(all.prompts, rest);
  });

  test('every category carries prompts and none are blank', () async {
    final categories = await RouletteData.load();

    for (final c in categories.skip(1)) {
      expect(c.prompts.length, 1500, reason: '${c.key} should hold 1500 prompts');
      expect(c.label, isNotEmpty);
      expect(c.prompts.where((p) => p.trim().isEmpty), isEmpty, reason: '${c.key} has a blank prompt');
    }
  });

  test('text survived the move out of Dart source', () async {
    final categories = await RouletteData.load();
    final all = categories.first.prompts;

    // Apostrophes were backslash-escaped in the old Dart literals, and the
    // prompts are full of emoji; both are easy to mangle in a conversion.
    expect(all.any((p) => p.contains("'")), isTrue, reason: 'apostrophes were lost');
    expect(all.any((p) => p.runes.any((r) => r > 0xFFFF)), isTrue, reason: 'emoji were lost');
    expect(all.any((p) => p.contains(r'\')), isFalse, reason: 'stray escape characters');
  });

  test('repeat loads are served from cache', () async {
    final first = await RouletteData.load();
    final second = await RouletteData.load();
    expect(identical(first, second), isTrue);
  });
}
