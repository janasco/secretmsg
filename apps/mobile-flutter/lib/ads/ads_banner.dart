library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'ads_config.dart';
import 'ads_service.dart';

class AdsBanner extends StatefulWidget {
  final AdsService service;

  AdsBanner({super.key, AdsService? service})
      : service = service ?? AdsService.instance;

  @override
  State<AdsBanner> createState() => _AdsBannerState();
}

class _AdsBannerState extends State<AdsBanner> {
  AdsService get _ads => widget.service;

  @override
  void initState() {
    super.initState();
    _ads.addListener(_onAdsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _ads.removeListener(_onAdsChanged);
    super.dispose();
  }

  void _onAdsChanged() {
    if (!mounted) return;
    setState(() {});
    if (_ads.isEnabled && _ads.bannerState == AdsSlotState.empty) {
      unawaited(_sync());
    }
  }

  Future<void> _sync() async {
    if (!mounted) return;
    if (_ads.isEnabled && _ads.bannerState == AdsSlotState.empty) {
      await _ads.loadBanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _ads.buildBanner(context);
    if (child == null) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.bg,
        border: Border(top: BorderSide(color: context.colors.border)),
      ),
      child: SafeArea(top: false, bottom: false, child: child),
    );
  }
}
