import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'widgets/bottom_nav.dart';
import 'screens/home_screen.dart';
import 'screens/dice_screen.dart';
import 'screens/sticker_studio_screen.dart';
import 'screens/inbox_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SecretMsgApp());
}

class SecretMsgApp extends StatelessWidget {
  const SecretMsgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SecretMsg',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SecretMainScaffold(),
    );
  }
}

class SecretMainScaffold extends StatefulWidget {
  const SecretMainScaffold({super.key});

  @override
  State<SecretMainScaffold> createState() => _SecretMainScaffoldState();
}

class _SecretMainScaffoldState extends State<SecretMainScaffold> {
  int _currentTab = 0;

  void _onTabSelected(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          HomeScreen(onNavigateTab: _onTabSelected),
          const DiceScreen(),
          const StickerStudioScreen(),
          const InboxScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SecretBottomNav(
        currentIndex: _currentTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
