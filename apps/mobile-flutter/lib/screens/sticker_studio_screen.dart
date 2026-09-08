import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../models/models.dart';

class StickerStudioScreen extends StatefulWidget {
  final String? initialQuestion;

  const StickerStudioScreen({super.key, this.initialQuestion});

  @override
  State<StickerStudioScreen> createState() => _StickerStudioScreenState();
}

class _StickerStudioScreenState extends State<StickerStudioScreen> {
  final service = MockDataService();
  late final TextEditingController questionController;
  late StoryTheme selectedTheme;

  final sampleQuestions = [
    'send me anonymous confessions 🤫',
    'who has a secret crush on me? 👀',
    'be completely honest about our vibe ✨',
    'what song reminds you of me? 🎧',
  ];

  @override
  void initState() {
    super.initState();
    questionController = TextEditingController(
      text: widget.initialQuestion ?? 'send me anonymous confessions 🤫',
    );
    selectedTheme = service.storyThemes[0];
    questionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  void _exportSticker() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.emeraldGreen, size: 18),
            const SizedBox(width: 8),
            Text('Story card saved for Instagram & Snapchat!'),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
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
          'Story Sticker Studio',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 9:16 Vertical Story Mockup Card
              Center(
                child: Container(
                  width: 240,
                  height: 380,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      colors: selectedTheme.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sticker Top Brand Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Text('🔒', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '@${service.currentUser.username}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: selectedTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Central TBH Prompt Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selectedTheme.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              questionController.text.isEmpty
                                  ? 'Type your question…'
                                  : questionController.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: selectedTheme.textColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selectedTheme.textColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'tap to type anonymous tbh ✍️',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: selectedTheme.textColor.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Watermark Footer
                      Text(
                        'secretmsg.net',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: selectedTheme.textColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Theme Swatches
              const Text(
                'Color Palette Theme',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: service.storyThemes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final theme = service.storyThemes[idx];
                    final isSelected = selectedTheme.id == theme.id;
                    return InkWell(
                      onTap: () => setState(() => selectedTheme = theme),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDim,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryWhite : AppTheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: theme.gradientColors),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              theme.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppTheme.primaryWhite : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Question Editor
              const Text(
                'Customize Sticker Question',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.outline),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: questionController,
                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryWhite),
                  decoration: const InputDecoration(
                    hintText: 'Enter question for sticker…',
                    hintStyle: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Question Pills
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: sampleQuestions.map((q) {
                  return InkWell(
                    onTap: () => setState(() => questionController.text = q),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDim,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Text(
                        q,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Export Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _exportSticker,
                  icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF0B0E14)),
                  label: const Text(
                    'Export Story Sticker (PNG)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0B0E14),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryWhite,
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
