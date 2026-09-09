import 'package:flutter/material.dart';

import '../api/config.dart';
import '../data/vibe_templates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/share_export.dart';

class StickerStudioScreen extends StatefulWidget {
  const StickerStudioScreen({super.key});

  @override
  State<StickerStudioScreen> createState() => _StickerStudioScreenState();
}

class _StickerStudioScreenState extends State<StickerStudioScreen> {
  final _captionCtrl = TextEditingController();
  final _linkCtrl = TextEditingController(text: 'yourname');
  final _previewKey = GlobalKey();

  String _presetId = 'tbh';
  String _themeId = 'neon';

  String get _caption {
    final custom = _captionCtrl.text.trim().replaceAll('\n', ' ').trim();
    if (custom.isNotEmpty) return custom;
    return STORY_PRESETS.firstWhere((p) => p.id == _presetId).text;
  }

  void _pickPreset(String id) {
    setState(() => _presetId = id);
  }

  void _pickTheme(String id) {
    setState(() => _themeId = id);
  }

  Future<void> _shareImage() async {
    final ok = await sharePng(_previewKey, subject: '${_caption}\n\n${shareUrlFor(_linkCtrl.text.trim().isNotEmpty ? _linkCtrl.text.trim() : 'yourname')}');
    if (!ok && mounted) showErrorSnack(context, 'Could not capture sticker');
  }

  Future<void> _saveImage() async {
    showErrorSnack(context, 'Saving to gallery…');
    final ok = await sharePng(_previewKey, subject: 'Story sticker — $kPublicBaseUrl');
    if (!ok && mounted) showErrorSnack(context, 'Could not capture sticker');
  }

  void _copyLink() {
    final board = _linkCtrl.text.trim();
    final link = shareUrlFor(board.isEmpty ? 'yourname' : board);
    copyToClipboard(context, link, message: 'Link copied');
  }

  void _copyCaption() {
    copyToClipboard(context, _caption, message: 'Caption copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Sticker Studio'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Build a story-worthy sticker in seconds',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pick a vibe, add your board link, and share it to your story. 9:16, ready to post.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 20),
                RepaintBoundary(
                  key: _previewKey,
                  child: _StickerPreview(caption: _caption, theme: _STICKER_THEME_BY_ID[_themeId]!),
                ),
                const SizedBox(height: 16),
                _buildPresets(),
                const SizedBox(height: 16),
                _buildOptions(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyCaption,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy caption'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyLink,
                        icon: const Icon(Icons.link, size: 16),
                        label: const Text('Copy link'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _shareImage,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share sticker to story', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saveImage,
                  child: const Text('Save image', style: TextStyle(color: Color(0xFFA5B4FC))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresets() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
for (final p in STORY_PRESETS)
          ChoiceChip(
            label: Text(p.label, style: const TextStyle(fontSize: 12)),
            selected: _presetId == p.id,
            selectedColor: AppColors.accent.withOpacity(0.2),
            labelStyle: TextStyle(
              color: _presetId == p.id ? Colors.white : const Color(0xFF94A3B8),
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: _presetId == p.id ? AppColors.accent : AppColors.border),
            onSelected: (_) => _pickPreset(p.id),
          ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final t in STICKER_THEMES) ...[
              _ThemeSwatch(
                gradient: [for (final c in t.gradient) _parseHex(c)],
                selected: _themeId == t.id,
                onTap: () => _pickTheme(t.id),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 16),
        const Text('Your caption (optional)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _captionCtrl,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Custom caption… (clears to the preset if blank)',
            filled: true,
            fillColor: const Color(0xFF0F1220),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Your board link', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _linkCtrl,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: '$kPublicBaseUrl/',
            filled: true,
            fillColor: const Color(0xFF0F1220),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}

Color _parseHex(String hex) {
  final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
  return Color(0xFF000000 | value);
}

const _STICKER_THEME_BY_ID = {
  'neon': StickerTheme('neon', 'Cyber Neon', ['#2E1065', '#1E1B4B', '#090A0F'], '#6366F1', '#818CF8'),
  'sunset': StickerTheme('sunset', 'Amber Sunset', ['#78350F', '#1E1B4B', '#090A0F'], '#F59E0B', '#FBBF24'),
  'emerald': StickerTheme('emerald', 'Emerald Velvet', ['#022C22', '#042F2E', '#090A0F'], '#10B981', '#34D399'),
  'candy': StickerTheme('candy', 'Cotton Candy', ['#831843', '#3B0764', '#090A0F'], '#EC4899', '#F9A8D4'),
  'obsidian': StickerTheme('obsidian', 'Pure Obsidian', ['#0F111A', '#090A0F'], '#FFFFFF', '#FFFFFF'),
};

class _ThemeSwatch extends StatelessWidget {
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeSwatch({required this.gradient, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.white : const Color(0xFF334155),
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

class _StickerPreview extends StatelessWidget {
  final String caption;
  final StickerTheme theme;
  const _StickerPreview({required this.caption, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = [for (final c in theme.gradient) _parseHex(c)];
    final accent = _parseHex(theme.accent);
    final border = _parseHex(theme.border);
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border.withOpacity(0.6), width: 1.4),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Text('S', style: TextStyle(color: _parseHex('#090A0F'), fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'secretmsg.net',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              caption,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900, height: 1.1),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap here to send me an anonymous message',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              height: 3,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.7),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}