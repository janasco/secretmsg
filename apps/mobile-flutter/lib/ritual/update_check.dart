/// App update checks against the public `/api/app-version` feed.
///
/// Shown on every cold start while behind (Update = open the destination for
/// *this* build's track, Later = snooze until next launch). The manual
/// "Check for updates" row in settings forces a result either way ("You're up
/// to date" or the dialog).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../api/config.dart';
import '../distribution/track.dart';

/// Feed key naming the Play destination, absent while Play is unpublished.
const String kPlayUrlField = 'url_play';

/// Feed key naming the sideload destination.
const String kSideloadUrlField = 'url_sideload';

/// Legacy single-URL key, read only by clients released before the per-track
/// fields existed. It is and stays the sideload download page.
const String kLegacyUrlField = 'url';

/// Last resort for a sideload build when the feed carries no URL at all, so a
/// truncated or rolled-back response cannot leave a sideloaded user with no
/// way to update.
const String kFallbackSideloadUrl = 'https://secretmsg.net/download';

class UpdateInfo {
  final String current;
  final String latest;

  /// Where the "Update" button goes, or null when the feed names no
  /// destination for this build's track — see [updateUrlForTrack].
  final String? url;

  final bool behind;
  final DistributionTrack track;

  const UpdateInfo({
    required this.current,
    required this.latest,
    required this.url,
    required this.behind,
    required this.track,
  });

  /// True when there is somewhere to send the user, i.e. the update dialog can
  /// be shown at all.
  bool get hasDestination => url != null && url!.isNotEmpty;
}

/// Numeric triple compare: 1.4.10 > 1.4.4, 1.10.0 > 1.9.9. Pure (tested).
int compareVersions(String a, String b) {
  List<int> parts(String v) =>
      v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final x = parts(a);
  final y = parts(b);
  for (var i = 0; i < 3; i++) {
    final xv = i < x.length ? x[i] : 0;
    final yv = i < y.length ? y[i] : 0;
    if (xv != yv) return xv.compareTo(yv);
  }
  return 0;
}

String? _nonEmpty(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}

/// The feed key that carries the destination for [track].
String urlFieldForTrack(DistributionTrack track) => switch (track) {
      DistributionTrack.play => kPlayUrlField,
      DistributionTrack.sideload => kSideloadUrlField,
    };

/// Picks the update destination for a client on [track] out of a decoded feed,
/// or returns null when the feed offers none for that track.
///
/// The two tracks never merge (see [DistributionTrack]), so this is the one
/// place that decides where a user is sent, and the rules are deliberately
/// asymmetric:
///
///   * **Sideload** prefers `url_sideload`, then falls back to the legacy
///     `url`, then to [kFallbackSideloadUrl]. LOUD, and deliberately so: that
///     fallback is safe *only* because `url` is by definition the sideload
///     download page, and it is what keeps every build that predates the
///     per-track fields working while the feed is being rolled forward. If
///     `url` is ever repointed away from the download page, this fallback
///     stops being safe and must be deleted rather than kept "for
///     compatibility".
///
///   * **Play** never falls back. `url` is the sideload page, so falling back
///     to it would send a Play user to an APK Android refuses to install over
///     their Play copy (`INSTALL_FAILED_UPDATE_INCOMPATIBLE`) — the exact bug
///     the per-track fields exist to remove. While `url_play` is absent from
///     the feed (Play is not published, so there is no listing URL to name)
///     the honest answer is null: the client stays silent instead of inventing
///     a destination. Re-adding `url_play` in the feed is all that is needed
///     to light this up; no new build is required.
String? updateUrlForTrack(Map<String, dynamic> feed, DistributionTrack track) {
  final own = _nonEmpty(feed[urlFieldForTrack(track)]);
  if (own != null) return own;
  if (track == DistributionTrack.sideload) {
    return _nonEmpty(feed[kLegacyUrlField]) ?? kFallbackSideloadUrl;
  }
  return null;
}

/// Returns update info, or null when the feed is unreachable (best-effort:
/// update prompts must never block boot or settings).
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version;
    final res = await http
        .get(Uri.parse('$kApiBaseUrl/api/app-version'))
        .timeout(const Duration(seconds: 3));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final latest = (data['android_latest'] ?? '').toString();
    if (latest.isEmpty) return null;
    return UpdateInfo(
      current: current,
      latest: latest,
      url: updateUrlForTrack(data, kDistributionTrack),
      behind: compareVersions(current, latest) < 0,
      track: kDistributionTrack,
    );
  } catch (_) {
    return null;
  }
}
