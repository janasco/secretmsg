import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'group_feed_screen.dart';
import 'social_api.dart';
import 'social_widgets.dart';

/// Group boxes: unlisted, invite-only, pseudonymous to the owner. Members join
/// with the app using an invite link plus a 6-digit code; member posting is off
/// by default and admission approval is on by default.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Map<String, dynamic>> _groups = <Map<String, dynamic>>[];
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
      final Map<String, dynamic> data = await SocialApi.listGroups();
      if (!mounted) return;
      final List<dynamic> raw = data['groups'] as List<dynamic>? ?? <dynamic>[];
      setState(() {
        _groups = raw.map((dynamic e) => e as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is SocialApiException ? e.message : 'Could not load your groups.';
      });
    }
  }

  Future<void> _openGroup(Map<String, dynamic> group) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupFeedScreen(
          groupId: group['id'] as String,
          groupName: group['name'] as String? ?? 'Group',
          isOwner: group['is_owner'] == 1,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _createGroup() async {
    final Map<String, dynamic>? created = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
    if (created == null || !mounted) return;
    showSuccessSnack(context, 'Group created. Share the invite link and code.');
    await _openGroup(created);
  }

  Future<void> _joinGroup() async {
    final Map<String, dynamic>? joined = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _JoinGroupDialog(),
    );
    if (joined == null || !mounted) return;
    final String state = joined['state']?.toString() ?? 'active';
    if (state == 'pending') {
      showSuccessSnack(context, 'Join request sent. The owner sees a pseudonym, not who you are.');
      _load();
      return;
    }
    showSuccessSnack(context, 'Joined.');
    final Map<String, dynamic>? group = joined['group'] as Map<String, dynamic>?;
    if (group != null) await _openGroup(group);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Group boxes'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const PageStorageKey<String>('groups-screen'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: <Widget>[
            const SocialHonestLimitsCard(
              lines: <String>[
                'Group feeds are sealed; the server stores ciphertext it cannot read.',
                'Filtered Words run on members\' devices and are bypassable by a modified client.',
                'Owner moderation cannot prevent screenshots, and the platform cannot pre-moderate what it cannot read.',
                'The owner sees pseudonyms, never handles. You can mute or leave without an announcement.',
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create a group'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _joinGroup,
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Join with a code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator(color: context.colors.accent)),
              )
            else if (_error != null)
              SocialErrorView(message: _error!, onRetry: _load)
            else if (_groups.isEmpty)
              const SocialEmptyState(
                icon: Icons.groups_outlined,
                title: 'No groups yet',
                body:
                    'Groups are unlisted and invite-only. Create one, or join with an invite code from a group owner.',
              )
            else
              for (final Map<String, dynamic> group in _groups) ...<Widget>[
                _GroupTile(
                  group: group,
                  onTap: () => _openGroup(group),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback onTap;

  const _GroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isOwner = group['is_owner'] == 1;
    final bool frozen = group['frozen'] == 1;
    final String pseudonym = group['pseudonym']?.toString() ?? '';
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.colors.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.forum_outlined, color: context.colors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  group['name']?.toString() ?? 'Group',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '@${group['slug']}',
                  style: TextStyle(color: context.colors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    SocialChip(label: pseudonym, icon: Icons.face_outlined),
                    if (isOwner) SocialChip(label: 'Owner', color: context.colors.amber, icon: Icons.star_outline),
                    if (frozen)
                      SocialChip(label: 'Read-only', color: context.colors.roseLight, icon: Icons.lock_outline),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _slug = TextEditingController();
  final TextEditingController _rules = TextEditingController(text: 'Be kind. No harassment, no doxxing.');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    _rules.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String name = _name.text.trim();
    final String slug = _slug.text.trim().toLowerCase();
    final String rules = _rules.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Group name must be 2-60 characters.');
      return;
    }
    if (rules.isEmpty) {
      setState(() => _error = 'Group rules are required so members know what this space is for.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> data = await SocialApi.createGroup(slug: slug, name: name, rules: rules);
      if (!mounted) return;
      final Map<String, dynamic> group = data['group'] as Map<String, dynamic>;
      Navigator.of(context).pop(<String, dynamic>{
        ...group,
        'is_owner': 1,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is SocialApiException ? e.message : 'Could not create the group.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create a group'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _name,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Group name', counterText: ''),
            ),
            TextField(
              controller: _slug,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Link name',
                prefixText: 'secretmsg.net/g/',
                counterText: '',
                helperText: '3-20 characters: a-z, 0-9, - and _',
              ),
            ),
            TextField(
              controller: _rules,
              maxLength: 500,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Rules',
                helperText: 'Required. 500 characters max.',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This creates a room where anonymous messages have one controlled home. Member posting starts off, join approval is on, and you will see pseudonyms only.',
              style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Creating…' : 'Create'),
        ),
      ],
    );
  }
}

class _JoinGroupDialog extends StatefulWidget {
  const _JoinGroupDialog();

  @override
  State<_JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<_JoinGroupDialog> {
  final TextEditingController _slug = TextEditingController();
  final TextEditingController _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _slug.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String slug = _slug.text.trim().toLowerCase();
    final String code = _code.text.replaceAll(RegExp(r'\D'), '');
    if (slug.isEmpty || code.length != 6) {
      setState(() => _error = 'Enter the group link name and the 6-digit invite code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> lookup = await SocialApi.lookupGroup(slug);
      final Map<String, dynamic> group = lookup['group'] as Map<String, dynamic>;
      final String groupId = group['id'] as String;
      final Map<String, dynamic> joined = await SocialApi.joinGroup(groupId, code);
      if (!mounted) return;
      Navigator.of(context).pop(<String, dynamic>{
        'state': joined['state'],
        'group': group,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e is SocialApiException ? e.message : 'Could not join this group.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _slug,
            decoration: const InputDecoration(
              labelText: 'Group link name',
              prefixText: 'secretmsg.net/g/',
            ),
          ),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: '6-digit invite code', counterText: ''),
          ),
          const SizedBox(height: 6),
          Text(
            'Joining requires the app. The owner approves requests and sees a pseudonym, never your handle.',
            style: TextStyle(color: context.colors.textMuted, fontSize: 11, height: 1.5),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12)),
          ],
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(_busy ? 'Joining…' : 'Join'),
        ),
      ],
    );
  }
}
