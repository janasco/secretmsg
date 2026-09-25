import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/billing.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SupportersScreen extends StatefulWidget {
  const SupportersScreen({super.key});

  @override
  State<SupportersScreen> createState() => _SupportersScreenState();
}

class _SupportersScreenState extends State<SupportersScreen> {
  SupportersData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.getSupporters();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the supporters wall.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Supporters Wall'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 100),
                    Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.colors.roseLight)),
                    const SizedBox(height: 12),
                    Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    key: const PageStorageKey('supporters'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    itemCount: _data!.supporters.isEmpty
                        ? 3
                        : _data!.supporters.length + 3,
                    itemBuilder: (context, i) {
                      final supporters = _data!.supporters;
                      final Widget child;
                      if (i == 0) {
                        child = _HeroCard(data: _data!);
                      } else if (supporters.isEmpty && i == 1) {
                        child = const SizedBox(height: 18);
                      } else if (supporters.isEmpty) {
                        child = const _SupportCta();
                      } else if (i == 1) {
                        child = const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: _RecentSupportersTitle(),
                        );
                      } else if (i < supporters.length + 2) {
                        child = Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SupporterTile(
                            key: ValueKey(supporters[i - 2].alias),
                            supporter: supporters[i - 2],
                          ),
                        );
                      } else {
                        child = const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: _SupportCta(),
                        );
                      }
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: child,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _RecentSupportersTitle extends StatelessWidget {
  const _RecentSupportersTitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Recent supporters',
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final SupportersData data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data.stats['totalSupporters']?.toString() ?? '—';
    final goal = data.stats['monthlyServerGoalPercent'];
    final month = data.stats['currentMonth']?.toString() ?? 'this month';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [context.colors.accentDeep, context.colors.surface]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 8),
              Text(
                'Powering an anonymous, independent internet',
                style: TextStyle(color: context.colors.textPrimary, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'SecretMsg is a personal project with zero ad trackers and zero data selling. Running secure, always-on infrastructure costs real money — every supporter keeps the lights on.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12.5, height: 1.55),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatBox(value: total, label: 'Supporters'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBox(
                  value: goal is num ? '${goal.round()}%' : '—',
                  label: 'Server goal ($month)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: context.colors.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: context.colors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _SupporterTile extends StatelessWidget {
  final Supporter supporter;
  const _SupporterTile({super.key, required this.supporter});

  (String, Color) tierStyle(BuildContext context, String tier) {
    switch (tier) {
      case 'Golden Guardian':
        return ('👑', const Color(0xFFF59E0B));
      case 'Silver Patron':
        return ('🥈', context.colors.textSecondary);
      case 'Coffee Backer':
        return ('☕', const Color(0xFFC084FC));
      default:
        return ('🛡️', const Color(0xFF818CF8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = tierStyle(context, supporter.tier);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarBadge(
                initials: supporter.alias.length >= 2 ? supporter.alias.substring(0, 2).toUpperCase() : supporter.alias,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supporter.alias, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(_formatTime(supporter.createdAt), style: TextStyle(color: context.colors.textMuted, fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text('$icon ${supporter.tier}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (supporter.note != null && supporter.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${supporter.note}”',
              style: TextStyle(color: context.colors.textHigh, fontSize: 12.5, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatTime(String iso) {
    try {
      final t = DateTime.parse(iso).toLocal();
      return '${t.day.toString().padLeft(2, '0')} ${_months[t.month - 1]}, ${t.year}';
    } catch (_) {
      return iso;
    }
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}

/// Supporter perks, purchased through Google Play Billing.
///
/// Nothing is unlocked on this side: [Billing] forwards the purchase token to
/// the API, which verifies it with Google before granting the perk.
class _SupportCta extends StatefulWidget {
  const _SupportCta();

  @override
  State<_SupportCta> createState() => _SupportCtaState();
}

class _SupportCtaState extends State<_SupportCta> {
  StreamSubscription<BillingEvent>? _sub;
  bool _loading = true;
  String? _busyProductId;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _sub = Billing.events.listen(_onBillingEvent);
    _init();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    await Billing.init();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onBillingEvent(BillingEvent e) {
    if (!mounted) return;
    setState(() {
      switch (e.stage) {
        case BillingStage.pending:
          _busyProductId = e.productId;
          _notice = 'Waiting for Google Play to confirm your payment...';
          break;
        case BillingStage.granted:
          _busyProductId = null;
          _notice = '${BillingProducts.labelFor(e.productId)} unlocked. Thank you!';
          break;
        case BillingStage.cancelled:
          _busyProductId = null;
          _notice = null;
          break;
        case BillingStage.failed:
          _busyProductId = null;
          _notice = e.message ?? 'That purchase could not be completed.';
          break;
      }
    });
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() {
      _busyProductId = product.id;
      _notice = null;
    });
    try {
      await Billing.buy(product);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyProductId = null;
        _notice = e is ApiException ? e.message : 'Could not complete this purchase.';
      });
    }
  }

  Future<void> _restore() async {
    setState(() => _notice = 'Checking for previous purchases...');
    try {
      await Billing.restore();
    } catch (e) {
      if (!mounted) return;
      setState(() => _notice = e is ApiException ? e.message : 'Could not restore your purchases.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Want to be on this wall?',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Supporting keeps SecretMsg ad-free and fully private.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 14),
          ..._buildStore(),
          if (_notice != null) ...[
            const SizedBox(height: 10),
            Text(
              _notice!,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.accentSoft, fontSize: 11, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildStore() {
    if (_loading) {
      return const [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      ];
    }

    // Sideloaded builds and misconfigured Play products both land here.
    if (!Billing.isAvailable || Billing.products.isEmpty) {
      return [
        Text(
          'In-app purchases are not available on this device yet. '
          'Reach out to support@secretmsg.net if you would like to support the project.',
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5),
        ),
      ];
    }

    final sorted = [...Billing.products]..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));

    return [
      for (final p in sorted) ...[
        _PerkRow(
          title: BillingProducts.labelFor(p.id),
          price: p.price,
          busy: _busyProductId == p.id,
          onBuy: _busyProductId == null ? () => _buy(p) : null,
        ),
        const SizedBox(height: 8),
      ],
      TextButton(
        onPressed: _busyProductId == null ? _restore : null,
        child: Text(
          'Restore purchases',
          style: TextStyle(color: context.colors.accentSoft, fontSize: 12),
        ),
      ),
    ];
  }
}

class _PerkRow extends StatelessWidget {
  final String title;
  final String price;
  final bool busy;
  final VoidCallback? onBuy;

  const _PerkRow({
    required this.title,
    required this.price,
    required this.busy,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(color: context.colors.textHigh, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          height: 34,
          child: FilledButton(
            onPressed: busy ? null : onBuy,
            child: busy
                ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(price, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
