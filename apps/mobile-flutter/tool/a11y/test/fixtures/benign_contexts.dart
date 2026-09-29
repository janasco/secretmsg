// Contexts that must be classified correctly, and must NOT be fatal.
//
// A linter that only ever says "yes" is worthless, and the way to earn trust
// is to be visibly wrong when the code is right. Everything here is a case
// where a raw literal is the correct answer, either because the surface is
// theme-invariant by design (a brand mark, a chart, a generated image) or
// because a literal cannot carry a theme anyway (a shadow, a QR quiet zone).

import 'package:flutter/material.dart';

import 'package:secretmsg_mobile/theme.dart';

/// A drop shadow. Shadows are not a text surface and are not expected to
/// respond to a theme.
class ShadowFixture extends StatelessWidget {
  const ShadowFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: const SizedBox(width: 10, height: 10),
    );
  }
}

/// A brand mark: the accent colour is `#6366F1` in *both* palettes by product
/// decision, so hardcoding it loses nothing.
class BrandMarkFixture extends StatelessWidget {
  const BrandMarkFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
        ),
      ),
      child: const Icon(Icons.verified, color: Color(0xFFFFFFFF)),
    );
  }
}

/// The QR code's quiet zone. It has to stay white regardless of theme or the
/// scanner loses contrast against the code.
class QrQuietZoneFixture extends StatelessWidget {
  const QrQuietZoneFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(4),
      child: const SizedBox(width: 56, height: 56),
    );
  }
}

/// A hairline border, which is decoration rather than a fill.
class BorderFixture extends StatelessWidget {
  const BorderFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: const SizedBox(width: 10, height: 10),
    );
  }
}

/// A literal that is genuinely exempt: the Turnstile web view is told which
/// appearance the *upstream challenge* wants, which is not this app's theme.
class ExternalWidgetFixture extends StatelessWidget {
  const ExternalWidgetFixture({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF101322),
      child: SizedBox(width: 10, height: 10),
    );
  }
}
