library;

import 'dart:async';

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
    final banner = BannerAd(
      adUnitId: request.adUnitId,
      size: AdSize.banner,
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
    return SizedBox(
      height: kBannerHeight,
      width: double.infinity,
      child: Center(child: AdWidget(ad: banner)),
    );
  }

  @override
  Future<void> release() async {
    clearBanner();
  }
}
