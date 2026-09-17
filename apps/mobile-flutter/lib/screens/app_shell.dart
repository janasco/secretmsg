import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/notch_nav_bar.dart';
import 'dice_screen.dart';
import 'inbox_screen.dart';
import 'send_screen.dart';
import 'settings_screen.dart';
import 'sticker_studio_screen.dart';

enum AppTab { inbox, send, dice, stickers, settings }

/// Exposes the shell to the screens inside it, so a tab can hand off to a
/// sibling by switching tabs rather than pushing a second copy of it onto the
/// navigation stack.
///
/// [maybeOf] returns null when a screen is used on its own — an addressed
/// composer opened from a shared link, for example — so callers should keep a
/// push as their fallback.
class AppShellScope extends InheritedWidget {
  final void Function(AppTab tab) switchTo;

  const AppShellScope({
    super.key,
    required this.switchTo,
    required super.child,
  });

  static AppShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) => false;
}

/// The signed-in home of the app: inbox, composer, supporters and settings,
/// each reachable in one tap.
class AppShell extends StatefulWidget {
  final AppTab initialTab;
  const AppShell({super.key, this.initialTab = AppTab.inbox});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late AppTab _tab = widget.initialTab;

  /// A tab is only constructed once it has been opened, so a cold start does
  /// not fire four screens' worth of network calls at once. After that the
  /// IndexedStack keeps it mounted, preserving scroll position and any
  /// half-written message when switching away and back.
  late final Set<AppTab> _visited = <AppTab>{widget.initialTab};

  void _switchTo(AppTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  Widget _screenFor(AppTab tab) {
    switch (tab) {
      case AppTab.inbox:
        return const InboxScreen();
      case AppTab.send:
        return const SendScreen();
      case AppTab.dice:
        return const DiceScreen();
      case AppTab.stickers:
        return const StickerStudioScreen();
      case AppTab.settings:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    const order = AppTab.values;
    final index = order.indexOf(_tab);

    return AppShellScope(
      switchTo: _switchTo,
      child: PopScope(
        // Back from a secondary tab returns to the inbox instead of closing
        // the app, which is what Android users expect from a tab bar.
        canPop: _tab == AppTab.inbox,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _switchTo(AppTab.inbox);
        },
        child: Scaffold(
          backgroundColor: context.colors.bg,
          body: IndexedStack(
            index: index,
            children: [
              for (final tab in order)
                if (_visited.contains(tab)) _screenFor(tab) else const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NotchNavBar(
            selectedIndex: index,
            onTap: (i) => _switchTo(order[i]),
            destinations: const [
              NotchDestination(
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox,
                label: 'Inbox',
              ),
              NotchDestination(
                icon: Icons.edit_outlined,
                selectedIcon: Icons.edit,
                label: 'Send',
              ),
              NotchDestination(
                icon: Icons.casino_outlined,
                selectedIcon: Icons.casino,
                label: 'Dice',
              ),
              NotchDestination(
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                label: 'Stickers',
              ),
              NotchDestination(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'My Link',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
