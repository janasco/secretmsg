/// Rank-up detection + celebration dialog.
library;

import 'package:flutter/material.dart';

import '../api/models.dart';
import '../api/session.dart';
import '../theme.dart';
import 'ranks.dart';

/// Compares the fresh profile rank against the last celebrated tier for this
/// account. Returns true when a rank-up dialog was shown (caller can ignore
/// the result; it exists for tests).
class RankUp {
  static Future<bool> maybeShow(BuildContext context, UserProfile user) async {
    final current = '${user.id}|${user.rank.tier}';
    final last = await Session.getLastSeenRank();
    if (last == null) {
      // First sighting for this install: record silently, no celebration.
      await Session.setLastSeenRank(user.id, user.rank.tier);
      return false;
    }
    if (last == current) return false;
    final lastTier = last.contains('|') ? last.split('|').last : last;
    final climbed =
        tierOrder(user.rank.tier) > tierOrder(lastTier) && tierOrder(lastTier) >= 0;
    await Session.setLastSeenRank(user.id, user.rank.tier);
    if (!climbed) return false;
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (_) => RankUpDialog(rank: user.rank),
    );
    return true;
  }
}

class RankUpDialog extends StatelessWidget {
  final RankInfo rank;

  const RankUpDialog({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.colors.border),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rank.emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Rank up!',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'You reached ${rank.name} with ${rank.score} activity points.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Nice', style: TextStyle(color: context.colors.accent)),
        ),
      ],
    );
  }
}
