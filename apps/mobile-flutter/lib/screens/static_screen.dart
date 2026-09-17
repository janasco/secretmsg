import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/static_content.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Renders a static legal/safety/info page from [STATIC_PAGES].
class StaticScreen extends StatelessWidget {
  final String keyOf;
  const StaticScreen({super.key, required this.keyOf});

  @override
  Widget build(BuildContext context) {
    final page = STATIC_PAGES[keyOf];
    if (page == null) {
      return Scaffold(
        body: Center(child: Text('Page not found', style: TextStyle(color: context.colors.textSecondary))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('SecretMsg', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PublicPageHeader(
              title: page.title,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final section in page.sections) ...[
                    _StaticSectionCard(section: section),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 12),
                  _ContactCta(keyOf: keyOf),
                  // No website footer: legal pages end here. Cross-links to
                  // sibling documents live in the safety center entry point.
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticSectionCard extends StatelessWidget {
  final StaticSection section;
  const _StaticSectionCard({required this.section});

  String get cleanHeading {
    // Strip leading emoji / short marker tokens like 'psychology ' or '🏠 '.
    final words = section.heading.split(' ');
    if (words.length > 1 && _looksLikeMarker(words.first)) {
      return words.sublist(1).join(' ');
    }
    return section.heading;
  }

  bool _looksLikeMarker(String w) {
    if (w.isEmpty) return false;
    if (w.startsWith('#')) return true;
    if (w.codeUnits.any((c) => c >= 0x1F000)) return true;
    return w == 'local_fire_department' || w == 'psychology';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cleanHeading,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final para in section.body)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                para,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 13,
                  height: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactCta extends StatelessWidget {
  final String keyOf;
  const _ContactCta({required this.keyOf});

  @override
  Widget build(BuildContext context) {
    if (keyOf == 'contact') {
      return const _EmailCard();
    }
    return const SizedBox.shrink();
  }
}

class _EmailCard extends StatelessWidget {
  const _EmailCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.accentDeep, context.colors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Need help or have concerns?',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Our team reads every note. For safety emergencies, reach out immediately.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.accent,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final uri = Uri.parse('mailto:support@secretmsg.net');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('support@secretmsg.net'),
            ),
          ),
        ],
      ),
    );
  }
}