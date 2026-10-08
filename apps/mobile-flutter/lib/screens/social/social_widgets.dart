import 'package:flutter/material.dart';

import '../../theme.dart';
import 'social_api.dart';

/// Honest-limits panel. Every group surface repeats what the platform cannot
/// do, because the alternative is a user discovering it when they are already
/// hurt: bodies are ciphertext, client-side filtering is bypassable by a
/// modified client, owner moderation cannot un-send or prevent screenshots,
/// and the platform acts on reports and metadata rather than on unseen content.
class SocialHonestLimitsCard extends StatelessWidget {
  final List<String> lines;

  const SocialHonestLimitsCard({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.info_outline, size: 16, color: context.colors.amber),
              const SizedBox(width: 8),
              Text(
                'The honest limits',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final String line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '\u2022 $line',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fixed six-emoji reaction strip. One reaction per person; tapping the same
/// one removes it, tapping another switches it. No negative glyph exists and
/// no downvote control is ever rendered. Selection is conveyed by shape and
/// semantics, not color alone.
class ReactionStrip extends StatelessWidget {
  final Map<String, int> counts;
  final String? mine;
  final bool enabled;
  final String disabledCopy;
  final bool showCounts;
  final ValueChanged<String> onSelect;

  const ReactionStrip({
    super.key,
    required this.counts,
    required this.mine,
    required this.enabled,
    required this.disabledCopy,
    required this.onSelect,
    this.showCounts = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final ReactionEmoji emoji in kReactionEmoji)
              _ReactionButton(
                emoji: emoji,
                selected: mine == emoji.id,
                count: showCounts ? (counts[emoji.id] ?? 0) : 0,
                showCount: showCounts,
                enabled: enabled,
                onTap: () => onSelect(emoji.id),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          enabled
              ? (showCounts
                  ? 'Counts are aggregate. No surface shows who reacted.'
                  : 'One reaction per person. No public counts, no downvotes.')
              : disabledCopy,
          style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.4),
        ),
      ],
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final ReactionEmoji emoji;
  final bool selected;
  final int count;
  final bool showCount;
  final bool enabled;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.selected,
    required this.count,
    required this.showCount,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '${emoji.label} (selected)' : emoji.label,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? context.colors.accent.withValues(alpha: 0.22)
                : context.colors.surfaceLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.colors.accent : context.colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(emoji.glyph, style: const TextStyle(fontSize: 18)),
              if (showCount && count > 0) ...<Widget>[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? context.colors.textPrimary : context.colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SocialEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const SocialEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 40, color: context.colors.textMuted),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.5),
          ),
          if (action != null) ...<Widget>[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class SocialErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SocialErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_off, size: 36, color: context.colors.roseLight),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Small-caps metadata chip used for pseudonyms, day timestamps, and states.
class SocialChip extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const SocialChip({super.key, required this.label, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final Color tint = color ?? context.colors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tint.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: tint),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: tint, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
