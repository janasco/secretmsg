import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/app_footer.dart';
import 'screens.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _go(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 3.5,
                    top: 3.5,
                    width: 10,
                    height: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0E14),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: 18,
                    height: 18,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 3.5,
                    bottom: 3.5,
                    width: 10,
                    height: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0E14),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Text('SecretMsg', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _go(context, const AppShell(initialTab: AppTab.inbox)),
            child: const Text('Inbox', style: TextStyle(color: Color(0xFFA5B4FC))),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, size: 20),
            color: const Color(0xFFA5B4FC),
            onPressed: () => _go(context, const AppShell(initialTab: AppTab.settings)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Hero(onGo: (s) => _go(context, s)),
          ),
          const SliverToBoxAdapter(child: _FeatureGrid()),
          const SliverToBoxAdapter(child: _VibeTeaser()),
          const SliverToBoxAdapter(child: FooterLinks()),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final void Function(Widget) onGo;
  const _Hero({required this.onGo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF0B0C14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const Text(
                'The messenger that keeps your secrets',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text(
                'Friends, family, fans, and followers can send you honest anonymous questions and messages — no identity defense mechanisms needed.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.55),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => onGo(const AppShell(initialTab: AppTab.send)),
                      child: const Text('Send it to a friend', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => onGo(const LoginScreen()),
                child: const Text('Create your inbox', style: TextStyle(color: Color(0xFFA5B4FC), fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  _miniLogo('LB', const Color(0xFFF59E0B)),
                  const SizedBox(width: 2),
                  _miniLogo('SM', const Color(0xFFE32F2F)),
                  const SizedBox(width: 2),
                  _miniLogo('YT', const Color(0xFFB91C1C)),
                  const SizedBox(width: 2),
                  _miniLogo('TT', const Color(0xFF0EA5E9)),
                  const SizedBox(width: 2),
                  _miniLogo('IG', const Color(0xFFF9A8D4)),
                  const SizedBox(width: 2),
                  _miniLogo('WA', const Color(0xFF16A34A)),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniLogo(String l, Color c) {
    return Tooltip(
      message: l,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.withOpacity(0.18),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(l, style: TextStyle(color: c, fontSize: 9, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      (_Feature(
        icon: Icons.filter_tilt_shift,
        title: 'Be REAL',
        body: 'Share what’s authentic. Sincerity builds trust.',
        color: const Color(0xFF818CF8),
      )),
      (_Feature(
        icon: Icons.favorite_border,
        title: 'Be KIND',
        body: 'Lift each other up and keep every message positive.',
        color: const Color(0xFFF472B6),
      )),
      (_Feature(
        icon: Icons.public,
        title: 'Be YOU',
        body: 'Embrace your unique personality, quirks and all.',
        color: const Color(0xFFFBBF24),
      )),
      (_Feature(
        icon: Icons.visibility_off,
        title: 'Zero Tracking',
        body: 'No IP logs, no ad surveillance, no profile mining.',
        color: const Color(0xFF34D399),
      )),
      (_Feature(
        icon: Icons.pause_circle_outline,
        title: 'Recipient Control',
        body: 'Pause your link, filter words, wipe data in one tap.',
        color: const Color(0xFF60A5FA),
      )),
      (_Feature(
        icon: Icons.double_arrow,
        title: 'Blind Replies',
        body: 'Reply to anonymous messages without revealing IDs.',
        color: const Color(0xFFC084FC),
      )),
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final f in items) _FeatureCard(feature: f)],
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _Feature({required this.icon, required this.title, required this.body, required this.color});
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1220),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(feature.icon, color: feature.color, size: 24),
            const SizedBox(height: 10),
            Text(feature.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 6),
            Text(feature.body, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.45)),
          ],
        ),
      ),
    );
  }
}

class _VibeTeaser extends StatelessWidget {
  const _VibeTeaser();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F1220)]),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Find the perfect vibe to break the ice', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Roll the Dice Roulette or open the Sticker Studio inside every composer.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const DiceScreen()),
                      ),
                      icon: const Icon(Icons.casino_outlined, size: 18),
                      label: const Text('Dice Roulette'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StickerStudioScreen()),
                      ),
                      icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: const Text('Sticker Studio'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}