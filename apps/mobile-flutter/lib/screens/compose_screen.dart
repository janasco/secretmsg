import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import 'dice_screen.dart';

class ComposeScreen extends StatefulWidget {
  final String? initialPrompt;

  const ComposeScreen({super.key, this.initialPrompt});

  @override
  State<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends State<ComposeScreen> {
  late final TextEditingController messageController;
  String selectedAudience = 'Mutual';
  bool allowClue = true;
  final int maxChars = 300;

  final audiences = [
    'Close Friend',
    'A Crush',
    'Mutual',
    'Acquaintance',
  ];

  final quickEmojis = ['🤍', '🔥', '🤫', '👀', '✨', '🌹'];

  @override
  void initState() {
    super.initState();
    messageController = TextEditingController(text: widget.initialPrompt ?? '');
    messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    MockDataService().sendMessage(
      text,
      hint: allowClue ? 'Mobile / App ($selectedAudience)' : null,
    );

    // Show Double-Blind Token Confirmation Dialog
    final randomToken = 'rep_${Random().nextInt(899999) + 100000}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.outlineStrong),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.emeraldGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sent Anonymously!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryWhite,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your identity is 100% hidden. Below is your double-blind private reply token:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.key_rounded, size: 14, color: AppTheme.skyBlue),
                    const SizedBox(width: 6),
                    Text(
                      randomToken,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.skyBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Close dialog
                    Navigator.of(context).pop(); // Back to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryWhite,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B0E14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          'Compose Secret Message',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DiceScreen()),
              );
            },
            icon: const Icon(Icons.casino_rounded, size: 20, color: AppTheme.textMuted),
            tooltip: 'Dice Roulette',
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
              // Recipient Target Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceDim,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'J',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primaryWhite),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sending to @janasco',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
                        ),
                        Text(
                          'Encrypted & stateless delivery',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Audience Chips
              const Text(
                'Who are you to them?',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: audiences.map((aud) {
                  final isSelected = selectedAudience == aud;
                  return ChoiceChip(
                    label: Text(aud),
                    selected: isSelected,
                    onSelected: (_) => setState(() => selectedAudience = aud),
                    backgroundColor: AppTheme.surfaceDim,
                    selectedColor: AppTheme.primaryWhite,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF0B0E14) : AppTheme.primaryWhite,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryWhite : AppTheme.outline,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // Text Area Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.outlineStrong),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: messageController,
                      maxLength: maxChars,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 14, color: AppTheme.primaryWhite, height: 1.4),
                      decoration: const InputDecoration(
                        hintText: 'Type your honest confession, compliment, or question here…',
                        hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        border: InputBorder.none,
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quick Emoji Reactions
                        Row(
                          children: quickEmojis.map((emoji) {
                            return InkWell(
                              onTap: () {
                                messageController.text += ' $emoji';
                                messageController.selection = TextSelection.fromPosition(
                                  TextPosition(offset: messageController.text.length),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(emoji, style: const TextStyle(fontSize: 16)),
                              ),
                            );
                          }).toList(),
                        ),
                        // Character Counter
                        Text(
                          '${messageController.text.length}/$maxChars',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: messageController.text.length > maxChars * 0.9
                                ? AppTheme.wholesomeRose
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Clue Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDim,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 16, color: AppTheme.textMuted),
                        SizedBox(width: 8),
                        Text(
                          'Include Broad Clue (Device & General Audience)',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Switch(
                      value: allowClue,
                      onChanged: (v) => setState(() => allowClue = v),
                      activeColor: AppTheme.primaryWhite,
                      activeTrackColor: AppTheme.surfaceHigh,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Send Action Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: messageController.text.trim().isNotEmpty ? _sendMessage : null,
                  icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF0B0E14)),
                  label: const Text(
                    'Send Anonymously',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B0E14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryWhite,
                    disabledBackgroundColor: AppTheme.primaryWhite.withOpacity(0.3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
