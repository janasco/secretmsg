import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Stitch vocabulary: glass panel on the obsidian backdrop — surface fill,
/// hairline border, 16px radius. The default card container for list items,
/// stat cards and sectioned content.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;
  final Color? borderColor;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

/// Stitch: small-caps pill — label-caps type, 9999px radius, hairline border.
/// [filled] switches to the brand violet fill for selected/active states.
class StitchPill extends StatelessWidget {
  final String label;
  final bool filled;
  final Color? color;
  final IconData? icon;

  const StitchPill(this.label, {super.key, this.filled = false, this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? c : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? c : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppType.labelCaps.copyWith(
              color: filled ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stitch KPI stat card: caption label over a bold value inside a glass card.
class StatCard extends StatelessWidget {
  final String label;
  final String value;

  const StatCard({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(), style: AppType.labelCaps),
          const SizedBox(height: 2),
          Text(value, style: AppType.headlineMd),
        ],
      ),
    );
  }
}

/// Stitch in-content section header: headline title with an optional
/// trailing widget (pill, button) on the same row.
class StitchSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const StitchSectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppType.headlineMd)),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AvatarBadge extends StatelessWidget {
  final String initials;
  final double size;
  final bool showRing;

  const AvatarBadge({
    super.key,
    required this.initials,
    this.size = 48,
    this.showRing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size - (showRing ? size * 0.08 : 0),
          height: size - (showRing ? size * 0.08 : 0),
          decoration: const BoxDecoration(
            color: AppColors.bgSoft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials.isEmpty ? 'S' : initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SupporterBadge extends StatelessWidget {
  final String tier;
  final String? badgeTitle;

  const SupporterBadge({super.key, required this.tier, this.badgeTitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.amber.withOpacity(0.35)),
      ),
      child: Text(
        badgeTitle ?? tier,
        style: const TextStyle(
          color: AppColors.amberLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogo;
  final List<Widget>? actions;

  const AppTopBar({super.key, this.title = '', this.showLogo = true, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: showLogo
          ? Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'S',
                    style: TextStyle(
                      color: AppColors.bg,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (title.isEmpty)
                  const Text(
                    'SecretMsg',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            )
          : Text(title),
      actions: actions,
    );
  }
}

/// Section heading used across public pages (mirrors PublicPage.tsx).
class PublicPageHeader extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? description;
  final Widget? child;

  const PublicPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    color: AppColors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text(
                      'Back to secretmsg.net',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (eyebrow != null)
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.accent.withOpacity(0.25)),
                    ),
                    child: Text(
                      eyebrow!,
                      style: const TextStyle(
                        color: AppColors.accentSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 10),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textHigh,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (child != null) child!,
            ],
          ),
        ),
      ),
    );
  }
}

void copyToClipboard(BuildContext context, String text,
    {String? message}) {
  Clipboard.setData(ClipboardData(text: text));
  if (message != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }
}

void showErrorSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.roseDeep,
    ),
  );
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.emerald,
    ),
  );
}