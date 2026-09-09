import 'package:flutter/material.dart';

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
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? ListView(
                  children: [
                    const SizedBox(height: 100),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFCA5A5))),
                    const SizedBox(height: 12),
                    Center(child: OutlinedButton(onPressed: _load, child: const Text('Retry'))),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _HeroCard(data: _data!),
                              const SizedBox(height: 18),
                              if (_data!.supporters.isNotEmpty)
                                const Text(
                                  'Recent supporters',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              const SizedBox(height: 10),
                              for (final s in _data!.supporters) ...[
                                _SupporterTile(supporter: s),
                                const SizedBox(height: 10),
                              ],
                              const SizedBox(height: 8),
                              const _SupportCta(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
        gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF0F1220)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Powering an anonymous, independent internet',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'SecretMsg is a personal project with zero ad trackers and zero data selling. Running secure, always-on infrastructure costs real money — every supporter keeps the lights on.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.55),
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
        color: const Color(0xFF090A0F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
        ],
      ),
    );
  }
}

class _SupporterTile extends StatelessWidget {
  final Supporter supporter;
  const _SupporterTile({required this.supporter});

  (String, Color) tierStyle(String tier) {
    switch (tier) {
      case 'Golden Guardian':
        return ('👑', const Color(0xFFF59E0B));
      case 'Silver Patron':
        return ('🥈', const Color(0xFF94A3B8));
      case 'Coffee Backer':
        return ('☕', const Color(0xFFC084FC));
      default:
        return ('🛡️', const Color(0xFF818CF8));
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = tierStyle(supporter.tier);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
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
                    Text(supporter.alias, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(_formatTime(supporter.createdAt), style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text('$icon ${supporter.tier}', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (supporter.note != null && supporter.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${supporter.note}”',
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.5),
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

class _SupportCta extends StatelessWidget {
  const _SupportCta();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Text(
            'Want to be on this wall?',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Supporting keeps SecretMsg ad-free and fully private. Reach out to support@secretmsg.net to join.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}