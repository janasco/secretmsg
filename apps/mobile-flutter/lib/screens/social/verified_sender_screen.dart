import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'social_api.dart';
import 'social_widgets.dart';

/// Opt-in verified sender.
///
/// The badge is a server-signed attestation attached per message; a modified
/// client cannot mint one because it holds no signing key. Verification is off
/// by default, replies carry none unless enabled for that thread, and the
/// attestation contains no stable identifier a recipient could reuse to link
/// two messages.
///
/// SHIPPING GATE: the consent copy below states that message bodies stay
/// end-to-end encrypted. This screen must not ship to users before the E2E
/// envelope does (see docs/design/001); until then, verified badges are
/// disabled server-side anyway because no signing key is configured.
class VerifiedSenderScreen extends StatefulWidget {
  const VerifiedSenderScreen({super.key});

  @override
  State<VerifiedSenderScreen> createState() => _VerifiedSenderScreenState();
}

class _VerifiedSenderScreenState extends State<VerifiedSenderScreen> {
  bool _consent = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  Map<String, dynamic> _status = <String, dynamic>{};

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
      final Map<String, dynamic> data = await SocialApi.verifiedMe();
      if (!mounted) return;
      setState(() {
        _status = data;
        _loading = false;
        _consent = data['consent'] != null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is SocialApiException ? e.message : 'Could not load your verification status.';
      });
    }
  }

  Future<void> _start(String claimType) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_status['consent'] == null) {
        await SocialApi.consentVerified();
      }
      await SocialApi.startVerification(claimType);
      if (!mounted) return;
      showSuccessSnack(context, 'Verification started.');
      await _load();
    } on SocialApiException catch (e) {
      if (!mounted) return;
      // 501 means the vendor path is not configured in this environment;
      // nothing was stored, exactly as the copy promises.
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Verification is not available right now. Nothing was stored.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? badge = _status['badge'] as Map<String, dynamic>?;
    final bool verified = _status['verified'] == true;
    final bool revoked = badge != null && badge['revoked'] == true;
    return Scaffold(
      appBar: const AppTopBar(title: 'Verified sender'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: <Widget>[
                if (_error != null) ...<Widget>[
                  Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12)),
                  const SizedBox(height: 10),
                ],
                if (verified && badge != null) ...<Widget>[
                  _BadgePreview(
                    claimText: badge['claim_text']?.toString() ?? 'Verified',
                    verifiedAt: badge['verified_at'] as int?,
                    revoked: revoked,
                  ),
                  const SizedBox(height: 14),
                ],
                const SocialHonestLimitsCard(
                  lines: <String>[
                    'Verification asserts a checked claim — an organization affiliation or 18+ — not who the person is.',
                    'It is off by default, and replies carry no badge unless you enable it for that thread.',
                    'Per-message attestations carry no stable verification ID, so two verified messages cannot be linked by a recipient.',
                    'Reactions never carry badges.',
                    'Behavioral inference — writing style, timing — is not preventable and is not something we will claim otherwise.',
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Before you verify',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What is stored:\n'
                  '\u2022 Organization claim: the domain, the date, and a one-way HMAC of the verified mailbox. The address itself is not stored.\n'
                  '\u2022 18+ claim: the vendor\u2019s pass result, the date, and a vendor reference. No documents, no identity fields, no images.\n\n'
                  'Retention and deletion: the record is deleted with your account. Cancelling before completion, or a failed attempt, stores nothing.\n\n'
                  'Legal process: a valid subpoena or equivalent to SecretMsg or the vendor can identify a verified sender. '
                  'Your message bodies stay end-to-end encrypted and are not readable by SecretMsg.',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.6),
                ),
                const SizedBox(height: 14),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _consent,
                  onChanged: _busy
                      ? null
                      : (bool? value) => setState(() => _consent = value ?? false),
                  title: const Text(
                    'I understand what verification stores and that legal process can identify me.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (!_consent || _busy) ? null : () => _start('org'),
                        child: const Text('Verify organization'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: (!_consent || _busy) ? null : () => _start('age'),
                        child: const Text('Verify 18+'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Each send is opt-in separately. When you attach a badge, the sender-facing preview shows exactly what the recipient will see: the claim text, the verification date, and an explanation that verification is not a promise of good intent.',
                  style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.55),
                ),
              ],
            ),
    );
  }
}

class _BadgePreview extends StatelessWidget {
  final String claimText;
  final int? verifiedAt;
  final bool revoked;

  const _BadgePreview({required this.claimText, required this.verifiedAt, required this.revoked});

  @override
  Widget build(BuildContext context) {
    final String date = verifiedAt == null
        ? ''
        : DateTime.fromMillisecondsSinceEpoch(verifiedAt! * 1000)
            .toIso8601String()
            .substring(0, 10);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (revoked ? context.colors.amber : context.colors.accent).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (revoked ? context.colors.amber : context.colors.accent).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            revoked ? Icons.gpp_bad_outlined : Icons.verified_outlined,
            color: revoked ? context.colors.amber : context.colors.accentSoft,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  revoked ? 'Verification revoked' : claimText,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (date.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    'Checked $date',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'SecretMsg checked this claim at send time. It does not tell you who the sender is. A verified claim is not a promise of good intent.',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
