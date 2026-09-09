import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/roulette_data.dart';
import '../theme.dart';
import '../widgets/common.dart';

class DiceScreen extends StatefulWidget {
  const DiceScreen({super.key});

  @override
  State<DiceScreen> createState() => _DiceScreenState();
}

class _DiceScreenState extends State<DiceScreen> {
  String _category = 'all';
  String? _current;
  bool _rolling = false;
  int _visible = 30;
  static final _rand = Random();

  List<RouletteCategory>? _categories;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadPrompts();
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
        spins++;
        if (spins >= 12) {
          t.cancel();
          setState(() {
            _current = _pool[target];
            _rolling = false;
          });
        }
      },
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
              const Text(
                'Could not load the prompt pool.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadPrompts, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return const Center(
      child: SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF818CF8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    if (categories == null) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Dice Prompt Roulette'),
        body: _buildPlaceholder(),
      );
    }
    return Scaffold(
      appBar: const AppTopBar(title: 'Dice Prompt Roulette'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Spin the dice, drop the question',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'One roll summons a random question from the pool. Copy it, tweak it, or send it straight to the composer.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 18),
                _DiceButton(rolling: _rolling, onRoll: _roll),
                const SizedBox(height: 20),
                if (_current != null) ...[
                  _PromptCard(text: _current!),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Browse the pool — ${_formatCount(_pool.length)}',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ChoiceChip(
                      label: Text(c.label, style: const TextStyle(fontSize: 12)),
                      selected: _category == c.key,
                      selectedColor: AppColors.accent.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _category == c.key ? Colors.white : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(color: _category == c.key ? AppColors.accent : AppColors.border),
                      onSelected: (_) => setState(() {
                        _category = c.key;
                        _visible = 30;
                        _current = null;
                      }),
                    ),
                  ),
                const SizedBox(height: 6),
                for (final p in _pool.take(_visible)) ...[
                  _PoolTile(text: p),
                  const SizedBox(height: 8),
                ],
                if (_visible < _pool.length) ...[
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () => setState(() => _visible += 30),
                    child: const Text('Load more', style: TextStyle(color: Color(0xFFA5B4FC))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k+ prompts' : '$n prompts';
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
              color: AppColors.accent.withOpacity(0.25),
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
  const _PromptCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1220),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => copyToClipboard(context, text, message: 'Prompt copied'),
                icon: const Icon(Icons.copy, size: 15),
                label: const Text('Copy'),
              ),
              const Spacer(),
              const Text('cleared', style: TextStyle(color: Color(0xFF10B981), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoolTile extends StatelessWidget {
  final String text;
  const _PoolTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1220),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(text, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            onPressed: () => copyToClipboard(context, text, message: 'Prompt copied'),
            icon: const Icon(Icons.copy, size: 13),
            label: const Text('Copy', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}