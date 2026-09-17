import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api/session.dart';
import 'diag/turnstile_diag.dart';
import 'ritual/daily_drop.dart';
import 'ritual/drop_store.dart';
import 'ritual/push.dart';
import 'ritual/reminders.dart';
import 'ritual/update_check.dart';
import 'sync/connectivity.dart';
import 'data/vibe_templates.dart';
import 'screens/app_shell.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/send_screen.dart';
import 'screens/static_screen.dart';
import 'screens/sticker_studio_screen.dart';
import 'screens/supporters_screen.dart';
import 'screens/dice_screen.dart';
import 'theme.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColors.bg,
      statusBarIconBrightness: WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ),
  );
  // Theme choice loads before runApp so the first frame already matches
  // (system default unless the user overrode it in settings).
  try {
    await ThemeController.load();
  } catch (_) {}
  // Reminders init before runApp so a notification-tap cold start captures
  // its payload route. Best-effort: never let this crash boot.
  try {
    await initReminders();
  } catch (_) {}
  // Push init is separate: Firebase misconfiguration must not take down boot.
  try {
    await initPush();
  } catch (_) {}
  // Sync engine: outbox drain on reconnect. Never blocks boot.
  try {
    await SyncService.init();
  } catch (_) {}
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
        return const AppShell(initialTab: AppTab.inbox);
      case 'settings':
        return const AppShell(initialTab: AppTab.settings);
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
        // A link addressed to someone opens the composer on its own, because
        // the sender is usually a stranger with no inbox of their own. A bare
        // /send is the shell's composer tab.
        return raw.length > 1
            ? SendScreen(initialUsername: raw[1])
            : const AppShell(initialTab: AppTab.send);
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
  final _navKey = GlobalKey<NavigatorState>();
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _resolveHome();
  }

  /// A shared link always wins. On a plain launch we check for a stored session
  /// so a signed-in owner opens on their inbox instead of the marketing page.
  /// A notification tap wins over both, and a signed-in cold start refreshes
  /// today's ritual reminders from current state.
  Future<void> _resolveHome() async {
    final tapRoute = pendingRoute;
    pendingRoute = null;
    if (tapRoute == '/drop' || tapRoute == '/inbox') {
      if (!mounted) return;
      setState(() => _home = const AppShell(initialTab: AppTab.inbox));
      unawaited(_maybePromptUpdate());
      return;
    }

    final linked = DeepLinkRouter.routeFor(widget.initialRoute);
    if (linked is! LandingScreen) {
      if (!mounted) return;
      setState(() => _home = linked);
      unawaited(_maybePromptUpdate());
      return;
    }

    Widget next = const LandingScreen();
    try {
      final token = await Session.getToken();
      if (token != null && token.isNotEmpty) {
        next = const AppShell(initialTab: AppTab.inbox);
        await _refreshRitualReminders();
        // Push token self-heals on every signed-in cold start.
        try {
          await registerPushToken();
        } catch (_) {}
      }
    } catch (_) {
      // Unreadable secure storage just means we show the landing screen.
    }
    if (!mounted) return;
    setState(() => _home = next);
    unawaited(_maybePromptUpdate());
  }

  /// Cold-start update prompt: once per launch, skippable (Later snoozes
  /// until the next cold start). Best-effort — never blocks or breaks boot.
  Future<void> _maybePromptUpdate() async {
    if (_updateChecked) return;
    _updateChecked = true;
    try {
      final info = await checkForUpdate();
      if (info == null || !info.behind) return;
      final ctx = _navKey.currentContext;
      if (ctx == null || !ctx.mounted || !mounted) return;
      await showUpdateDialog(ctx, info);
    } catch (_) {}
  }

  /// Derives today's reminders from ritual state. Signed-out users get none;
  /// signed-in users get the Drop reminders until answered (the inbox owns
  /// check-ins and streak counts once it loads).
  Future<void> _refreshRitualReminders() async {
    try {
      final now = DateTime.now();
      final prompt = VIBE_TEMPLATES[dropIndexForDay(now, VIBE_TEMPLATES.length)].text;
      await rescheduleAll(
        now: now,
        dropAnswered: await DropStore.isDone(now),
        checkedInToday: false,
        streakCount: 0,
        dropPrompt: prompt,
      );
    } catch (_) {
      // Reminders are best-effort; never break sign-in.
    }
  }

  @override
  Widget build(BuildContext context) {
    const isDiag = bool.fromEnvironment('SMS_TURNSTILE_TEST');
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (_, mode, __) {
        // Keep the system chrome in sync with the effective brightness.
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        final effectiveDark = mode == ThemeMode.dark ||
            (mode == ThemeMode.system && platformBrightness == Brightness.dark);
        final chromeBg = effectiveDark ? context.colors.bg : context.colors.textPrimary;
        final chromeIcons =
            effectiveDark ? Brightness.light : Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: chromeBg,
            statusBarIconBrightness: chromeIcons,
            systemNavigationBarColor: chromeBg,
            systemNavigationBarIconBrightness: chromeIcons,
          ),
        );
        return MaterialApp(
      title: 'SecretMsg',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      navigatorKey: _navKey,
      home: isDiag ? const TurnstileDiagScreen() : (_home ?? const _Booting()),
      routes: {
        '/home': (_) => const LandingScreen(),
        '/inbox': (_) => const AppShell(initialTab: AppTab.inbox),
        '/settings': (_) => const AppShell(initialTab: AppTab.settings),
        '/supporters': (_) => const SupportersScreen(),
        '/sticker': (_) => const StickerStudioScreen(),
        '/dice': (_) => const DiceScreen(),
        '/login': (_) => const LoginScreen(),
        '/send': (_) => const AppShell(initialTab: AppTab.send),
        '/about': (_) => const StaticScreen(keyOf: 'about'),
        '/faq': (_) => const StaticScreen(keyOf: 'faq'),
        '/privacy': (_) => const StaticScreen(keyOf: 'privacy'),
        '/terms': (_) => const StaticScreen(keyOf: 'terms'),
        '/safety': (_) => const StaticScreen(keyOf: 'safety'),
      },
        );
      },
    );
  }
}

/// Shown for the moment it takes to read the stored session.
class _Booting extends StatelessWidget {
  const _Booting();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      body: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accentFaint),
        ),
      ),
    );
  }
}
