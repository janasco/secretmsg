import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'social_api.dart';
import 'social_widgets.dart';

/// The member's own box inside a group.
///
/// Enforcement is cryptographic, not policy: messages here are sealed to the
/// member's key, the owner's client never receives this ciphertext, and even a
/// malicious server could not make it readable to the owner. The API also
/// refuses owner requests for another member's box.
class MemberBoxScreen extends StatefulWidget {
  final String groupId;
  final String memberId;
  final String pseudonym;

  const MemberBoxScreen({
    super.key,
    required this.groupId,
    required this.memberId,
    required this.pseudonym,
  });

  @override
  State<MemberBoxScreen> createState() => _MemberBoxScreenState();
}

class _MemberBoxScreenState extends State<MemberBoxScreen> {
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
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
      final Map<String, dynamic> data =
          await SocialApi.listMemberBox(widget.groupId, widget.memberId);
      final List<dynamic> raw = data['messages'] as List<dynamic>? ?? <dynamic>[];
      if (!mounted) return;
      setState(() {
        _messages = raw.map((dynamic e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is SocialApiException ? e.message : 'Could not open this box.';
      });
    }
  }

  Future<void> _report(Map<String, dynamic> message) async {
    final Map<String, dynamic>? envelope =
        openInterimEnvelope(message['payload'] as String? ?? '');
    final String? plaintext = envelope?['t'] as String?;
    final _BoxReportResult? result = await showModalBottomSheet<_BoxReportResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BoxReportSheet(canDisclose: plaintext != null),
    );
    if (result == null || !mounted) return;
    try {
      await SocialApi.report(
        targetKind: 'member_box',
        targetId: message['id'] as String,
        reason: result.reason,
        consent: result.includeCopy,
        disclosedPayload: plaintext,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        result.includeCopy
            ? 'Report sent with your copy of this message. Nothing else in your box is shared.'
            : 'Report sent. No content was attached.',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not send the report.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopBar(title: 'Box for ${widget.pseudonym}'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const PageStorageKey<String>('member-box'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: <Widget>[
            const SocialHonestLimitsCard(
              lines: <String>[
                'This box is sealed to your key. The group owner never receives it and cannot read it.',
                'Reports are metadata-only unless you tick the box that attaches your copy of one message.',
                'Only the person you are messaging and you can read this thread; the platform stores ciphertext.',
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Messages sent here stay between pseudonyms. Sender handles are never shown, and no member list is exposed to you.',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: context.colors.accent)),
              )
            else if (_error != null)
              SocialErrorView(message: _error!, onRetry: _load)
            else if (_messages.isEmpty)
              const SocialEmptyState(
                icon: Icons.mark_email_unread_outlined,
                title: 'Nothing here yet',
                body:
                    'When a member sends you a private box message, it lands here. Open a feed post and tap “Private box” to write to its author.',
              )
            else
              for (final Map<String, dynamic> message in _messages) ...<Widget>[
                _BoxMessageTile(message: message, onReport: () => _report(message)),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _BoxMessageTile extends StatelessWidget {
  final Map<String, dynamic> message;
  final VoidCallback onReport;

  const _BoxMessageTile({required this.message, required this.onReport});

  String _timestamp() {
    final Object? created = message['created_at'];
    if (created is int) {
      final DateTime when = DateTime.fromMillisecondsSinceEpoch(created * 1000);
      final String hh = when.hour.toString().padLeft(2, '0');
      final String mm = when.minute.toString().padLeft(2, '0');
      return '${when.year}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')} $hh:$mm';
    }
    return 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? envelope =
        openInterimEnvelope(message['payload'] as String? ?? '');
    final String? text = envelope?['t'] as String?;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SocialChip(label: 'From a member', icon: Icons.face_outlined),
              const Spacer(),
              Text(_timestamp(), style: TextStyle(color: context.colors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          if (text != null)
            Text(
              text,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 14, height: 1.5),
            )
          else
            Text(
              'Sealed message. The key for this box is not on this device yet.',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.flag_outlined, size: 16),
              label: const Text('Report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoxReportResult {
  final String reason;
  final bool includeCopy;

  const _BoxReportResult(this.reason, this.includeCopy);
}

class _BoxReportSheet extends StatefulWidget {
  final bool canDisclose;

  const _BoxReportSheet({required this.canDisclose});

  @override
  State<_BoxReportSheet> createState() => _BoxReportSheetState();
}

class _BoxReportSheetState extends State<_BoxReportSheet> {
  final TextEditingController _reason = TextEditingController();
  bool _includeCopy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Report this message',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _reason,
            maxLength: 200,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'What is wrong?', counterText: ''),
          ),
          if (widget.canDisclose)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeCopy,
              onChanged: (bool? value) => setState(() => _includeCopy = value ?? false),
              title: const Text(
                'Include my copy of this message with the report',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Reporting shows us this message so we can review it. Nothing else in your box is shared.',
                style: TextStyle(fontSize: 11),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final String reason = _reason.text.trim();
                if (reason.length < 3) return;
                Navigator.of(context).pop(_BoxReportResult(reason, _includeCopy));
              },
              child: const Text('Submit report'),
            ),
          ),
        ],
      ),
    );
  }
}
