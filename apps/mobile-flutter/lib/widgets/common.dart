import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

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
          colors: [Color(0xFF6366F1), Color(0xFFF59E0B)],
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
          color: Color(0xFFFCD34D),
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
                        color: Color(0xFFA5B4FC),
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
                    color: Color(0xFFCBD5E1),
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
      backgroundColor: const Color(0xFF7F1D1D),
    ),
  );
}