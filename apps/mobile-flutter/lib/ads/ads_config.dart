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

/// AdMob uses two different identifier formats, and conflating them is a common
/// mistake: an **app id** is `ca-app-pub-<16 digits>~<digits>` (tilde) and goes in
/// the manifest, while an **ad unit id** is `ca-app-pub-<16 digits>/<digits>`
/// (slash) and goes in ad requests. Putting an ad unit id in the manifest makes
/// the SDK reject the app id, and vice versa.
final RegExp _adMobAppIdPattern = RegExp(r'^ca-app-pub-(\d{16})~\d{6,16}$');
final RegExp _adUnitIdPattern = RegExp(r'^ca-app-pub-(\d{16})/\d{6,16}$');

bool _isPlaceholder(String value) => value.contains('0000000000000000');

/// True for a well-formed, non-placeholder AdMob **app** id (`~` form).
bool isRealAdMobAppId(String value) =>
    _adMobAppIdPattern.hasMatch(value) && !_isPlaceholder(value);

/// True for a well-formed, non-placeholder **ad unit** id (`/` form).
bool isRealAdUnitId(String value) =>
    _adUnitIdPattern.hasMatch(value) && !_isPlaceholder(value);

/// The publisher id embedded in either identifier form, or null if malformed.
///
/// All three identifiers must come from the same AdMob account. Pasting an ad
/// unit belonging to a different account produces a build that serves no ads
/// with no error, so the mismatch is rejected instead.
String? adMobPublisherId(String value) {
  if (_isPlaceholder(value)) return null;
  final match = _adMobAppIdPattern.firstMatch(value) ??
      _adUnitIdPattern.firstMatch(value);
  return match?.group(1);
}

/// True when the app id and both ad unit ids belong to one AdMob account.
bool get adIdsSharePublisher {
  final publishers = [
    adMobPublisherId(kAdMobAppId),
    adMobPublisherId(kBannerAdUnitId),
    adMobPublisherId(kRewardedAdUnitId),
  ];
  return !publishers.contains(null) && publishers.toSet().length == 1;
}

/// True when every AdMob identifier is a real value rather than a placeholder,
/// uses the correct format for its slot, and comes from the same account.
bool get adsIdsConfigured =>
    isRealAdMobAppId(kAdMobAppId) &&
    isRealAdUnitId(kBannerAdUnitId) &&
    isRealAdUnitId(kRewardedAdUnitId) &&
    adIdsSharePublisher;

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
