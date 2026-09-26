import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:secretmsg_mobile/ads/ads_banner.dart';
import 'package:secretmsg_mobile/ads/ads_config.dart';
import 'package:secretmsg_mobile/ads/ads_flags.dart';
import 'package:secretmsg_mobile/ads/ads_platform.dart';
import 'package:secretmsg_mobile/ads/ads_service.dart';
import 'package:secretmsg_mobile/api/models.dart';
import 'package:secretmsg_mobile/ritual/streak_store.dart';
import 'package:secretmsg_mobile/theme.dart';
import 'package:secretmsg_mobile/widgets/notch_nav_bar.dart';

import 'secure_storage_mock.dart';

class FakeAdsPlatform implements AdsPlatform {
  int initializeCalls = 0;
  int consentCalls = 0;
  int bannerLoadCalls = 0;
  int bannerClearCalls = 0;
  int rewardedCalls = 0;

  AdsConsentState consent = AdsConsentState.notRequired;
  PrivacyOptionsRequirement privacyRequirement = PrivacyOptionsRequirement.notRequired;
  PrivacyOptionsOutcome privacyOutcome = PrivacyOptionsOutcome.completed;
  Object? throwOnPrivacyOptions;
  int privacyRequirementCalls = 0;
  int privacyOptionCalls = 0;
  bool bannerFill = true;
  RewardedOutcome outcome = RewardedOutcome.earned;
  Object? throwOnRewarded;
  Object? throwOnBannerLoad;

  final List<AdsRequest> bannerRequests = <AdsRequest>[];
  final List<AdsRequest> rewardedRequests = <AdsRequest>[];

  @override
  Future<void> initialize() async {
    initializeCalls++;
  }

  @override
  Future<AdsConsentState> gatherConsent() async {
    consentCalls++;
    return consent;
  }

  @override
  Future<PrivacyOptionsRequirement> privacyOptionsRequirement() async {
    privacyRequirementCalls++;
    if (throwOnPrivacyOptions != null) throw throwOnPrivacyOptions!;
    return privacyRequirement;
  }

  @override
  Future<PrivacyOptionsOutcome> showPrivacyOptions() async {
    privacyOptionCalls++;
    if (throwOnPrivacyOptions != null) throw throwOnPrivacyOptions!;
    return privacyOutcome;
  }

  @override
  Future<bool> loadBanner(AdsRequest request) async {
    bannerLoadCalls++;
    bannerRequests.add(request);
    if (throwOnBannerLoad != null) throw throwOnBannerLoad!;
    return bannerFill;
  }

  @override
  Future<RewardedOutcome> showRewarded(AdsRequest request) async {
    rewardedCalls++;
    rewardedRequests.add(request);
    if (throwOnRewarded != null) throw throwOnRewarded!;
    return outcome;
  }

  @override
  void clearBanner() {
    bannerClearCalls++;
  }

  @override
  Widget? buildBanner(BuildContext context) =>
      const SizedBox(height: kMaxBannerHeight, child: Text('ad'));

  @override
  Future<void> release() async {
    clearBanner();
  }
}

const UserProfile _supporter = UserProfile(
  id: 'u1',
  username: 'ada',
  displayName: 'Ada',
  isPremium: 1,
);

const UserProfile _free = UserProfile(
  id: 'u1',
  username: 'ada',
  displayName: 'Ada',
);

const NotchDestination _dest = NotchDestination(
  icon: Icons.inbox_outlined,
  selectedIcon: Icons.inbox,
  label: 'Inbox',
);

void _noop(int _) {}

AdsService _build({FakeAdsPlatform? platform, bool flag = true}) {
  return AdsService(
    platform: platform ?? FakeAdsPlatform(),
    flags: AdsFlagResolver(
      fetcher: () async => flag,
      clock: () => DateTime(2026, 9, 26),
    ),
  );
}

