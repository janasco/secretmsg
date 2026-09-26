library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import '../api/models.dart';
import '../api/session.dart';
import 'ads_config.dart';
import 'ads_flags.dart';
import 'ads_platform.dart';
import 'mobile_ads_platform.dart';

class AdsService extends ChangeNotifier {
  AdsService({AdsPlatform? platform, AdsFlagResolver? flags})
      : _platform = platform ?? MobileAdsPlatform(),
        _flags = flags ?? AdsFlagResolver();

  static AdsService? _instance;

  static AdsService get instance => _instance ??= AdsService();

  final AdsPlatform _platform;
  final AdsFlagResolver _flags;

  final Set<String> _suppressions = <String>{};

  bool _adFree = false;
  bool _profileKnown = false;
  bool _ready = false;
  bool _remoteEnabled = false;
  bool _initialised = false;
  bool _released = false;
  bool _rewardInFlight = false;
  AdsConsentState _consent = AdsConsentState.unknown;
  AdsSlotState _banner = AdsSlotState.empty;

  bool get isAdFree => _adFree;

  bool get isEnabled => canServeAds(
        adFree: _adFree,
        ready: _ready,
        remoteEnabled: _remoteEnabled,
        consent: _consent,
        suppressed: _suppressions.isNotEmpty,
      );

  bool get ready => _ready;

  bool get remoteEnabled => _remoteEnabled;

  AdsConsentState get consent => _consent;

  AdsSlotState get bannerState => _banner;

  bool get isSuppressed => _suppressions.isNotEmpty;

  AdsRequestPolicy get policy => AdsRequestPolicy.forConsent(_consent);

  bool get canRequestPersonalised => _consent == AdsConsentState.obtained;

  Widget? buildBanner(BuildContext context) {
    if (_banner != AdsSlotState.ready) return null;
    if (!isEnabled) return null;
    return _platform.buildBanner(context);
  }

  void suppress(String reason) {
    if (_suppressions.add(reason)) notifyListeners();
  }

  void unsuppress(String reason) {
    if (_suppressions.remove(reason)) notifyListeners();
  }

  void clearSuppressions() {
    if (_suppressions.isEmpty) return;
    _suppressions.clear();
    notifyListeners();
  }

  void applyProfile(UserProfile? profile) {
    _profileKnown = true;
    final adFree = profile?.isPremium == 1;
    if (adFree == _adFree) return;
    _adFree = adFree;
    if (_adFree) {
      _ready = false;
      _banner = AdsSlotState.empty;
      try {
        _platform.clearBanner();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> init() async {
    if (_initialised || _released) return;
    _initialised = true;
    try {
      if (!_profileKnown) {
        final saved = await Session.getSavedUser();
        if (_released) return;
        applyProfile(saved);
      }
      if (_adFree) {
        _ready = true;
        notifyListeners();
        return;
      }
      final enabled = await _flags.resolve();
      if (_released) return;
      _remoteEnabled = enabled;
      if (!enabled) {
        _ready = true;
        notifyListeners();
        return;
      }
      await _platform.initialize();
      if (_released) return;
      _consent = await _platform.gatherConsent();
      if (_released) return;
      _ready = true;
    } catch (_) {
      _ready = true;
      _remoteEnabled = false;
      _consent = AdsConsentState.unavailable;
    }
    notifyListeners();
  }

  Future<void> loadBanner() async {
    if (!isEnabled) {
      if (_banner != AdsSlotState.empty) {
        _banner = AdsSlotState.empty;
        notifyListeners();
      }
      return;
    }
    if (_banner == AdsSlotState.loading || _banner == AdsSlotState.ready) {
      return;
    }
    _banner = AdsSlotState.loading;
    notifyListeners();
    var loaded = false;
    try {
      loaded = await _platform.loadBanner(
        AdsRequest(adUnitId: kBannerAdUnitId, policy: policy),
      );
    } catch (_) {
      loaded = false;
    }
    if (_released) return;
    _banner = loaded && isEnabled ? AdsSlotState.ready : AdsSlotState.failed;
    notifyListeners();
  }

  void clearBanner() {
    if (_banner == AdsSlotState.empty) return;
    _banner = AdsSlotState.empty;
    try {
      _platform.clearBanner();
    } catch (_) {}
    notifyListeners();
  }

  Future<RewardedOutcome> showRewardedForStreakFreeze() async {
    if (!isEnabled) return RewardedOutcome.unavailable;
    if (_rewardInFlight) return RewardedOutcome.unavailable;
    _rewardInFlight = true;
    try {
      return await _platform.showRewarded(
        AdsRequest(adUnitId: kRewardedAdUnitId, policy: policy),
      );
    } catch (_) {
      return RewardedOutcome.failed;
    } finally {
      _rewardInFlight = false;
    }
  }

  Future<PrivacyOptionsOutcome> showPrivacyOptions() async {
    if (!await privacyOptionsRequired()) {
      return PrivacyOptionsOutcome.unavailable;
    }
    final outcome = await _platform.showPrivacyOptions();
    // The user may have flipped the choice, so re-read consent rather than
    // assuming the previous value still holds. Otherwise a withdrawal would
    // leave personalised ads enabled for the rest of the session.
    if (outcome == PrivacyOptionsOutcome.completed) {
      await _refreshConsent();
    }
    return outcome;
  }

  /// Whether a privacy options entry point must be shown.
  ///
  /// Never true when ads are off or an ad-free account is active: with no ad
  /// requests being made there is no advertising choice to revisit. Missing
  /// identifiers need no separate check here, because a platform that cannot
  /// initialize throws and init() then clears the remote flag, so _remoteEnabled
  /// is already false in that case.
  Future<bool> privacyOptionsRequired() async {
    if (_adFree || !_remoteEnabled) return false;
    switch (await _platform.privacyOptionsRequirement()) {
      case PrivacyOptionsRequirement.required:
        return true;
      case PrivacyOptionsRequirement.notRequired:
      case PrivacyOptionsRequirement.unknown:
        return false;
    }
  }

  Future<void> _refreshConsent() async {
    try {
      _consent = await _platform.gatherConsent();
    } catch (_) {
      _consent = AdsConsentState.unavailable;
    }
    if (_released) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _released = true;
    _ready = false;
    _banner = AdsSlotState.empty;
    unawaited(_platform.release().catchError((Object _) {}));
    super.dispose();
  }
}
