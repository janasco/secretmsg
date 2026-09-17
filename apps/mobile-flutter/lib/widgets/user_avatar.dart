import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:multiavatar_plus/multiavatar_plus.dart';

/// Brand mark that follows the theme: dark tile in dark mode, light tile
/// in light mode (the dark tile reads near-black on paper backgrounds).
class AppMark extends StatelessWidget {
  final double size;
  final double radius;
  const AppMark({super.key, this.size = 28, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        light ? 'assets/app-icon-light.png' : 'assets/app-icon.png',
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: Text(
            'S',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.55,
            ),
          ),
        ),
      ),
    );
  }
}

/// Generative multiavatar for a user identity, derived deterministically
/// from [seed] (owner `avatar_seed`, otherwise the username). Same seed =
/// same face on every device, no download needed.
class UserAvatar extends StatelessWidget {
  final String seed;
  final double size;
  final String? fallbackInitials;
  const UserAvatar({
    super.key,
    required this.seed,
    required this.size,
    this.fallbackInitials,
  });

  @override
  Widget build(BuildContext context) {
    final key = seed.trim().isEmpty ? 'secretmsg' : seed.trim();
    Widget face;
    try {
      face = SvgPicture.string(
        multiavatar(key),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } catch (_) {
      face = Container(
        width: size,
        height: size,
        color: const Color(0xFF6366F1),
        alignment: Alignment.center,
        child: Text(
          (fallbackInitials ?? String.fromCharCode(key.runes.first)).toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.36,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }
    return ClipOval(child: SizedBox(width: size, height: size, child: face));
  }
}
