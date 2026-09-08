import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';
import '../models/models.dart';
import 'compose_screen.dart';
import 'sticker_studio_screen.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final service = MockDataService();

  late PromptTemplate currentPrompt;
  int diceFace = 6;
  bool isRolling = false;

  final diceDots = {
    1: [const Offset(0, 0)],
    2: [const Offset(-0.4, -0.4), const Offset(0.4, 0.4)],
    3: [const Offset(-0.4, -0.4), const Offset(0, 0), const Offset(0.4, 0.4)],
    4: [
      const Offset(-0.4, -0.4),
      const Offset(0.4, -0.4),
      const Offset(-0.4, 0.4),
      const Offset(0.4, 0.4),
    ],
    5: [
      const Offset(-0.4, -0.4),
      const Offset(0.4, -0.4),
      const Offset(0, 0),
      const Offset(-0.4, 0.4),
      const Offset(0.4, 0.4),
    ],
    6: [
      const Offset(-0.4, -0.5),
      const Offset(-0.4, 0),
      const Offset(-0.4, 0.5),
      const Offset(0.4, -0.5),
      const Offset(0.4, 0),
      const Offset(0.4, 0.5),
    ],
  };

  @override
  void initState() {
    super.initState();
    currentPrompt = service.templates[0];
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rollDice() {
    if (isRolling) return;
    setState(() => isRolling = true);
    _controller.forward(from: 0.0).then((_) {
      final rand = Random();
      setState(() {
        diceFace = rand.nextInt(6) + 1;
        currentPrompt = service.templates[rand.nextInt(service.templates.length)];
        isRolling = false;
      });
    });
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
          'Roulette & Dice',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const Text(
                'Shake the dice to unlock unfiltered candid prompts for your friends & crushes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),

              const SizedBox(height: 28),

              // Animated 3D-Styled Dice Cube
              GestureDetector(
                onTap: _rollDice,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final rotation = _animation.value * pi * 4;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateX(rotation)
                        ..rotateY(rotation),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryWhite,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: DiceFacePainter(dots: diceDots[diceFace] ?? []),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: _rollDice,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppTheme.primaryWhite),
                label: const Text(
                  'Tap or Shake to Roll',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryWhite),
                ),
              ),

              const SizedBox(height: 24),

              // Result Prompt Card
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDim,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.outline),
                          ),
                          child: Text(
                            '${currentPrompt.emoji} ${currentPrompt.category.toUpperCase()}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: AppTheme.skyBlue,
                            ),
                          ),
                        ),
                        const Text(
                          'Rolled Prompt',
                          style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentPrompt.promptText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryWhite,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ComposeScreen(initialPrompt: currentPrompt.promptText),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 14, color: Color(0xFF0B0E14)),
                              label: const Text(
                                'Send Message',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B0E14),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryWhite,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StickerStudioScreen(initialQuestion: currentPrompt.promptText),
                                ),
                              );
                            },
                            icon: const Icon(Icons.photo_filter_rounded, size: 16, color: AppTheme.primaryWhite),
                            label: const Text(
                              'Sticker',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryWhite),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppTheme.outlineStrong),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Category Prompt Quick Pool
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Popular Prompt Pool',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: service.templates.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final item = service.templates[idx];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentPrompt = item;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDim,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.outline),
                      ),
                      child: Row(
                        children: [
                          Text(item.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.promptText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryWhite),
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiceFacePainter extends CustomPainter {
  final List<Offset> dots;

  DiceFacePainter({required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B0E14)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const radius = 6.0;

    for (final dot in dots) {
      final pos = Offset(
        center.dx + dot.dx * (size.width * 0.6),
        center.dy + dot.dy * (size.height * 0.6),
      );
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
