library;

const String kAdMobAppIdPlaceholder = 'ca-app-pub-0000000000000000';
const String kBannerAdUnitIdPlaceholder =
    'ca-app-pub-0000000000000000/0000000000000000';
const String kRewardedAdUnitIdPlaceholder =
    'ca-app-pub-0000000000000000/0000000000000000';
const String kAdsFlagsKey = 'ads_enabled';
const String kAdsFlagsFetchedAtKey = 'ads_enabled_fetched_at';
const Duration kAdsFlagsMaxAge = Duration(hours: 6);
const bool kAdsEnabledWithoutServerFlag = false;
const int kMaxStreakFreezes = 1;
const double kBannerHeight = 50;

enum AdsConsentState { unknown, notRequired, obtained, denied, unavailable }

enum AdsSlotState { empty, loading, ready, failed }

enum RewardedOutcome { earned, skipped, noFill, failed, unavailable }

class AdsRequestPolicy {
  final bool nonPersonalised;
  final bool childDirected;
  final bool underAgeOfConsent;

  const AdsRequestPolicy({
    required this.nonPersonalised,
    required this.childDirected,
    required this.underAgeOfConsent,
  });

  factory AdsRequestPolicy.forConsent(AdsConsentState consent) =>
      AdsRequestPolicy(
        nonPersonalised: consent != AdsConsentState.obtained,
        childDirected: false,
        underAgeOfConsent: false,
      );
}

class AdsRequest {
  final String adUnitId;
  final AdsRequestPolicy policy;

  const AdsRequest({required this.adUnitId, required this.policy});
}

bool canServeAds({
  required bool adFree,
  required bool ready,
  required bool remoteEnabled,
  required AdsConsentState consent,
  required bool suppressed,
}) {
  if (adFree) return false;
  if (suppressed) return false;
  if (!ready) return false;
  if (!remoteEnabled) return false;
  if (consent == AdsConsentState.unknown) return false;
  if (consent == AdsConsentState.unavailable) return false;
  return true;
}

bool canOfferStreakFreezeByAd({
  required bool adsEnabled,
  required int streakCount,
  required int freezes,
  int maxFreezes = kMaxStreakFreezes,
}) {
  if (!adsEnabled) return false;
  if (streakCount < 1) return false;
  if (freezes >= maxFreezes) return false;
  return true;
}
