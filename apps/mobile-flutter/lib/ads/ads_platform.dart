library;

import 'package:flutter/widgets.dart';

import 'ads_config.dart';

abstract class AdsPlatform {
  Future<void> initialize();

  Future<AdsConsentState> gatherConsent();

  Future<RewardedOutcome> showRewarded(AdsRequest request);

  Future<bool> loadBanner(AdsRequest request);

  void clearBanner();

  Widget? buildBanner(BuildContext context);

  Future<void> release();
}
