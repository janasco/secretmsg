import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/session.dart';
import 'diag/turnstile_diag.dart';
import 'screens/inbox_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/send_screen.dart';
import 'screens/static_screen.dart';
import 'screens/supporters_screen.dart';
import 'screens/sticker_studio_screen.dart';
import 'screens/dice_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.bg,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  const isDiag = bool.fromEnvironment('SMS_TURNSTILE_TEST');
  runApp(SecretMsgApp(
    initialRoute: isDiag ? '/diag' : WidgetsBinding.instance.platformDispatcher.defaultRouteName,
  ));
}

/// Translates web URLs shared to the app into their native screens.
///
/// Anything that is not a known website route is treated as a board handle,
/// because `secretmsg.net/<username>` is the public send link. That fallback
/// makes it important to list every real route here: a missing one would open
/// a compose screen addressed to a user who does not exist.
class DeepLinkRouter {
  /// Website path -> key in STATIC_PAGES. The site serves several of these
  /// under /p/ and /legal/, and sometimes under more than one spelling.
  static const _staticKeys = <String, String>{
    'about': 'about',
    'faq': 'faq',
    'contact': 'contact',
    'contact-us': 'contact',
    'safety': 'safety',
    'privacy': 'privacy',
    'terms': 'terms',
    'cookies': 'cookies',
    'disclaimer': 'disclaimer',
    'safety-tools': 'safety-tools',
    'community-guidelines': 'community-guidelines',
    'approach-to-safety': 'approach-to-safety',
    'child-safety-policy': 'child-safety',
    'child-safety': 'child-safety',
    'guide-to-online-safety': 'online-safety-guide',
    'online-safety-guide': 'online-safety-guide',
    'resources': 'safety-resources',
    'safety-resources': 'safety-resources',
  };

  static Widget routeFor(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return const LandingScreen();

    // A bare route name ('/') carries no host; a shared link does.
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    if (host.isNotEmpty && host != 'secretmsg.net' && !host.endsWith('.secretmsg.net')) {
      return const LandingScreen();
    }

    var raw = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    // The website groups its document pages under /p/ and /legal/; the app has
    // no such nesting, so drop those prefixes before matching.
    while (raw.isNotEmpty && (raw.first.toLowerCase() == 'p' || raw.first.toLowerCase() == 'legal')) {
      raw = raw.sublist(1);
    }
    if (raw.isEmpty) return const LandingScreen();

    final first = raw.first.toLowerCase();

    final staticKey = _staticKeys[first];
    if (staticKey != null) return StaticScreen(keyOf: staticKey);

    switch (first) {
      case 'inbox':
        return const InboxScreen();
      case 'settings':
        return const SettingsScreen();
      case 'supporters':
      case 'donors':
        return const SupportersScreen();
      case 'sticker-studio':
      case 'sticker':
        return const StickerStudioScreen();
      case 'dice':
        return const DiceScreen();
      case 'login':
        return const LoginScreen();
      case 'send':
        return raw.length > 1 ? SendScreen(initialUsername: raw[1]) : const SendScreen();
      case 'reply':
      case 'demo':
        // Web-only flows with no native equivalent.
        return const LandingScreen();
    }

    return SendScreen(initialUsername: raw.first);
  }
}

class SecretMsgApp extends StatefulWidget {
  final String initialRoute;
  const SecretMsgApp({super.key, this.initialRoute = '/'});

  @override
  State<SecretMsgApp> createState() => _SecretMsgAppState();
}

class _SecretMsgAppState extends State<SecretMsgApp> {
  Widget? _home;

  @override
  void initState() {
    super.initState();
    _resolveHome();
  }

  /// A shared link always wins. On a plain launch we check for a stored session
  /// so a signed-in owner opens on their inbox instead of the marketing page.
  Future<void> _resolveHome() async {
    final linked = DeepLinkRouter.routeFor(widget.initialRoute);
    if (linked is! LandingScreen) {
      if (!mounted) return;
      setState(() => _home = linked);
      return;
    }

    Widget next = const LandingScreen();
    try {
      final token = await Session.getToken();
      if (token != null && token.isNotEmpty) next = const InboxScreen();
    } catch (_) {
      // Unreadable secure storage just means we show the landing screen.
    }
    if (!mounted) return;
    setState(() => _home = next);
  }

  @override
  Widget build(BuildContext context) {
    const isDiag = bool.fromEnvironment('SMS_TURNSTILE_TEST');
    return MaterialApp(
      title: 'SecretMsg',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: isDiag ? const TurnstileDiagScreen() : (_home ?? const _Booting()),
      routes: {
        '/home': (_) => const LandingScreen(),
        '/inbox': (_) => const InboxScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/supporters': (_) => const SupportersScreen(),
        '/sticker': (_) => const StickerStudioScreen(),
        '/dice': (_) => const DiceScreen(),
        '/login': (_) => const LoginScreen(),
        '/send': (_) => const SendScreen(),
        '/about': (_) => const StaticScreen(keyOf: 'about'),
        '/faq': (_) => const StaticScreen(keyOf: 'faq'),
        '/privacy': (_) => const StaticScreen(keyOf: 'privacy'),
        '/terms': (_) => const StaticScreen(keyOf: 'terms'),
        '/safety': (_) => const StaticScreen(keyOf: 'safety'),
      },
    );
  }
}

/// Shown for the moment it takes to read the stored session.
class _Booting extends StatelessWidget {
  const _Booting();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
        ),
      ),
    );
  }
}
