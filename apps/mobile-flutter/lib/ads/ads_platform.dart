library;

import 'package:flutter/widgets.dart';

import 'ads_config.dart';

abstract class AdsPlatform {
  Future<void> initialize();

  Future<AdsConsentState> gatherConsent();

  /// Whether a privacy options entry point must be shown to the user.
  Future<PrivacyOptionsRequirement> privacyOptionsRequirement();

  /// Present the form that lets a user revisit a consent or opt-out choice.
  Future<PrivacyOptionsOutcome> showPrivacyOptions();

  Future<RewardedOutcome> showRewarded(AdsRequest request);

  Future<bool> loadBanner(AdsRequest request);

  void clearBanner();

  Widget? buildBanner(BuildContext context);

  Future<void> release();
}
