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
        color: context.colors.surface,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? context.colors.border),
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
    final c = color ?? context.colors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? c : context.colors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? c : context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: filled ? context.colors.textPrimary : context.colors.textSecondary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.type.labelCaps.copyWith(
              color: filled ? context.colors.textPrimary : context.colors.textSecondary,
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
          Text(label.toUpperCase(), style: context.type.labelCaps),
          const SizedBox(height: 2),
          Text(value, style: context.type.headlineMd),
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
          Expanded(child: Text(title, style: context.type.headlineMd)),
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
        gradient: LinearGradient(
          colors: [context.colors.accent, context.colors.amber],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size - (showRing ? size * 0.08 : 0),
          height: size - (showRing ? size * 0.08 : 0),
          decoration: BoxDecoration(
            color: context.colors.bgSoft,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                color: context.colors.textPrimary,
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
        color: context.colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.amber.withValues(alpha: 0.35)),
      ),
      child: Text(
        badgeTitle ?? tier,
        style: TextStyle(
          color: context.colors.amberLight,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Activity-rank pill (emoji + tier name). Mirrors SupporterBadge sizing so
/// the two sit side by side in profile headers.
class RankBadge extends StatelessWidget {
  final String emoji;
  final String name;

  const RankBadge({super.key, required this.emoji, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$emoji $name',
        style: TextStyle(
          color: context.colors.accentSoft,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Thin progress track toward the next rank tier.
class RankProgressBar extends StatelessWidget {
  final double progress;

  const RankProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: context.colors.border,
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/app-icon.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colors.textPrimary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: context.colors.bg,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (title.isEmpty)
                  Text(
                    'SecretMsg',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  Text(
                    title,
                    style: TextStyle(
                      color: context.colors.textPrimary,
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
                    color: context.colors.textSecondary,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                    child: Text(
                      'Back to secretmsg.net',
                      style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
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
                      color: context.colors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.colors.accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      eyebrow!,
                      style: TextStyle(
                        color: context.colors.accentSoft,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textPrimary,
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
                  style: TextStyle(
                    color: context.colors.textHigh,
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
      backgroundColor: context.colors.roseDeep,
    ),
  );
}

void showSuccessSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: context.colors.emerald,
    ),
  );
}

/// Auth shell: branded top bar + centered 480-wide scroll column.
/// Used by login, recovery, and backup-codes so auth screens share one shape.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String heading;
  final String subheading;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.heading,
    required this.subheading,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(heading, style: context.type.headlineMd),
                const SizedBox(height: 8),
                Text(subheading, style: context.type.bodySm.copyWith(height: 1.55)),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// System text field: surface fill, hairline border, 12px radius.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool enabled;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.inputFormatters,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autocorrect: false,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      style: context.type.bodyBase,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: context.colors.textSecondary),
        hintStyle: TextStyle(color: context.colors.textMuted),
        filled: true,
        fillColor: context.colors.surface,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.colors.accent),
        ),
      ),
    );
  }
}