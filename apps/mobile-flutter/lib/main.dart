import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// Supports:
///  - https://secretmsg.net/<username> and https://secretmsg.net/send → composer
///  - https://app.secretmsg.net/inbox → inbox
///  - https://secretmsg.net/about     → info page
/// Falls back to [LandingScreen].
class _DeepLinkRouter {
  static Widget routeFor(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return const LandingScreen();
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if ((host == 'app.secretmsg.net' || host == 'secretmsg.net') && segs.isNotEmpty) {
      final first = segs.first;
      if (first == 'inbox') return const InboxScreen();
      if (first == 'send') {
        return segs.length > 1
            ? SendScreen(initialUsername: segs[1])
            : const SendScreen();
      }
      if (first == 'about' || first == 'faq' || first == 'privacy' ||
          first == 'terms' || first == 'safety') {
        return StaticScreen(keyOf: first);
      }
      return SendScreen(initialUsername: first);
    }
    return const LandingScreen();
  }
}

class SecretMsgApp extends StatefulWidget {
  final String initialRoute;
  const SecretMsgApp({super.key, this.initialRoute = '/'});

  @override
  State<SecretMsgApp> createState() => _SecretMsgAppState();
}

class _SecretMsgAppState extends State<SecretMsgApp> {
  late final Widget _home = _DeepLinkRouter.routeFor(widget.initialRoute);

  @override
  Widget build(BuildContext context) {
    const isDiag = bool.fromEnvironment('SMS_TURNSTILE_TEST');
    return MaterialApp(
      title: 'SecretMsg',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: isDiag ? const TurnstileDiagScreen() : _home,
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