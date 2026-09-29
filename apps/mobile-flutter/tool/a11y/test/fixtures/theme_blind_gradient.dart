// Synthetic fixture. NOT compiled and NOT imported by anything.
//
// This carries the exact pattern from the bug that shipped in
// lib/screens/daily_drop_screen.dart and was fixed in commit 43aa190: a
// gradient whose stops are raw colour literals, dark in both themes, with the
// text on the card resolving to a light-theme token. The real line is fixed,
// so the pattern has to live somewhere for the detector to be tested against;
// putting it back into lib/ to test it would reintroduce the bug.
//
// Read by tool/a11y/test/detector_test.dart. Never edit this to "fix" a
// finding: a finding here is the point of the file.

import 'package:flutter/material.dart';

import 'package:secretmsg_mobile/theme.dart';

/// The pre-fix Daily Drop card.
class ThemeBlindGradientFixture extends StatelessWidget {
  const ThemeBlindGradientFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2356), Color(0xFF151B26)],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Drop",
            style: context.type.titleSm.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Share it out and collect anonymous answers.',
            style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// The post-fix card. Identical to the fixture above except that the gradient
/// reads palette tokens, so it cannot be a theme-blind surface.
class ThemedGradientFixture extends StatelessWidget {
  const ThemedGradientFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.accentDeep, context.colors.surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: context.colors.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Drop",
            style: context.type.titleSm.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
