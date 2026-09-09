import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/screens.dart';
import '../theme.dart';

class FooterLinks extends StatelessWidget {
  const FooterLinks({super.key});

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _link(BuildContext context, String target, String label) {
    switch (target) {
      case 'home':
        Navigator.of(context).popUntil((r) => r.isFirst);
      case 'supporters':
        _go(context, const AppShell(initialTab: AppTab.supporters));
      case 'dice':
        _go(context, const DiceScreen());
      case 'sticker':
        _go(context, const StickerStudioScreen());
      case 'inbox':
        _go(context, const AppShell(initialTab: AppTab.inbox));
      default:
        _go(context, StaticScreen(keyOf: target));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Container(
          margin: const EdgeInsets.only(top: 40),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.start,
                runSpacing: 28,
                spacing: 36,
                children: [
                  _FooterColumn(
                    title: 'Platform',
                    items: [
                      _ColItem('Home', () => _link(context, 'home', 'Home')),
                      _ColItem('About Us', () => _link(context, 'about', 'About Us')),
                      _ColItem('Supporters Wall', () => _link(context, 'supporters', 'Supporters Wall')),
                      _ColItem('Help & FAQs', () => _link(context, 'faq', 'Help & FAQs')),
                    ],
                  ),
                  _FooterColumn(
                    title: 'Explore',
                    items: [
                      _ColItem('Dice Prompt Roulette', () => _link(context, 'dice', 'Dice Prompt Roulette')),
                      _ColItem('Sticker Studio', () => _link(context, 'sticker', 'Sticker Studio')),
                      _ColItem('Anonymous Inbox', () => _link(context, 'inbox', 'Anonymous Inbox')),
                    ],
                  ),
                  _FooterColumn(
                    title: 'Safety',
                    items: [
                      _ColItem('Safety Center', () => _link(context, 'safety', 'Safety Center')),
                      _ColItem('Child Safety Policy', () => _link(context, 'child-safety', 'Child Safety Policy')),
                      _ColItem('Approach to Safety', () => _link(context, 'approach-to-safety', 'Approach to Safety')),
                      _ColItem('Online Safety Guide', () => _link(context, 'online-safety-guide', 'Online Safety Guide')),
                      _ColItem('Community Guidelines', () => _link(context, 'community-guidelines', 'Community Guidelines')),
                      _ColItem('Our Safety Tools', () => _link(context, 'safety-tools', 'Our Safety Tools')),
                      _ColItem('Crisis Resources (988)', () => _link(context, 'safety-resources', 'Crisis Resources (988)')),
                      _ColItem('Contact & Escalations', () => _link(context, 'contact', 'Contact & Escalations')),
                    ],
                  ),
                  _FooterColumn(
                    title: 'Legal',
                    items: [
                      _ColItem('Privacy Policy', () => _link(context, 'privacy', 'Privacy Policy')),
                      _ColItem('Terms of Service', () => _link(context, 'terms', 'Terms of Service')),
                      _ColItem('Cookies Policy', () => _link(context, 'cookies', 'Cookies Policy')),
                      _ColItem('Disclaimer & Safety', () => _link(context, 'disclaimer', 'Disclaimer & Safety')),
                    ],
                  ),
                  _FooterColumn(
                    title: 'Connect',
                    items: [
                      _ColItem('GitHub Repository', () => _openExternal('https://github.com/janasco/secretmsg')),
                      _ColItem('support@secretmsg.net', () => _openExternal('mailto:support@secretmsg.net')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 14),
              const Text(
                '© 2026 secretmsg.net   ·   Personal Project by janasco\n'
                'Deepening authentic connections, safely.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textFaint,
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColItem {
  final String label;
  final VoidCallback onTap;
  _ColItem(this.label, this.onTap);
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<_ColItem> items;
  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          for (final item in items) ...[
            InkWell(
              onTap: item.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  item.label,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 5),
          ],
        ],
      ),
    );
  }
}