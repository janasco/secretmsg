import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../models/models.dart';
import 'sticker_studio_screen.dart';

class MessageDetailScreen extends StatefulWidget {
  final SecretMessage message;

  const MessageDetailScreen({super.key, required this.message});

  @override
  State<MessageDetailScreen> createState() => _MessageDetailScreenState();
}

class _MessageDetailScreenState extends State<MessageDetailScreen> {
  final service = MockDataService();
  final TextEditingController replyController = TextEditingController();
  bool isReplying = false;

  @override
  void dispose() {
    replyController.dispose();
    super.dispose();
  }

  void _sendReply() {
    final reply = replyController.text.trim();
    if (reply.isEmpty) return;

    service.replyToMessage(widget.message.id, reply);
    replyController.clear();
    setState(() => isReplying = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Double-blind reply delivered securely!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E293B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Anonymous Message',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
        actions: [
          IconButton(
            onPressed: () {
              service.togglePin(widget.message.id);
              setState(() {});
            },
            icon: Icon(
              widget.message.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              size: 20,
              color: widget.message.isPinned ? AppTheme.amberGold : AppTheme.textMuted,
            ),
            tooltip: widget.message.isPinned ? 'Unpin' : 'Pin',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outlineStrong),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, size: 14, color: AppTheme.emeraldGreen),
                            const SizedBox(width: 6),
                            Text(
                              widget.message.deviceHint ?? 'Anonymous Sender',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDate(widget.message.createdAt),
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.message.content,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryWhite,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Export to Story Button
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StickerStudioScreen(initialQuestion: widget.message.content),
                            ),
                          );
                        },
                        icon: const Icon(Icons.photo_filter_rounded, size: 14, color: AppTheme.primaryWhite),
                        label: const Text(
                          'Share to Instagram Story',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryWhite),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.outlineStrong),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Double-Blind Reply Section
              const Text(
                'Double-Blind Anonymous Reply',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),

              if (widget.message.replyContent != null) ...[
                // Existing Reply Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDim,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.reply_rounded, size: 14, color: AppTheme.skyBlue),
                              SizedBox(width: 6),
                              Text(
                                'Your Reply',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.skyBlue,
                                ),
                              ),
                            ],
                          ),
                          if (widget.message.replyAt != null)
                            Text(
                              _formatDate(widget.message.replyAt!),
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.message.replyContent!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryWhite,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Composer Input
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.outline),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: replyController,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 13, color: AppTheme.primaryWhite),
                        decoration: const InputDecoration(
                          hintText: 'Write your reply… sender will check privately via their token.',
                          hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          border: InputBorder.none,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          height: 34,
                          child: ElevatedButton.icon(
                            onPressed: _sendReply,
                            icon: const Icon(Icons.send_rounded, size: 12, color: Color(0xFF0B0E14)),
                            label: const Text(
                              'Send Reply',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0B0E14),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryWhite,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
