import 'package:flutter/foundation.dart';

import '../ads/ads_flags.dart';
import '../ritual/drop_store.dart';
import '../ritual/reminders.dart';
import '../ritual/streak_store.dart';
import '../sync/cache.dart';
import '../sync/outbox.dart';
import 'session.dart';

class AccountDataWipeResult {
  final List<String> failures;

  const AccountDataWipeResult(this.failures);

  bool get complete => failures.isEmpty;
}

class AccountDataWipe {
  AccountDataWipe._();

  static Future<AccountDataWipeResult> wipeAllLocalAccountData() async {
    final failures = <String>[];

    void recordFailure(String subsystem) {
      if (!failures.contains(subsystem)) failures.add(subsystem);
    }

    Future<void> run(
      String subsystem,
      Future<void> Function() action,
    ) async {
      try {
        await action();
      } catch (_) {
        recordFailure(subsystem);
      }
    }

    await run('session', () async {
      for (final failure in await Session.clearAccountData()) {
        recordFailure(failure);
      }
    });
    await run('inbox cache', InboxCache.clear);
    await run('outbox', Outbox.clearAll);
    await run('ads flag cache', AdsFlagCache.clear);
    await run('streak', StreakStore.clear);
    await run('Daily Drop', DropStore.clear);
    await run('vibe', VibeStore.clear);
    await run('reminder notifications', cancelAllReminders);
    await run('reminder preferences', () async {
      for (final failure in await clearReminderPreferences()) {
        recordFailure(failure);
      }
    });

    if (failures.isNotEmpty) {
      debugPrint('Local account data wipe incomplete: ${failures.join(', ')}');
    }
    return AccountDataWipeResult(List.unmodifiable(failures));
  }
}
