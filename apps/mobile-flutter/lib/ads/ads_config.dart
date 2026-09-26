library;

const String kAdsFlagsKey = 'ads_enabled';
const String kAdsFlagsFetchedAtKey = 'ads_enabled_fetched_at';
const Duration kAdsFlagsMaxAge = Duration(hours: 6);
const bool kAdsEnabledWithoutServerFlag = false;
const int kMaxStreakFreezes = 1;
const double kBannerHeight = 50;

// Ad identifiers are build-time inputs, never committed. The Gradle build
// refuses to produce a release artifact unless these are supplied as a complete
// set (see android/app/build.gradle), so a release binary can never carry a
// placeholder. See scripts/build_release.sh for the canonical invocation.
const String kAdMobAppId = String.fromEnvironment('ADMOB_APP_ID');
const String kBannerAdUnitId = String.fromEnvironment('ADMOB_BANNER_AD_UNIT_ID');
const String kRewardedAdUnitId = String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID');

/// True when every AdMob identifier is a real value rather than a placeholder.
///
/// Ad unit ids must additionally belong to [kAdMobAppId]'s app; the Gradle
/// guard enforces that pairing at build time, since it is the only layer that
/// can see both the manifest value and these defines.
bool get adsIdsConfigured =>
    isRealAdId(kAdMobAppId) &&
    isRealAdId(kBannerAdUnitId) &&
    isRealAdId(kRewardedAdUnitId);

/// Matches a well-formed AdMob app id (`ca-app-pub-` + 16 digits) or ad unit id
/// (the same, plus `/` + 10 digits).
final RegExp _adIdPattern = RegExp(r'^ca-app-pub-\d{16}(/\d{10})?$');

bool isRealAdId(String value) =>
    _adIdPattern.hasMatch(value) && !value.contains('0000000000000000');

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
