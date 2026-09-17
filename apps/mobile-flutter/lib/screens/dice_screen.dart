import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/roulette_data.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'send_screen.dart';

/// Dice Prompt Roulette: pick a vibe, roll, get one question. No browsing —
/// the pool (9k prompts) stays behind the button.
class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  String _category = RouletteData.allKey;
  String? _current;
  bool _rolling = false;
  static final _rand = Random();

  List<RouletteCategory>? _categories;
  Object? _loadError;
  List<String> _history = [];
  bool _soundOn = true;
  final _sfx = AudioPlayer();

  static const _historyKey = 'dice_history';

  static const _categoryIcons = {
    'all': '🎲',
    'crush': '💘',
    'spicy': '🌶️',
    'secrets': '🤫',
    'chaotic': '🌪️',
    'realtalk': '💬',
    'latenight': '🌙',
  };

  @override
  void initState() {
    super.initState();
    _loadPrompts();
    _loadHistory();
    _loadSoundPref();
  }

  @override
  void dispose() {
    _sfx.dispose();
    super.dispose();
  }

  Future<void> _loadSoundPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _soundOn = prefs.getBool('dice_sound') ?? true);
    } catch (_) {}
  }

  Future<void> _toggleSound() async {
    setState(() => _soundOn = !_soundOn);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dice_sound', _soundOn);
    } catch (_) {}
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List).map((e) => e.toString()).toList();
      if (!mounted) return;
      setState(() => _history = list.take(8).toList());
    } catch (_) {}
  }

  Future<void> _pushHistory(String text) async {
    final next = [text, ..._history.where((h) => h != text)].take(8).toList();
    setState(() => _history = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, jsonEncode(next));
    } catch (_) {}
  }

  Future<void> _tick() async {
    if (!_soundOn) return;
    try {
      await _sfx.play(AssetSource('sounds/tick.wav'));
    } catch (_) {}
  }

  Future<void> _chime() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    if (!_soundOn) return;
    try {
      await _sfx.play(AssetSource('sounds/chime.wav'));
    } catch (_) {}
  }

  Future<void> _loadPrompts() async {
    setState(() => _loadError = null);
    try {
      final categories = await RouletteData.load();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e);
    }
  }

  List<String> get _pool {
    final categories = _categories;
    if (categories == null) return const <String>[];
    for (final c in categories) {
      if (c.key == _category) return c.prompts;
    }
    return categories.first.prompts;
  }

  void _roll() {
    if (_rolling || _pool.isEmpty) return;
    setState(() {
      _rolling = true;
      _current = null;
    });
    var spins = 0;
    final target = _rand.nextInt(_pool.length);
    Timer.periodic(
      const Duration(milliseconds: 110),
      (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _current = _pool[_rand.nextInt(_pool.length)]);
        unawaited(_tick());
        spins++;
        if (spins >= 12) {
          t.cancel();
          setState(() {
            _current = _pool[target];
            _rolling = false;
          });
          unawaited(_chime());
          unawaited(_pushHistory(_pool[target]));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    return Scaffold(
      appBar: const AppTopBar(title: 'Dice Prompt Roulette'),
      body: categories == null ? _buildPlaceholder() : _buildGame(categories),
    );
  }

  Widget _buildPlaceholder() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load the prompt pool.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.colors.textHigh, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadPrompts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Center(
      child: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.accentFaint),
      ),
    );
  }

  Widget _buildGame(List<RouletteCategory> categories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Spin the dice, drop the question',
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: _soundOn ? 'Mute sounds' : 'Unmute sounds',
                    onPressed: _toggleSound,
                    icon: Icon(
                      _soundOn ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                      size: 20,
                      color: context.colors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a vibe, roll, and send the question it lands on.',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 18),
              // Vibe picker: icons only.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final c in categories)
                    _VibeIcon(
                      emoji: _categoryIcons[c.key] ?? '🎲',
                      label: c.label,
                      selected: _category == c.key,
                      onTap: () => setState(() {
                        _category = c.key;
                        _current = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _DiceButton(rolling: _rolling, onRoll: _roll),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _current != null
                    ? _PromptCard(
                        key: ValueKey(_current),
                        text: _current!,
                        onSend: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SendScreen(initialMessage: _current),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              if (_history.isNotEmpty) ...[
                const SizedBox(height: 18),
                _buildHistory(),
              ],
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent rolls — tap to reuse',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in _history)
              ActionChip(
                label: Text(
                  h.length > 28 ? '${h.substring(0, 28)}…' : h,
                  style: const TextStyle(fontSize: 11.5),
                ),
                onPressed: () => setState(() => _current = h),
                backgroundColor: context.colors.surface,
                side: BorderSide(color: context.colors.border),
                labelStyle: TextStyle(color: context.colors.textSecondary),
              ),
          ],
        ),
      ],
    );
  }

}

class _VibeIcon extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _VibeIcon({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? context.colors.accent.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: selected ? context.colors.accent : context.colors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 22)),
        ),
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  final bool rolling;
  final VoidCallback onRoll;
  const _DiceButton({required this.rolling, required this.onRoll});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: rolling ? null : onRoll,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: rolling
                ? [const Color(0xFF4F46E5), const Color(0xFF7C3AED)]
                : [const Color(0xFF6366F1), const Color(0xFFF59E0B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.accent.withValues(alpha: 0.25),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                rolling ? Icons.casino : Icons.casino_outlined,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(height: 6),
              Text(
                rolling ? 'Rolling…' : 'Roll the dice',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String text;
  final VoidCallback onSend;
  const _PromptCard({super.key, required this.text, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: TextStyle(color: context.colors.textPrimary, fontSize: 17, fontWeight: FontWeight.w800, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => copyToClipboard(context, text, message: 'Prompt copied'),
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onSend,
                icon: const Icon(Icons.send, size: 15),
                label: const Text('Use in composer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: context.colors.accent,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
