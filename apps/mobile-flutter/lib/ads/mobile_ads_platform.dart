library;

import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads_config.dart';
import 'ads_platform.dart';

class MobileAdsPlatform implements AdsPlatform {
  BannerAd? _banner;

  @override
  Future<void> initialize() async {
    // The Gradle release guard already makes this unreachable in a shipped
    // artifact; keep the runtime check so a misconfigured build fails closed
    // rather than initializing the SDK with unusable identifiers.
    if (!adsIdsConfigured) {
      throw StateError('AdMob identifiers are not configured for this build.');
    }
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          maxAdContentRating: MaxAdContentRating.pg,
          ageRestrictedTreatment: AgeRestrictedTreatment.teen,
        ),
      );
    } catch (_) {}
    try {
      await MobileAds.instance.initialize();
    } catch (_) {}
  }

  @override
  Future<AdsConsentState> gatherConsent() async {
    final consent = ConsentInformation.instance;
    final update = Completer<void>();
    try {
      consent.requestConsentInfoUpdate(
        ConsentRequestParameters(tagForUnderAgeOfConsent: false),
        update.complete,
        (_) {
          if (!update.isCompleted) update.complete();
        },
      );
    } catch (_) {
      return AdsConsentState.unavailable;
    }
    try {
      await update.future.timeout(const Duration(seconds: 15));
    } catch (_) {
      return AdsConsentState.unavailable;
    }

    ConsentStatus status = ConsentStatus.unknown;
    try {
      status = await consent.getConsentStatus();
    } catch (_) {
      return AdsConsentState.unavailable;
    }

    if (status == ConsentStatus.required) {
      var available = false;
      try {
        available = await consent.isConsentFormAvailable();
      } catch (_) {
        available = false;
      }
      if (available) {
        final shown = Completer<void>();
        try {
          unawaited(ConsentForm.loadAndShowConsentFormIfRequired((_) {
            if (!shown.isCompleted) shown.complete();
          }));
        } catch (_) {}
        try {
          await shown.future.timeout(const Duration(seconds: 120));
        } catch (_) {}
        try {
          status = await consent.getConsentStatus();
        } catch (_) {}
      }
    }

    var canRequestAds = false;
    try {
      canRequestAds = await consent.canRequestAds();
    } catch (_) {}

    if (status == ConsentStatus.obtained && canRequestAds) {
      return AdsConsentState.obtained;
    }
    if (status == ConsentStatus.notRequired && canRequestAds) {
      return AdsConsentState.notRequired;
    }
    if (canRequestAds) return AdsConsentState.notRequired;
    return AdsConsentState.denied;
  }

  @override
  Future<PrivacyOptionsRequirement> privacyOptionsRequirement() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      switch (status) {
        case PrivacyOptionsRequirementStatus.required:
          return PrivacyOptionsRequirement.required;
        case PrivacyOptionsRequirementStatus.notRequired:
          return PrivacyOptionsRequirement.notRequired;
        case PrivacyOptionsRequirementStatus.unknown:
          return PrivacyOptionsRequirement.unknown;
      }
    } catch (_) {}
    return PrivacyOptionsRequirement.unknown;
  }

  @override
  Future<PrivacyOptionsOutcome> showPrivacyOptions() async {
    // The SDK reports an error rather than throwing when no form is available,
    // so treat that as "nothing to show" rather than an error. Callers gate the
    // entry point on privacyOptionsRequirement, so this is a fallback.
    final errors = <Object?>[];
    try {
      final done = Completer<void>();
      try {
        unawaited(ConsentForm.showPrivacyOptionsForm((error) {
          if (error != null) errors.add(error);
          if (!done.isCompleted) done.complete();
        }));
      } catch (_) {
        return PrivacyOptionsOutcome.unavailable;
      }
      try {
        await done.future.timeout(const Duration(seconds: 120));
      } catch (_) {
        return PrivacyOptionsOutcome.failed;
      }
      if (errors.isNotEmpty) return PrivacyOptionsOutcome.unavailable;
      return PrivacyOptionsOutcome.completed;
    } catch (_) {
      return PrivacyOptionsOutcome.failed;
    }
  }

  @override
  Future<RewardedOutcome> showRewarded(AdsRequest request) async {
    final outcome = Completer<RewardedOutcome>();
    try {
      await RewardedAd.load(
        adUnitId: request.adUnitId,
        request: AdRequest(
          keywords: const <String>[],
          nonPersonalizedAds: request.policy.nonPersonalised,
        ),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) async {
            var earned = false;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (dismissed) async {
                await dismissed.dispose();
                if (!outcome.isCompleted) {
                  outcome.complete(
                      earned ? RewardedOutcome.earned : RewardedOutcome.skipped);
                }
              },
              onAdFailedToShowFullScreenContent: (failed, _) async {
                await failed.dispose();
                if (!outcome.isCompleted) {
                  outcome.complete(RewardedOutcome.failed);
                }
              },
            );
            try {
              await ad.show(
                onUserEarnedReward: (_, __) => earned = true,
              );
            } catch (_) {
              await ad.dispose();
              if (!outcome.isCompleted) {
                outcome.complete(RewardedOutcome.failed);
              }
            }
          },
          onAdFailedToLoad: (error) {
            if (!outcome.isCompleted) outcome.complete(RewardedOutcome.noFill);
          },
        ),
      );
    } catch (_) {
      if (!outcome.isCompleted) outcome.complete(RewardedOutcome.failed);
    }
    return outcome.future.timeout(
      const Duration(seconds: 90),
      onTimeout: () => RewardedOutcome.failed,
    );
  }

  @override
  Future<bool> loadBanner(AdsRequest request) async {
    clearBanner();
    final loaded = Completer<bool>();
    final size = await _bannerSize();
    if (size == null) return false;
    final banner = BannerAd(
      adUnitId: request.adUnitId,
      size: size,
      request: AdRequest(
        keywords: const <String>[],
        nonPersonalizedAds: request.policy.nonPersonalised,
      ),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _banner = ad as BannerAd;
          if (!loaded.isCompleted) loaded.complete(true);
        },
        onAdFailedToLoad: (ad, _) {
          if (!loaded.isCompleted) loaded.complete(false);
        },
      ),
    );
    try {
      await banner.load();
    } catch (_) {
      if (!loaded.isCompleted) loaded.complete(false);
    }
    return loaded.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () => false,
    );
  }

  /// The slot to request: an anchored adaptive banner clamped to
  /// [kMaxBannerHeight].
  ///
  /// The banner is pinned above the navigation bar, which is the anchored case
  /// adaptive banners are designed for. Google's guidance is that adaptive
  /// supersedes fixed 320x50 and earns materially more per impression, so a
  /// fixed size would leave most of that on the table.
  ///
  /// The unclamped anchored height reaches 150dp or 20% of the screen, whichever
  /// is smaller. That is too much to hand to a messaging surface which also
  /// holds a compose field, so the height is capped while the width stays at
  /// screen width, which keeps eligible demand unrestricted and the layout
  /// stable.
  Future<AdSize?> _bannerSize() async {
    int width;
    try {
      final view = PlatformDispatcher.instance.views.first;
      width = (view.physicalSize.width / view.devicePixelRatio).floor();
    } catch (_) {
      return null;
    }
    if (width <= 0) return null;

    // Auto-detects orientation, so no BuildContext is needed and a rotation
    // reloads the slot for the new width rather than keeping a stale one.
    final AnchoredAdaptiveBannerAdSize? adaptive;
    try {
      adaptive = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    } catch (_) {
      return null;
    }
    if (adaptive == null) return null;
    if (adaptive.width <= 0 || adaptive.height <= 0) return null;
    if (adaptive.height <= kMaxBannerHeightInt) return adaptive;
    return AdSize(width: adaptive.width, height: kMaxBannerHeightInt);
  }

  @override
  void clearBanner() {
    final banner = _banner;
    _banner = null;
    if (banner == null) return;
    unawaited(banner.dispose().catchError((Object _) {}));
  }

  @override
  Widget? buildBanner(BuildContext context) {
    final banner = _banner;
    if (banner == null) return null;
    // Size from the loaded creative rather than a hardcoded height, so the slot
    // matches whatever was actually served. A 320x50 creative in a 60dp slot is
    // centred with padding; a taller one fills it.
    final height = banner.size.height.toDouble();
    return SizedBox(
      height: height > 0 ? height : kMaxBannerHeight,
      width: double.infinity,
      child: Center(child: AdWidget(ad: banner)),
    );
  }

  @override
  Future<void> release() async {
    clearBanner();
  }
}
