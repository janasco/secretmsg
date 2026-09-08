import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../models/models.dart';
import 'message_detail_screen.dart';
import 'settings_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final service = MockDataService();
  String selectedFilter = 'All';

  final filters = ['All', 'Unread', 'Pinned'];

  @override
  void initState() {
    super.initState();
    service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    service.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = service.messages.where((m) {
      if (selectedFilter == 'Unread') return !m.isRead;
      if (selectedFilter == 'Pinned') return m.isPinned;
      return true;
    }).toList();

    final totalCount = service.messages.length;
    final unreadCount = service.messages.where((m) => !m.isRead).length;
    final pinnedCount = service.messages.where((m) => m.isPinned).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Secret Inbox',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20, color: AppTheme.textMuted),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KPI Metrics Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _buildMetricCard('Total', '$totalCount', AppTheme.skyBlue),
                  const SizedBox(width: 8),
                  _buildMetricCard('Unread', '$unreadCount', AppTheme.wholesomeRose),
                  const SizedBox(width: 8),
                  _buildMetricCard('Pinned', '$pinnedCount', AppTheme.amberGold),
                ],
              ),
            ),

            // Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: filters.map((f) {
                  final isSelected = selectedFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => selectedFilter = f),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryWhite : AppTheme.surfaceDim,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryWhite : AppTheme.outline,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF0B0E14) : AppTheme.primaryWhite,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),

            // Messages Feed
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: AppTheme.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'No messages in this folder',
                            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final msg = filtered[idx];
                        return _buildMessageCard(context, msg);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, SecretMessage msg) {
    return InkWell(
      onTap: () {
        service.markAsRead(msg.id);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => MessageDetailScreen(message: msg)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: !msg.isRead ? AppTheme.primaryWhite.withOpacity(0.4) : AppTheme.outline,
            width: !msg.isRead ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (!msg.isRead) ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.wholesomeRose,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      msg.deviceHint ?? 'Anonymous Sender',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (msg.isPinned) ...[
                      const Icon(Icons.push_pin_rounded, size: 12, color: AppTheme.amberGold),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      _formatTime(msg.createdAt),
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              msg.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: !msg.isRead ? FontWeight.w700 : FontWeight.w500,
                color: AppTheme.primaryWhite,
                height: 1.35,
              ),
            ),
            if (msg.replyContent != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDim,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reply_rounded, size: 12, color: AppTheme.skyBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'You: ${msg.replyContent!}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
