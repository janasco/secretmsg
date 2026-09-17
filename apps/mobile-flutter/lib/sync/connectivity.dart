/// Connectivity watch: drains the outbox and refreshes content when the
/// network comes back. Best-effort — every operation it triggers already
/// tolerates failure, so this layer never throws.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'outbox.dart';

class SyncService {
  SyncService._();
  static StreamSubscription<List<ConnectivityResult>>? _sub;
  static bool _online = true;
  static final ValueNotifier<bool> online = ValueNotifier(true);

  static Future<void> init({Future<void> Function()? onOnline}) async {
    await Outbox.refresh();
    try {
      final current = await Connectivity().checkConnectivity();
      _setOnline(!current.contains(ConnectivityResult.none));
    } catch (_) {}
    await _sub?.cancel();
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      final up = !results.contains(ConnectivityResult.none);
      final wasDown = !_online;
      _setOnline(up);
      if (up && wasDown) {
        unawaited(Outbox.drain(onChanged: onOnline));
      }
    });
  }

  static void _setOnline(bool value) {
    _online = value;
    if (online.value != value) online.value = value;
  }

  static void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
