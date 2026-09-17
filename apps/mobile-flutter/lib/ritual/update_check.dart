/// App update checks against the public `/api/app-version` feed.
///
/// Shown on every cold start while behind (Update = open download page,
/// Later = snooze until next launch). The manual "Check for updates" row in
/// settings forces a result either way ("You're up to date" or the dialog).
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../api/config.dart';

class UpdateInfo {
  final String current;
  final String latest;
  final String url;
  final bool behind;

  const UpdateInfo({
    required this.current,
    required this.latest,
    required this.url,
    required this.behind,
  });
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

/// Returns update info, or null when the feed is unreachable (best-effort:
/// update prompts must never block boot or settings).
Future<UpdateInfo?> checkForUpdate() async {
  try {
    final pkg = await PackageInfo.fromPlatform();
    final current = pkg.version;
    final res = await http
        .get(Uri.parse('$kApiBaseUrl/api/app-version'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final latest = (data['android_latest'] ?? '').toString();
    final url = (data['url'] ?? 'https://secretmsg.net/download').toString();
    if (latest.isEmpty) return null;
    return UpdateInfo(
      current: current,
      latest: latest,
      url: url,
      behind: compareVersions(current, latest) < 0,
    );
  } catch (_) {
    return null;
  }
}
