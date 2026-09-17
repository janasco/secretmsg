/// Shared celebration dialog for newly unlocked badges and freshly
/// completed challenges (rank-ups keep their dedicated RankUpDialog).
library;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'badges.dart';
import 'challenges.dart';

class UnlocksDialog extends StatelessWidget {
  final List<BadgeDef> badges;
  final List<ChallengeDef> challenges;

  const UnlocksDialog({super.key, this.badges = const [], this.challenges = const []});

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
          const Text('🎉', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Unlocked!',
            style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final b in badges) ...[
            Text(
              '${b.emoji} ${b.name}',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              b.hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
          ],
          for (final c in challenges) ...[
            Text(
              '${c.emoji} Challenge: ${c.title}',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              c.hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Sweet', style: TextStyle(color: context.colors.accent)),
        ),
      ],
    );
  }
}

/// Shows the unlocks dialog when there is anything new. Returns true if shown.
Future<bool> maybeShowUnlocks(
  BuildContext context, {
  List<BadgeDef> badges = const [],
  List<ChallengeDef> challenges = const [],
}) async {
  if (badges.isEmpty && challenges.isEmpty) return false;
  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    builder: (_) => UnlocksDialog(badges: badges, challenges: challenges),
  );
  return true;
}
