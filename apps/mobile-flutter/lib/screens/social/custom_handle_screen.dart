import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'social_api.dart';
import 'social_widgets.dart';

/// Claim one custom handle.
///
/// Handles are ASCII-only by syntax (no homoglyph or punycode lookalikes),
/// checked atomically server-side, and compared under a confusable rule so
/// `1aura` cannot shadow `laura`. Old handles keep redirecting while the
/// account lives and become permanent tombstones after deletion — never
/// reassigned — so a printed sticker or QR code can never resolve to a
/// stranger's box.
class CustomHandleScreen extends StatefulWidget {
  const CustomHandleScreen({super.key});

  @override
  State<CustomHandleScreen> createState() => _CustomHandleScreenState();
}

class _CustomHandleScreenState extends State<CustomHandleScreen> {
  final TextEditingController _handle = TextEditingController();
  List<Map<String, dynamic>> _handles = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _handle.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> data = await SocialApi.getMyHandles();
      final List<dynamic> raw = data['handles'] as List<dynamic>? ?? <dynamic>[];
      if (!mounted) return;
      setState(() {
        _handles = raw.map((dynamic e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is SocialApiException ? e.message : 'Could not load your handles.';
      });
    }
  }

  Future<void> _claim() async {
    final String requested = _handle.text.trim().replaceFirst(RegExp(r'^@'), '');
    if (requested.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final Map<String, dynamic> data = await SocialApi.claimHandle(requested);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _success = data['message']?.toString() ?? 'Handle claimed.';
        _handle.clear();
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is SocialApiException ? e.message : 'That handle could not be claimed.';
      });
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'retired':
        return 'Redirects';
      case 'tombstone':
        return 'Retired forever';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Custom handle'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: <Widget>[
          if (_error != null) ...<Widget>[
            Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12, height: 1.5)),
            const SizedBox(height: 10),
          ],
          if (_success != null) ...<Widget>[
            Text(_success!, style: TextStyle(color: context.colors.emeraldLight, fontSize: 12, height: 1.5)),
            const SizedBox(height: 10),
          ],
          const SocialHonestLimitsCard(
            lines: <String>[
              'A handle is public. Do not use a full legal name, a school plus graduation year, or other identifying details.',
              'Handles are 3-20 characters: a-z, 0-9, - and _. ASCII only, so no lookalike or punycode tricks.',
              'A custom handle needs a verified email or an account older than 7 days. One change per 30 days, up to 3 per year.',
              'Old links keep working: retired handles redirect to your newest handle, and they are never given to anyone else.',
              'If the account is deleted, the handle is retired permanently and shows “this box no longer exists” — never another person’s box.',
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _handle,
            autocorrect: false,
            maxLength: 20,
            decoration: const InputDecoration(
              labelText: 'Claim a handle',
              prefixText: 'secretmsg.net/',
              counterText: '',
              helperText: 'Lowercase letters, numbers, dashes and underscores',
            ),
            onSubmitted: (_) {
              if (!_busy) _claim();
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _claim,
              child: Text(_busy ? 'Claiming…' : 'Claim handle'),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your handles',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            Center(child: CircularProgressIndicator(color: context.colors.accent))
          else if (_handles.isEmpty)
            Text(
              'No custom handle yet. Your auto-generated handle keeps working either way.',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.5),
            )
          else
            for (final Map<String, dynamic> handle in _handles) ...<Widget>[
              GlassCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '@${handle['display_handle'] ?? handle['handle']}',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (handle['status'] == 'retired' && handle['redirect_to'] != null)
                            Text(
                              'Redirects to @${handle['redirect_to']}',
                              style: TextStyle(color: context.colors.textMuted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    SocialChip(
                      label: _statusLabel(handle['status']?.toString() ?? ''),
                      color: handle['status'] == 'active' ? context.colors.emerald : context.colors.textMuted,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
