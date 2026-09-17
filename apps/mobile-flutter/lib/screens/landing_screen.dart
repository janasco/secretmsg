import 'package:flutter/material.dart';

import '../theme.dart';
import 'screens.dart';

/// First-run welcome: three swipeable cards, then exactly one decision —
/// create an inbox or log in. No marketing grid, no footer, no dead-end
/// buttons. Signed-in users never see this (main routes them to the inbox).
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _cards = [
    (emoji: '💌', title: 'Your anonymous inbox', body: 'Share one link. Friends, crushes and followers send honest TBHs — no accounts, no names, ever.'),
    (emoji: '🔥', title: 'A reason to open it daily', body: "A fresh Daily Drop prompt every morning, streaks that grow, and a nudge the moment someone writes you."),
    (emoji: '🛡️', title: 'Private by design', body: 'Zero tracking, no IP logs, bot-screened senders. Pause your board or wipe everything in one tap.'),
  ];

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              // Brand mark.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('S',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                  ),
                  const SizedBox(width: 10),
                  const Text('SecretMsg',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                ],
              ),
              const SizedBox(height: 8),
              // Swipeable pitch.
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _cards.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final c = _cards[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(c.emoji, style: const TextStyle(fontSize: 64)),
                        const SizedBox(height: 20),
                        Text(c.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.25)),
                        const SizedBox(height: 12),
                        Text(c.body,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.55)),
                      ],
                    );
                  },
                ),
              ),
              // Dots.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _cards.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? AppColors.accent : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // The one decision.
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => _go(const LoginScreen()),
                child: const Text('Create my inbox — free', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _go(const LoginScreen()),
                child: const Text('I already have one — log in',
                    style: TextStyle(color: AppColors.accentSoft, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              TextButton(
                onPressed: () => _go(const AppShell(initialTab: AppTab.send)),
                child: const Text('Just sending to a friend?',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