Future<void> _pumpShell(WidgetTester tester, AdsService service) async {
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.dark(),
    home: Scaffold(
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdsBanner(service: service),
          const NotchNavBar(
            selectedIndex: 0,
            onTap: _noop,
            destinations: [_dest],
          ),
        ],
      ),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStoredToken(null);
  });

  tearDown(clearStoredTokenMock);

  group('request policy', () {
    test('every request is tagged as not child-directed and not under age',
        () {
      for (final state in AdsConsentState.values) {
        final policy = AdsRequestPolicy.forConsent(state);
        expect(policy.childDirected, isFalse, reason: '$state');
        expect(policy.underAgeOfConsent, isFalse, reason: '$state');
      }
    });

    test('only explicit UMP consent permits personalised requests', () {
      expect(
        AdsRequestPolicy.forConsent(AdsConsentState.obtained).nonPersonalised,
        isFalse,
      );
      for (final state in [
        AdsConsentState.denied,
        AdsConsentState.notRequired,
        AdsConsentState.unknown,
        AdsConsentState.unavailable,
      ]) {
        expect(
          AdsRequestPolicy.forConsent(state).nonPersonalised,
          isTrue,
          reason: '$state',
        );
      }
    });
  });

  group('canServeAds', () {
    test('an ad-free account never serves ads', () {
      expect(
        canServeAds(
          adFree: true,
          ready: true,
          remoteEnabled: true,
          consent: AdsConsentState.obtained,
          suppressed: false,
        ),
        isFalse,
      );
    });

    test('the kill-switch turns ads off', () {
      expect(
        canServeAds(
          adFree: false,
          ready: true,
          remoteEnabled: false,
          consent: AdsConsentState.obtained,
          suppressed: false,
        ),
        isFalse,
      );
    });

    test('no ad is served while consent is unknown or unavailable', () {
      for (final state in [
        AdsConsentState.unknown,
        AdsConsentState.unavailable,
      ]) {
        expect(
          canServeAds(
            adFree: false,
            ready: true,
            remoteEnabled: true,
            consent: state,
            suppressed: false,
          ),
          isFalse,
          reason: '$state',
        );
      }
    });

    test('a suppressed surface serves nothing', () {
      expect(
        canServeAds(
          adFree: false,
          ready: true,
          remoteEnabled: true,
          consent: AdsConsentState.obtained,
          suppressed: true,
        ),
        isFalse,
      );
    });

    test('denied consent still serves non-personalised ads', () {
      expect(
        canServeAds(
          adFree: false,
          ready: true,
          remoteEnabled: true,
          consent: AdsConsentState.denied,
          suppressed: false,
        ),
        isTrue,
      );
    });
  });

  group('ad-free entitlement', () {
    test('a supporter initialises nothing and requests nothing', () async {
      final platform = FakeAdsPlatform();
      final service = _build(platform: platform);
      service.applyProfile(_supporter);
      await service.init();

      expect(service.isAdFree, isTrue);
      expect(service.isEnabled, isFalse);
      expect(platform.initializeCalls, 0);
      expect(platform.consentCalls, 0);

      await service.loadBanner();
      expect(platform.bannerLoadCalls, 0);
      expect(service.bannerState, AdsSlotState.empty);

      expect(
        await service.showRewardedForStreakFreeze(),
        RewardedOutcome.unavailable,
      );
      expect(platform.rewardedCalls, 0);
    });

    test('losing the entitlement re-opens the gate for the next init',
        () async {
      final service = _build();
      service.applyProfile(_supporter);
      await service.init();
      expect(service.isEnabled, isFalse);

      service.applyProfile(_free);
      expect(service.isAdFree, isFalse);
    });
  });

  group('kill-switch', () {
    test('a disabled flag means the platform is never touched', () async {
      final platform = FakeAdsPlatform();
      final service = _build(platform: platform, flag: false);
      await service.init();

      expect(service.remoteEnabled, isFalse);
      expect(service.isEnabled, isFalse);
      expect(platform.initializeCalls, 0);
      expect(platform.consentCalls, 0);

      await service.loadBanner();
      expect(platform.bannerLoadCalls, 0);
      expect(
        await service.showRewardedForStreakFreeze(),
        RewardedOutcome.unavailable,
      );
      expect(platform.rewardedCalls, 0);
    });

    test('a fetch failure falls back to the cached value', () async {
      SharedPreferences.setMockInitialValues({
        'ads_enabled': true,
        'ads_enabled_fetched_at': DateTime(2026, 9, 26).millisecondsSinceEpoch,
      });
      final service = AdsService(
        platform: FakeAdsPlatform(),
        flags: AdsFlagResolver(
          fetcher: () async => null,
          clock: () => DateTime(2026, 9, 26),
        ),
      );
      await service.init();
      expect(service.remoteEnabled, isTrue);
    });

    test('a throwing fetch with no cache resolves to ads off', () async {
      final resolver = AdsFlagResolver(
        fetcher: () async => throw Exception('offline'),
        clock: () => DateTime(2026, 9, 26),
      );
      expect(await resolver.resolve(), isFalse);
    });

    test('a fresh server value replaces a stale cached one', () async {
      SharedPreferences.setMockInitialValues({
        'ads_enabled': true,
        'ads_enabled_fetched_at': DateTime(2026, 9, 20).millisecondsSinceEpoch,
      });
      final resolver = AdsFlagResolver(
        fetcher: () async => false,
        clock: () => DateTime(2026, 9, 26),
      );
      expect(await resolver.resolve(), isFalse);
      expect((await AdsFlagCache.read())?.enabled, isFalse);
    });

    test('the served flag is cached for the next cold start', () async {
      final resolver = AdsFlagResolver(
        fetcher: () async => true,
        clock: () => DateTime(2026, 9, 26),
      );
      expect(await resolver.resolve(), isTrue);
      expect((await AdsFlagCache.read())?.enabled, isTrue);
    });
  });

  group('consent', () {
    test('denied consent falls back to non-personalised requests', () async {
      final platform = FakeAdsPlatform()..consent = AdsConsentState.denied;
      final service = _build(platform: platform);
      await service.init();

      expect(service.consent, AdsConsentState.denied);
      expect(service.canRequestPersonalised, isFalse);
      expect(service.isEnabled, isTrue);

      await service.loadBanner();
      final banner = platform.bannerRequests.single;
      expect(banner.policy.nonPersonalised, isTrue);
      expect(banner.policy.childDirected, isFalse);
      expect(banner.policy.underAgeOfConsent, isFalse);

      await service.showRewardedForStreakFreeze();
      final rewarded = platform.rewardedRequests.single;
      expect(rewarded.policy.nonPersonalised, isTrue);
      expect(rewarded.policy.childDirected, isFalse);
      expect(rewarded.policy.underAgeOfConsent, isFalse);
    });

    test('granted consent permits personalised requests', () async {
      final platform = FakeAdsPlatform()..consent = AdsConsentState.obtained;
      final service = _build(platform: platform);
      await service.init();

      await service.showRewardedForStreakFreeze();
      expect(platform.rewardedRequests.single.policy.nonPersonalised, isFalse);
    });

    test('no ad is requested before consent has been gathered', () async {
      final platform = FakeAdsPlatform();
      final service = _build(platform: platform);
      expect(service.isEnabled, isFalse);

      await service.loadBanner();
      expect(platform.bannerLoadCalls, 0);
      expect(
        await service.showRewardedForStreakFreeze(),
        RewardedOutcome.unavailable,
      );
      expect(platform.rewardedCalls, 0);
    });
  });

  group('empty and failing ads', () {
    test('an absent banner fill degrades to no ad without throwing',
        () async {
      final platform = FakeAdsPlatform()..bannerFill = false;
      final service = _build(platform: platform);
      await service.init();
      await service.loadBanner();

      expect(service.bannerState, AdsSlotState.failed);
    });

    test('a banner load that throws is swallowed', () async {
      final platform = FakeAdsPlatform()
        ..throwOnBannerLoad = StateError('no activity');
      final service = _build(platform: platform);
      await service.init();
      await service.loadBanner();

      expect(service.bannerState, AdsSlotState.failed);
    });

    test('a rewarded ad with no fill reports noFill, not an error', () async {
      final platform = FakeAdsPlatform()..outcome = RewardedOutcome.noFill;
      final service = _build(platform: platform);
      await service.init();
      expect(
        await service.showRewardedForStreakFreeze(),
        RewardedOutcome.noFill,
      );
    });

    test('a rewarded ad that throws becomes a failed outcome', () async {
      final platform = FakeAdsPlatform()
        ..throwOnRewarded = StateError('no activity');
      final service = _build(platform: platform);
      await service.init();
      expect(
        await service.showRewardedForStreakFreeze(),
        RewardedOutcome.failed,
      );
    });

    test('a skipped rewarded ad earns nothing', () async {
      final platform = FakeAdsPlatform()..outcome = RewardedOutcome.skipped;
      final service = _build(platform: platform);
      await service.init();
      expect(
        await service.showRewardedForStreakFreeze(),
        RewardedOutcome.skipped,
      );
    });

    test('a second request while one is in flight is dropped', () async {
      final platform = FakeAdsPlatform();
      final service = _build(platform: platform);
      await service.init();
      final first = service.showRewardedForStreakFreeze();
      final second = await service.showRewardedForStreakFreeze();
      expect(second, RewardedOutcome.unavailable);
      expect(await first, RewardedOutcome.earned);
      expect(platform.rewardedCalls, 1);
    });
  });

  group('suppressed surfaces', () {
    test('suppression is idempotent per reason and additive across reasons',
        () {
      final service = _build();
      service.suppress('a');
      service.suppress('a');
      service.unsuppress('a');
      expect(service.isSuppressed, isFalse);

      service.suppress('moderation');
      service.suppress('report');
      service.unsuppress('moderation');
      expect(service.isSuppressed, isTrue);
      service.unsuppress('report');
      expect(service.isSuppressed, isFalse);
    });

    test('clearing suppressions restores the gate', () {
      final service = _build();
      service.suppress('moderation');
      service.suppress('report');
      service.clearSuppressions();
      expect(service.isSuppressed, isFalse);
    });
  });

  group('streak freeze offer', () {
    test('offered only when a streak is at risk and under the cap', () {
      expect(
        canOfferStreakFreezeByAd(
          adsEnabled: true,
          streakCount: 4,
          freezes: 0,
        ),
        isTrue,
      );
      expect(
        canOfferStreakFreezeByAd(
          adsEnabled: true,
          streakCount: 4,
          freezes: 1,
        ),
        isFalse,
      );
      expect(
        canOfferStreakFreezeByAd(
          adsEnabled: true,
          streakCount: 0,
          freezes: 0,
        ),
        isFalse,
      );
      expect(
        canOfferStreakFreezeByAd(
          adsEnabled: false,
          streakCount: 4,
          freezes: 0,
        ),
        isFalse,
      );
    });

    test('an ad-bought freeze is persisted and shares the cap', () async {
      SharedPreferences.setMockInitialValues({
        'streak_count': 9,
        'streak_last_day': '2026-09-26',
        'streak_freezes': 0,
      });
      final first = await StreakStore.grantFreeze();
      expect(first.earned, isTrue);
      expect(first.state.freezes, 1);
      expect(first.state.count, 9);

      final second = await StreakStore.grantFreeze();
      expect(second.earned, isFalse);
      expect(second.state.freezes, 1);
    });
  });

  group('banner widget', () {
    testWidgets('renders nothing and loads nothing while the flag is off',
        (tester) async {
      final platform = FakeAdsPlatform();
      final service = _build(platform: platform, flag: false);
      await service.init();

      await _pumpShell(tester, service);

      expect(find.text('ad'), findsNothing);
      expect(platform.bannerLoadCalls, 0);
      expect(find.byType(NotchNavBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the ad above the nav bar once loaded', (tester) async {
      final platform = FakeAdsPlatform();
      final service = _build(platform: platform);
      await service.init();

      await _pumpShell(tester, service);

      expect(platform.bannerLoadCalls, 1);
      expect(find.text('ad'), findsOneWidget);

      final navY = tester.getTopLeft(find.byType(NotchNavBar)).dy;
      final adY = tester.getTopLeft(find.text('ad')).dy;
      expect(adY, lessThan(navY));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a suppressed surface hides the loaded banner', (tester) async {
      final service = _build();
      await service.init();

      await _pumpShell(tester, service);
      expect(find.text('ad'), findsOneWidget);

      service.suppress('inbox-moderation');
      await tester.pump();
      expect(find.text('ad'), findsNothing);
      expect(find.byType(NotchNavBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      service.unsuppress('inbox-moderation');
      await tester.pump();
      expect(find.text('ad'), findsOneWidget);
    });

    testWidgets('an absent fill renders nothing and never overflows',
        (tester) async {
      final platform = FakeAdsPlatform()..bannerFill = false;
      final service = _build(platform: platform);
      await service.init();

      await _pumpShell(tester, service);

      expect(platform.bannerLoadCalls, 1);
      expect(find.text('ad'), findsNothing);
      expect(find.byType(NotchNavBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('privacy options entry point', () {
    // The service refuses the entry point whenever no ad requests are being
    // made, because there is no advertising choice to revisit in that case.
    test('is hidden when the remote flag is off', () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.required;
      final service = _build(platform: platform, flag: false);
      addTearDown(service.dispose);
      await service.init();
      expect(await service.privacyOptionsRequired(), isFalse);
    });

    test('is hidden when the SDK says it is not required', () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.notRequired;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      await service.init();
      expect(await service.privacyOptionsRequired(), isFalse);
    });

    test('is hidden when the SDK status is unknown', () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.unknown;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      await service.init();
      expect(await service.privacyOptionsRequired(), isFalse);
    });

    test('is offered when the SDK requires it', () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.required;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      await service.init();
      expect(await service.privacyOptionsRequired(), isTrue);
    });

    test('an ad-free account is never offered the entry point', () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.required;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      service.applyProfile(_supporter);
      await service.init();
      expect(service.isAdFree, isTrue);
      expect(await service.privacyOptionsRequired(), isFalse);
    });

    test('showing options re-reads consent so a withdrawal takes effect',
        () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.required
        ..consent = AdsConsentState.obtained;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      await service.init();
      expect(service.canRequestPersonalised, isTrue);
      final before = platform.consentCalls;

      // The user revokes consent in the form.
      platform.consent = AdsConsentState.denied;
      final outcome = await service.showPrivacyOptions();
      expect(outcome, PrivacyOptionsOutcome.completed);
      expect(platform.consentCalls, greaterThan(before));
      expect(service.canRequestPersonalised, isFalse);
    });

    test('does not open the form when it is not required', () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.notRequired;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      await service.init();
      final outcome = await service.showPrivacyOptions();
      expect(outcome, PrivacyOptionsOutcome.unavailable);
      expect(platform.privacyOptionCalls, 0);
    });

    test('surfaces an unavailable form rather than claiming success',
        () async {
      final platform = FakeAdsPlatform()
        ..privacyRequirement = PrivacyOptionsRequirement.required
        ..privacyOutcome = PrivacyOptionsOutcome.unavailable;
      final service = _build(platform: platform, flag: true);
      addTearDown(service.dispose);
      await service.init();
      final before = platform.consentCalls;
      expect(
        await service.showPrivacyOptions(),
        PrivacyOptionsOutcome.unavailable,
      );
      // No re-read, because nothing changed.
      expect(platform.consentCalls, before);
    });
  });

  group('AdMob build-time identifiers', () {
    // This suite runs without --dart-define, which is exactly the state a
    // release artifact must never be in. It drives the fake platform rather
    // than MobileAdsPlatform, so the default-valued constants are what a
    // misconfigured build would see.
    test('an unconfigured build reports missing identifiers', () {
      expect(kAdMobAppId, isEmpty);
      expect(kBannerAdUnitId, isEmpty);
      expect(kRewardedAdUnitId, isEmpty);
      expect(adsIdsConfigured, isFalse);
      expect(adIdsSharePublisher, isFalse);
    });

    // An app id carries a tilde; an ad unit id carries a slash. Conflating them
    // is the classic setup mistake, so each slot is checked against its own form.
    test('app ids use the tilde form', () {
      expect(
        isRealAdMobAppId('ca-app-pub-3940256099942544~3347511713'),
        isTrue,
      );
      // An ad unit id is not a valid app id.
      expect(
        isRealAdMobAppId('ca-app-pub-3940256099942544/7180472622'),
        isFalse,
      );
    });

    test('ad unit ids use the slash form', () {
      expect(
        isRealAdUnitId('ca-app-pub-3940256099942544/6300978111'),
        isTrue,
      );
      // An app id is not a valid ad unit id.
      expect(
        isRealAdUnitId('ca-app-pub-3940256099942544~3347511713'),
        isFalse,
      );
    });

    test('placeholder ids are rejected in both formats', () {
      expect(isRealAdMobAppId('ca-app-pub-0000000000000000~0000000000'), isFalse);
      expect(
        isRealAdUnitId('ca-app-pub-0000000000000000/0000000000'),
        isFalse,
      );
    });

    test('malformed ids are rejected', () {
      for (final bad in [
        '',
        'ca-app-pub-',
        '3940256099942544',
        'ca-app-pub-3940256099942544',
        'ca-app-pub-3940256099942544~',
        'ca-app-pub-3940256099942544/',
      ]) {
        expect(isRealAdMobAppId(bad), isFalse, reason: 'app: $bad');
        expect(isRealAdUnitId(bad), isFalse, reason: 'unit: $bad');
      }
    });

    test('the publisher id is recovered from either form', () {
      expect(
        adMobPublisherId('ca-app-pub-3940256099942544~3347511713'),
        '3940256099942544',
      );
      expect(
        adMobPublisherId('ca-app-pub-3940256099942544/6300978111'),
        '3940256099942544',
      );
      expect(adMobPublisherId('ca-app-pub-0000000000000000~1'), isNull);
      expect(adMobPublisherId('nonsense'), isNull);
    });
  });
}
