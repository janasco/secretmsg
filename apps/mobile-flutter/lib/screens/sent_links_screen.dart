import 'package:flutter/material.dart';

import '../api/config.dart';
import '../sync/sent_links.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Reply links for messages that were sent through the offline outbox.
///
/// The composer shows the link immediately when online; a queued send only
/// learns its token when the drain succeeds. Those tokens are stored here so
/// the sender can still read the recipient's blind reply later.
class SentLinksScreen extends StatefulWidget {
  const SentLinksScreen({super.key});

  @override
  State<SentLinksScreen> createState() => _SentLinksScreenState();
}

class _SentLinksScreenState extends State<SentLinksScreen> {
  List<SentLink>? _links;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final links = await SentLinks.load();
    if (!mounted) return;
    setState(() => _links = links);
  }

  Future<void> _remove(SentLink link) async {
    await SentLinks.remove(link.clientMsgId);
    await _load();
  }

  String _date(int ms) {
    if (ms <= 0) return '';
    final t = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final links = _links;
    return Scaffold(
      appBar: const AppTopBar(title: 'Sent messages'),
      body: links == null
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : links.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 90),
                    Icon(Icons.mark_email_read_outlined,
                        size: 52, color: context.colors.textFaint),
                    const SizedBox(height: 12),
                    Text('No sent messages yet',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      'Messages queued while offline keep their private reply link here after they send.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 12,
                          height: 1.5),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: links.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final link = links[i];
                    final url = '$kPublicBaseUrl/reply/${link.token}';
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  link.username.isEmpty
                                      ? 'Anonymous message'
                                      : 'To @${link.username}',
                                  style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(_date(link.sentAt),
                                  style: TextStyle(
                                      color: context.colors.textFaint,
                                      fontSize: 10.5)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => copyToClipboard(context, url,
                                message: 'Reply link copied'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.colors.bg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      url,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: context.colors.accentSoft,
                                          fontSize: 11,
                                          fontFamily: 'monospace'),
                                    ),
                                  ),
                                  Icon(Icons.copy,
                                      size: 15,
                                      color: context.colors.accentSoft),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _remove(link),
                              child: Text('Remove',
                                  style: TextStyle(
                                      color: context.colors.textMuted,
                                      fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
