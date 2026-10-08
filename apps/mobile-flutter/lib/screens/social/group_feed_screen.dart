import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'member_box_screen.dart';
import 'social_api.dart';
import 'social_widgets.dart';

/// The group feed: a sealed, member-only board. Member posting is off by
/// default; the owner can freeze the feed, turn posting on or off, slow it
/// down, delete posts, mute or remove members, and rotate the group key.
/// Members can react (one per person), upvote privately on-device, report with
/// consent, mute the feed locally, and leave without an announcement.
class GroupFeedScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final bool isOwner;

  const GroupFeedScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.isOwner,
  });

  @override
  State<GroupFeedScreen> createState() => _GroupFeedScreenState();
}

class _GroupFeedScreenState extends State<GroupFeedScreen> {
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _posts = <Map<String, dynamic>>[];
  final Map<String, List<Map<String, dynamic>>> _reactions = <String, List<Map<String, dynamic>>>{};
  Set<String> _upvotes = <String>{};
  bool _upvotedFirst = false;
  bool _loading = true;
  String? _error;
  String? _busyPostId;
  String? _loadReactionsError;

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
      final Map<String, dynamic> groupData = await SocialApi.getGroup(widget.groupId);
      final Map<String, dynamic> postsData = await SocialApi.listPosts(widget.groupId);
      final List<dynamic> rawPosts = postsData['posts'] as List<dynamic>? ?? <dynamic>[];
      final List<Map<String, dynamic>> posts =
          rawPosts.map((dynamic e) => e as Map<String, dynamic>).toList();
      final Set<String> upvotes = await LocalUpvotes.load();
      if (!mounted) return;
      setState(() {
        _group = groupData['group'] as Map<String, dynamic>?;
        _posts = posts;
        _upvotes = upvotes;
        _loading = false;
      });
      await _loadReactionsForVisiblePosts(posts);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is SocialApiException ? e.message : 'Could not load this group.';
      });
    }
  }

  Future<void> _loadReactionsForVisiblePosts(List<Map<String, dynamic>> posts) async {
    final List<Map<String, dynamic>> slice = posts.take(15).toList();
    for (final Map<String, dynamic> post in slice) {
      await _loadReactionsFor(post['id'] as String);
    }
  }

  Future<void> _loadReactionsFor(String postId) async {
    try {
      final Map<String, dynamic> data = await SocialApi.getPostReactions(widget.groupId, postId);
      final List<dynamic> raw = data['reactions'] as List<dynamic>? ?? <dynamic>[];
      final List<Map<String, dynamic>> rows =
          raw.map((dynamic e) => e as Map<String, dynamic>).toList();
      if (!mounted) return;
      setState(() {
        _reactions[postId] = rows;
        _loadReactionsError = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadReactionsError = 'Some reactions could not be loaded. Pull to refresh.');
    }
  }

  Future<void> _compose() async {
    final String? text = await showDialog<String>(
      context: context,
      builder: (_) => const _ComposePostDialog(),
    );
    if (text == null || !mounted) return;
    try {
      await SocialApi.createPost(widget.groupId, sealInterimEnvelope(<String, dynamic>{'t': text}));
      if (!mounted) return;
      showSuccessSnack(context, 'Posted to the group.');
      await _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not post.');
    }
  }

  String? _myReaction(String postId) {
    final List<Map<String, dynamic>>? rows = _reactions[postId];
    if (rows == null) return null;
    for (final Map<String, dynamic> row in rows) {
      if (row['mine'] == true) {
        return openReactionPayload(row['payload'] as String? ?? '');
      }
    }
    return null;
  }

  Map<String, int> _counts(String postId) {
    final Map<String, int> counts = <String, int>{};
    for (final Map<String, dynamic> row in _reactions[postId] ?? <Map<String, dynamic>>[]) {
      final String? id = openReactionPayload(row['payload'] as String? ?? '');
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _toggleReaction(String postId, String emojiId) async {
    final String? mine = _myReaction(postId);
    final String? next = mine == emojiId ? null : emojiId;
    setState(() => _busyPostId = postId);
    try {
      await SocialApi.putPostReaction(
        widget.groupId,
        postId,
        next == null ? null : sealReactionPayload(next),
      );
      if (!mounted) return;
      await _loadReactionsFor(postId);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not save that reaction.');
    } finally {
      if (mounted) setState(() => _busyPostId = null);
    }
  }

  Future<void> _toggleUpvote(String postId) async {
    final Set<String> updated = await LocalUpvotes.toggle(postId);
    if (!mounted) return;
    setState(() => _upvotes = updated);
  }

  Future<void> _clearRankings() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Clear rankings?'),
        content: const Text(
          'Your private upvotes live only on this device. Clearing them cannot be undone, and they are not stored anywhere else.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await LocalUpvotes.clear();
    if (!mounted) return;
    setState(() => _upvotes = <String>{});
    showSuccessSnack(context, 'Private rankings cleared.');
  }

  Future<void> _reportPost(Map<String, dynamic> post) async {
    final String postId = post['id'] as String;
    final Map<String, dynamic>? envelope = openInterimEnvelope(post['payload'] as String? ?? '');
    final String? plaintext = envelope?['t'] as String?;
    final _ReportResult? result = await showModalBottomSheet<_ReportResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(canDisclose: plaintext != null),
    );
    if (result == null || !mounted) return;
    try {
      await SocialApi.report(
        targetKind: 'group_post',
        targetId: postId,
        reason: result.reason,
        audience: result.audience,
        consent: result.includeCopy,
        disclosedPayload: plaintext,
      );
      if (!mounted) return;
      showSuccessSnack(
        context,
        result.includeCopy
            ? 'Report sent with your copy of the post. The reviewer sees that post only.'
            : 'Report sent. No content was attached.',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not send the report.');
    }
  }

  Future<void> _sendToAuthor(String postId) async {
    final String? text = await showDialog<String>(
      context: context,
      builder: (_) => const _ComposePostDialog(title: 'Send a private box message'),
    );
    if (text == null || !mounted) return;
    try {
      await SocialApi.sendMemberBoxToPostAuthor(
        widget.groupId,
        postId,
        sealInterimEnvelope(<String, dynamic>{'t': text}),
      );
      if (!mounted) return;
      showSuccessSnack(context, 'Delivered to their member box. The owner cannot read it.');
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not deliver.');
    }
  }

  Future<void> _leave() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Leave this group?'),
        content: const Text(
          'Nobody is told you left. The group key rotates, so you will not be able to read posts made after you leave.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await SocialApi.leaveGroup(widget.groupId);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'You left the group.');
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not leave.');
    }
  }

  Future<void> _toggleMute() async {
    final Map<String, dynamic>? me = _group?['me'] as Map<String, dynamic>?;
    final int current = (me?['notifications'] as int?) ?? 0;
    final bool next = current != 1;
    try {
      await SocialApi.updateMemberSettings(widget.groupId, <String, dynamic>{'notifications': next});
      if (!mounted) return;
      setState(() {
        me?['notifications'] = next ? 1 : 0;
      });
      showSuccessSnack(
        context,
        next ? 'Notifications for this group are on (generic text).' : 'Muted. You can still open the feed.',
      );
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'Could not update settings.');
    }
  }

  Future<void> _openMemberBox() async {
    final Map<String, dynamic>? me = _group?['me'] as Map<String, dynamic>?;
    final String? memberId = me?['id'] as String?;
    if (memberId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MemberBoxScreen(
          groupId: widget.groupId,
          memberId: memberId,
          pseudonym: me?['pseudonym']?.toString() ?? 'you',
        ),
      ),
    );
  }

  Future<void> _ownerTools() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OwnerToolsSheet(
        groupId: widget.groupId,
        group: _group ?? <String, dynamic>{},
        onChanged: _load,
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> group = _group ?? <String, dynamic>{};
    final bool frozen = group['frozen'] == true;
    final bool memberPosting = group['member_posting'] == 1;
    final Map<String, dynamic>? me = group['me'] as Map<String, dynamic>?;
    final bool canPost = widget.isOwner || memberPosting;

    final List<Map<String, dynamic>> ordered = _upvotedFirst
        ? LocalUpvotes.upvotedFirst<Map<String, dynamic>>(
            _posts,
            (Map<String, dynamic> post) => post['id'] as String? ?? '',
            _upvotes,
          )
        : _posts;

    return Scaffold(
      appBar: AppTopBar(
        title: widget.groupName,
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'upvoted':
                  setState(() => _upvotedFirst = !_upvotedFirst);
                  break;
                case 'mute':
                  _toggleMute();
                  break;
                case 'box':
                  _openMemberBox();
                  break;
                case 'clear':
                  _clearRankings();
                  break;
                case 'leave':
                  _leave();
                  break;
                case 'tools':
                  _ownerTools();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'upvoted',
                child: Text(_upvotedFirst ? 'Show recent first' : 'Upvoted first (on-device)'),
              ),
              PopupMenuItem<String>(
                value: 'mute',
                child: Text((me?['notifications'] as int?) == 1 ? 'Mute this group' : 'Unmute this group'),
              ),
              const PopupMenuItem<String>(value: 'box', child: Text('My member box')),
              const PopupMenuItem<String>(value: 'clear', child: Text('Clear my rankings')),
              if (widget.isOwner) const PopupMenuItem<String>(value: 'tools', child: Text('Owner tools')),
              const PopupMenuItem<String>(value: 'leave', child: Text('Leave group')),
            ],
          ),
        ],
      ),
      floatingActionButton: canPost && !frozen
          ? FloatingActionButton.extended(
              onPressed: _compose,
              backgroundColor: context.colors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Post'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? Center(child: CircularProgressIndicator(color: context.colors.accent))
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: <Widget>[SocialErrorView(message: _error!, onRetry: _load)],
                  )
                : ListView(
                    key: const PageStorageKey<String>('group-feed'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                    children: <Widget>[
                      if (frozen || group['throttled_until'] != null)
                        _FeedNotice(
                          icon: Icons.lock_outline,
                          text: frozen
                              ? 'The owner froze this feed. You can read and report, but nobody can post.'
                              : 'Reports are being reviewed, so posting is paused for a while. You can still read and report.',
                        ),
                      if (!canPost)
                        const _FeedNotice(
                          icon: Icons.visibility_outlined,
                          text: 'Only the owner posts here right now. Member posting is off by default.',
                        ),
                      if ((me?['notifications'] as int?) != 1)
                        const _FeedNotice(
                          icon: Icons.notifications_off_outlined,
                          text: 'Notifications for this group are muted by default. Tap the menu to turn them on.',
                        ),
                      if (_loadReactionsError != null)
                        _FeedNotice(icon: Icons.warning_amber_outlined, text: _loadReactionsError!),
                      if (ordered.isEmpty)
                        const SocialEmptyState(
                          icon: Icons.forum_outlined,
                          title: 'Nothing here yet',
                          body: 'When someone posts, it lands here. New members see posts made after they joined.',
                        )
                      else
                        for (final Map<String, dynamic> post in ordered) ...<Widget>[
                          _PostTile(
                            post: post,
                            myReaction: _myReaction(post['id'] as String),
                            counts: _counts(post['id'] as String),
                            busy: _busyPostId == post['id'],
                            upvoted: _upvotes.contains(post['id']),
                            isOwner: widget.isOwner,
                            reactionsEnabled: group['reactions_enabled'] != 0,
                            onReact: (String id) => _toggleReaction(post['id'] as String, id),
                            onUpvote: () => _toggleUpvote(post['id'] as String),
                            onReport: () => _reportPost(post),
                            onSendToAuthor: () => _sendToAuthor(post['id'] as String),
                            onDelete: () async {
                              try {
                                await SocialApi.deletePost(widget.groupId, post['id'] as String);
                                if (!context.mounted) return;
                                showSuccessSnack(context, 'Post removed for all members on next sync.');
                                await _load();
                              } catch (e) {
                                if (!context.mounted) return;
                                showErrorSnack(context,
                                    e is SocialApiException ? e.message : 'Could not delete.');
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                    ],
                  ),
      ),
    );
  }
}

class _FeedNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeedNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostTile extends StatelessWidget {
  final Map<String, dynamic> post;
  final String? myReaction;
  final Map<String, int> counts;
  final bool busy;
  final bool upvoted;
  final bool isOwner;
  final bool reactionsEnabled;
  final ValueChanged<String> onReact;
  final VoidCallback onUpvote;
  final VoidCallback onReport;
  final VoidCallback onSendToAuthor;
  final VoidCallback onDelete;

  const _PostTile({
    required this.post,
    required this.myReaction,
    required this.counts,
    required this.busy,
    required this.upvoted,
    required this.isOwner,
    required this.reactionsEnabled,
    required this.onReact,
    required this.onUpvote,
    required this.onReport,
    required this.onSendToAuthor,
    required this.onDelete,
  });

  String _timestamp() {
    final bool mine = post['mine'] == true;
    if (mine && post['created_at'] is int) {
      final DateTime when = DateTime.fromMillisecondsSinceEpoch((post['created_at'] as int) * 1000);
      final String hh = when.hour.toString().padLeft(2, '0');
      final String mm = when.minute.toString().padLeft(2, '0');
      return 'You \u00b7 $hh:$mm';
    }
    return post['day']?.toString() ?? 'Earlier';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? envelope = openInterimEnvelope(post['payload'] as String? ?? '');
    final String? text = envelope?['t'] as String?;
    final bool ownerPost = post['is_owner_post'] == true;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              SocialChip(
                label: ownerPost ? 'Group owner' : post['author_label']?.toString() ?? 'member',
                color: ownerPost ? context.colors.amber : null,
                icon: ownerPost ? Icons.campaign_outlined : Icons.face_outlined,
              ),
              const Spacer(),
              Text(
                _timestamp(),
                style: TextStyle(color: context.colors.textMuted, fontSize: 11),
              ),
              if (isOwner && !ownerPost)
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (BuildContext context) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'delete', child: Text('Delete for everyone')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (text != null)
            Text(
              text,
              style: TextStyle(color: context.colors.textPrimary, fontSize: 14, height: 1.5),
            )
          else
            Row(
              children: <Widget>[
                Icon(Icons.lock_outline, size: 14, color: context.colors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sealed post. The group key is not on this device yet.',
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          ReactionStrip(
            counts: counts,
            mine: myReaction,
            enabled: reactionsEnabled && !busy,
            disabledCopy: 'Reactions are turned off in this group. Existing reactions stay visible.',
            showCounts: true,
            onSelect: onReact,
          ),
          const Divider(height: 22),
          Row(
            children: <Widget>[
              Tooltip(
                message: 'Upvote privately — only you can see this',
                child: IconButton(
                  onPressed: onUpvote,
                  isSelected: upvoted,
                  icon: const Icon(Icons.arrow_circle_up_outlined),
                  selectedIcon: const Icon(Icons.arrow_circle_up),
                ),
              ),
              TextButton.icon(
                onPressed: onSendToAuthor,
                icon: const Icon(Icons.mail_outline, size: 16),
                label: const Text('Private box'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Report'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComposePostDialog extends StatefulWidget {
  final String title;

  const _ComposePostDialog({this.title = 'Post to the feed'});

  @override
  State<_ComposePostDialog> createState() => _ComposePostDialogState();
}

class _ComposePostDialogState extends State<_ComposePostDialog> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: 500,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Write something the group will see…',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final String value = _text.text.trim();
            if (value.isEmpty) return;
            Navigator.of(context).pop(value);
          },
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _ReportResult {
  final String reason;
  final String audience;
  final bool includeCopy;

  const _ReportResult(this.reason, this.audience, this.includeCopy);
}

class _ReportSheet extends StatefulWidget {
  final bool canDisclose;

  const _ReportSheet({required this.canDisclose});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final TextEditingController _reason = TextEditingController();
  String _audience = 'owner';
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
            'Report this post',
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
            decoration: const InputDecoration(
              labelText: 'What is wrong?',
              counterText: '',
            ),
          ),
          const SizedBox(height: 6),
          SegmentedButton<String>(
            segments: const <ButtonSegment<String>>[
              ButtonSegment<String>(value: 'owner', label: Text('Group owner')),
              ButtonSegment<String>(value: 'platform', label: Text('SecretMsg')),
            ],
            selected: <String>{_audience},
            onSelectionChanged: (Set<String> selection) {
              setState(() => _audience = selection.first);
            },
          ),
          if (widget.canDisclose)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeCopy,
              onChanged: (bool? value) => setState(() => _includeCopy = value ?? false),
              title: const Text(
                'Include my copy of this post with the report',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Reporting shows us this post so we can review it. Nothing else in your groups is shared.',
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
                Navigator.of(context).pop(_ReportResult(reason, _audience, _includeCopy));
              },
              child: const Text('Submit report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerToolsSheet extends StatefulWidget {
  final String groupId;
  final Map<String, dynamic> group;
  final Future<void> Function() onChanged;

  const _OwnerToolsSheet({
    required this.groupId,
    required this.group,
    required this.onChanged,
  });

  @override
  State<_OwnerToolsSheet> createState() => _OwnerToolsSheetState();
}

class _OwnerToolsSheetState extends State<_OwnerToolsSheet> {
  List<Map<String, dynamic>> _roster = <Map<String, dynamic>>[];
  bool _loadingRoster = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    try {
      final Map<String, dynamic> data = await SocialApi.getRoster(widget.groupId);
      final List<dynamic> raw = data['roster'] as List<dynamic>? ?? <dynamic>[];
      if (!mounted) return;
      setState(() {
        _roster = raw.map((dynamic e) => e as Map<String, dynamic>).toList();
        _loadingRoster = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRoster = false);
    }
  }

  Future<void> _run(Future<Map<String, dynamic>> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showSuccessSnack(context, success);
      await _loadRoster();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, e is SocialApiException ? e.message : 'That action failed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool frozen = widget.group['frozen'] == true;
    final bool memberPosting = widget.group['member_posting'] == 1;
    final List<Map<String, dynamic>> pending =
        _roster.where((Map<String, dynamic> m) => m['state'] == 'pending').toList();
    final List<Map<String, dynamic>> active =
        _roster.where((Map<String, dynamic> m) => m['state'] == 'active').toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Owner tools',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Owner actions are logged server-side as metadata for platform accountability. The roster is pseudonymous — it cannot map members to handles.',
                style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5),
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: memberPosting,
                onChanged: _busy
                    ? null
                    : (bool value) => _run(
                          () => SocialApi.updateGroupSettings(
                              widget.groupId, <String, dynamic>{'member_posting': value}),
                          value ? 'Member posting is on.' : 'Member posting is off.',
                        ),
                title: const Text('Member posting'),
                subtitle: const Text('Off by default. Members can always read and report.'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: frozen,
                onChanged: _busy
                    ? null
                    : (bool value) => _run(
                          () => SocialApi.freezeGroup(widget.groupId, value),
                          value ? 'Feed frozen.' : 'Feed open again.',
                        ),
                title: const Text('Freeze the feed'),
                subtitle: const Text('Read-only until you unfreeze. Members can still report.'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.vpn_key_outlined),
                title: const Text('Rotate the group key'),
                subtitle: const Text('Removed members cannot read posts from the new epoch.'),
                onTap: _busy
                    ? null
                    : () => _run(
                          () => SocialApi.rotateGroupKey(widget.groupId),
                          'Key rotated. Share the new group key with active members.',
                        ),
              ),
              const Divider(height: 24),
              Text(
                'Join requests (${pending.length})',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (_loadingRoster)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                )
              else if (pending.isEmpty)
                Text(
                  'No pending requests.',
                  style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                )
              else
                for (final Map<String, dynamic> member in pending)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(member['pseudonym']?.toString() ?? 'member'),
                    subtitle: const Text('Waiting for your decision'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                    () => SocialApi.decideJoinRequest(
                                        widget.groupId, member['id'] as String, 'decline'),
                                    'Request declined.',
                                  ),
                          icon: const Icon(Icons.close),
                          tooltip: 'Decline',
                        ),
                        IconButton(
                          onPressed: _busy
                              ? null
                              : () => _run(
                                    () => SocialApi.decideJoinRequest(
                                        widget.groupId, member['id'] as String, 'approve'),
                                    'Request approved.',
                                  ),
                          icon: const Icon(Icons.check),
                          tooltip: 'Approve',
                        ),
                      ],
                    ),
                  ),
              const Divider(height: 24),
              Text(
                'Members (${active.length})',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final Map<String, dynamic> member in active)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    member['is_owner'] == 1 ? Icons.star_outline : Icons.face_outlined,
                    color: member['is_owner'] == 1 ? context.colors.amber : context.colors.textMuted,
                  ),
                  title: Text(member['pseudonym']?.toString() ?? 'member'),
                  subtitle: Text(
                    member['is_owner'] == 1
                        ? 'Owner'
                        : (member['muted'] == 1 ? 'Muted' : 'Active'),
                  ),
                  trailing: member['is_owner'] == 1
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (String value) {
                            if (value == 'mute') {
                              _run(
                                () => SocialApi.muteMember(
                                    widget.groupId, member['id'] as String, member['muted'] != 1),
                                member['muted'] == 1 ? 'Unmuted.' : 'Muted.',
                              );
                            } else if (value == 'remove') {
                              _run(
                                () => SocialApi.removeMember(widget.groupId, member['id'] as String),
                                'Member removed and the key rotated.',
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'mute',
                              child: Text(member['muted'] == 1 ? 'Unmute' : 'Mute'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'remove',
                              child: Text('Remove from group'),
                            ),
                          ],
                        ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
