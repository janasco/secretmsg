import 'package:flutter_test/flutter_test.dart';

import 'package:secretmsg_mobile/main.dart';
import 'package:secretmsg_mobile/screens/app_shell.dart';
import 'package:secretmsg_mobile/screens/dice_screen.dart';
import 'package:secretmsg_mobile/screens/landing_screen.dart';
import 'package:secretmsg_mobile/screens/send_screen.dart';
import 'package:secretmsg_mobile/screens/static_screen.dart';
import 'package:secretmsg_mobile/screens/supporters_screen.dart';

void main() {
  group('document pages are not mistaken for board handles', () {
    // The website serves its legal and safety documents under /p/ and /legal/.
    // Before this was handled, every one of these opened a compose screen
    // addressed to a user called "p" or "legal".
    const documentUrls = <String, String>{
      'https://secretmsg.net/p/privacy': 'privacy',
      'https://secretmsg.net/p/terms': 'terms',
      'https://secretmsg.net/p/cookies': 'cookies',
      'https://secretmsg.net/p/disclaimer': 'disclaimer',
      'https://secretmsg.net/p/legal/terms': 'terms',
      'https://secretmsg.net/p/legal/privacy': 'privacy',
      'https://secretmsg.net/legal/privacy': 'privacy',
      'https://secretmsg.net/legal/disclaimer': 'disclaimer',
      'https://secretmsg.net/p/safety': 'safety',
      'https://secretmsg.net/p/safety-tools': 'safety-tools',
      'https://secretmsg.net/p/community-guidelines': 'community-guidelines',
      'https://secretmsg.net/p/approach-to-safety': 'approach-to-safety',
      'https://secretmsg.net/p/child-safety-policy': 'child-safety',
      'https://secretmsg.net/p/guide-to-online-safety': 'online-safety-guide',
      'https://secretmsg.net/p/resources': 'safety-resources',
      'https://secretmsg.net/p/contact-us': 'contact',
      'https://secretmsg.net/about': 'about',
      'https://secretmsg.net/faq': 'faq',
    };

    documentUrls.forEach((url, expectedKey) {
      test(url, () {
        final screen = DeepLinkRouter.routeFor(url);
        expect(screen, isA<StaticScreen>(), reason: '$url must not open a composer');
        expect((screen as StaticScreen).keyOf, expectedKey);
      });
    });
  });

  group('owner routes land in the tab shell', () {
    void expectsTab(String url, AppTab tab) {
      final screen = DeepLinkRouter.routeFor(url);
      expect(screen, isA<AppShell>(), reason: '$url should open the shell');
      expect((screen as AppShell).initialTab, tab);
    }

    test('inbox', () => expectsTab('https://secretmsg.net/inbox', AppTab.inbox));
    test('inbox on the app subdomain', () => expectsTab('https://app.secretmsg.net/inbox', AppTab.inbox));
    test('settings', () => expectsTab('https://secretmsg.net/settings', AppTab.settings));
    test('bare /send is the composer tab', () => expectsTab('https://secretmsg.net/send', AppTab.send));
  });

  group('standalone screens', () {
    test('dice', () => expect(DeepLinkRouter.routeFor('https://secretmsg.net/dice'), isA<DiceScreen>()));
    test('supporters', () => expect(DeepLinkRouter.routeFor('https://secretmsg.net/supporters'), isA<SupportersScreen>()));
    test('donors alias', () => expect(DeepLinkRouter.routeFor('https://secretmsg.net/donors'), isA<SupportersScreen>()));
  });

  group('board handles still reach the composer', () {
    // An addressed link is opened by a stranger who has no inbox of their own,
    // so it stays a standalone screen rather than a tab.
    test('bare handle', () {
      final screen = DeepLinkRouter.routeFor('https://secretmsg.net/janasco');
      expect(screen, isA<SendScreen>());
      expect((screen as SendScreen).initialUsername, 'janasco');
    });

    test('handle casing is preserved for the composer field', () {
      final screen = DeepLinkRouter.routeFor('https://secretmsg.net/Janasco');
      expect((screen as SendScreen).initialUsername, 'Janasco');
    });

    test('www is accepted', () {
      final screen = DeepLinkRouter.routeFor('https://www.secretmsg.net/janasco');
      expect(screen, isA<SendScreen>());
      expect((screen as SendScreen).initialUsername, 'janasco');
    });

    test('explicit /send/<user>', () {
      final screen = DeepLinkRouter.routeFor('https://secretmsg.net/send/janasco');
      expect(screen, isA<SendScreen>());
      expect((screen as SendScreen).initialUsername, 'janasco');
    });
  });

  group('falls back to landing', () {
    test('cold launch route', () => expect(DeepLinkRouter.routeFor('/'), isA<LandingScreen>()));
    test('empty string', () => expect(DeepLinkRouter.routeFor(''), isA<LandingScreen>()));
    test('foreign host is never trusted',
        () => expect(DeepLinkRouter.routeFor('https://evil.example/janasco'), isA<LandingScreen>()));
    test('a lookalike domain is not ours',
        () => expect(DeepLinkRouter.routeFor('https://notsecretmsg.net/janasco'), isA<LandingScreen>()));
    test('blind reply is web-only',
        () => expect(DeepLinkRouter.routeFor('https://secretmsg.net/reply/abc123'), isA<LandingScreen>()));
  });
}
