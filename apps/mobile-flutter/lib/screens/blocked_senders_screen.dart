import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class BlockedSendersScreen extends StatefulWidget {
  const BlockedSendersScreen({super.key});

  @override
  State<BlockedSendersScreen> createState() => _BlockedSendersScreenState();
}

class _BlockedSendersScreenState extends State<BlockedSendersScreen> {
  List<BlockedSender>? _blocked;
  bool _loading = true;
  String? _error;
  Set<String> _unblocking = {};

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
      final blocked = await ApiClient.getBlockedSenders();
      if (!mounted) return;
      setState(() {
        _blocked = blocked;
        _loading = false;
      });
    } on UnauthorizedError {
      if (!mounted) return;
      setState(() => _loading = false);
      showErrorSnack(context, 'Session expired. Please log in again.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load blocked senders.';
      });
    }
  }

  Future<void> _unblock(BlockedSender sender) async {
    final hash = sender.senderFpHash;
    if (hash.isEmpty || _unblocking.contains(hash)) return;
    setState(() => _unblocking = {..._unblocking, hash});
    try {
      await ApiClient.unblockSender(hash);
      if (!mounted) return;
      setState(() {
        _blocked = _blocked?.where((s) => s.senderFpHash != hash).toList();
        _unblocking = {..._unblocking}..remove(hash);
      });
      showSuccessSnack(context, 'Sender unblocked.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _unblocking = {..._unblocking}..remove(hash));
      showErrorSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Blocked Senders'),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 80),
        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }
    if (_error != null) {
      return Column(
        children: [
          const SizedBox(height: 80),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.roseLight)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }

    final blocked = _blocked ?? const [];
    if (blocked.isEmpty) {
      return const Column(
        children: [
          SizedBox(height: 80),
          Icon(Icons.block_outlined, size: 52, color: AppColors.textFaint),
          SizedBox(height: 12),
          Text('No blocked senders', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            'Blocked devices stay anonymous to you. They are simply prevented from sending you new messages.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Blocked devices cannot deliver messages to your inbox. Senders remain anonymous to you — you are blocking a device, not a person.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5),
        ),
        const SizedBox(height: 12),
        ...blocked.map((s) => _BlockedSenderTile(
              sender: s,
              unblocking: _unblocking.contains(s.senderFpHash),
              onUnblock: () => _unblock(s),
            )),
      ],
    );
  }
}

class _BlockedSenderTile extends StatelessWidget {
  final BlockedSender sender;
  final bool unblocking;
  final VoidCallback onUnblock;
  const _BlockedSenderTile({
    required this.sender,
    required this.unblocking,
    required this.onUnblock,
  });

  String get _label {
    final createdAt = sender.createdAt.trim();
    if (createdAt.isEmpty) return 'Blocked device';
    try {
      final t = DateTime.parse(createdAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(t);
      if (diff.inSeconds < 60) return 'Blocked just now';
      if (diff.inMinutes < 60) return 'Blocked ${diff.inMinutes} min ago';
      if (diff.inHours < 24) return 'Blocked ${diff.inHours} h ago';
      if (diff.inDays < 30) return 'Blocked ${diff.inDays} d ago';
      return 'Blocked ${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Blocked device';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accentDeep,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.devices_other, size: 19, color: AppColors.accentSoft),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                const Text(
                  'Anonymous device',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: unblocking ? null : onUnblock,
            child: unblocking
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Unblock', style: TextStyle(color: AppColors.accentSoft)),
          ),
        ],
      ),
    );
  }
}