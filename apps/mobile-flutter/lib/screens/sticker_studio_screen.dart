import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../api/config.dart';
import '../api/session.dart';
import '../data/vibe_templates.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/share_export.dart';
import '../widgets/user_avatar.dart';

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
  String _layout = 'bottom'; // top | center | bottom | card
  double _fontSize = 38;
  String _platform = 'generic'; // generic | instagram | tiktok | snapchat
  bool _showGuides = false;
  String? _identityHandle;
  String? _identitySeed;
  List<File> _recents = [];

  @override
  void initState() {
    super.initState();
    _loadIdentity();
    _loadRecents();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  /// Prefills the board link (and avatar) for signed-in owners so the
  /// studio is one-tap: pick vibe, share. Signed-out senders type a handle.
  Future<void> _loadIdentity() async {
    try {
      final user = await Session.getSavedUser();
      if (!mounted || user == null || user.username.isEmpty) return;
      setState(() {
        _identityHandle = user.username;
        _identitySeed = (user.avatarSeed == null || user.avatarSeed!.isEmpty)
            ? user.username
            : user.avatarSeed!;
        _linkCtrl.text = user.username;
      });
    } catch (_) {}
  }

  String get _boardHandle {
    final typed = _linkCtrl.text.trim();
    if (typed.isNotEmpty) return typed;
    return _identityHandle ?? 'yourname';
  }

  String get _avatarSeed {
    final typed = _linkCtrl.text.trim();
    if (typed.isNotEmpty &&
        _identityHandle != null &&
        typed.toLowerCase() == _identityHandle!.toLowerCase() &&
        _identitySeed != null) {
      return _identitySeed!;
    }
    return typed.isNotEmpty ? typed : 'secretmsg';
  }

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

  /// Content insets for the active platform preset, derived from the
  /// rendered 9:16 box so fractions stay exact at any screen size.
  EdgeInsets _insetsFor(Size box) {
    final f = _platformInsets[_platform] ?? _platformInsets['generic']!;
    return EdgeInsets.only(
      top: box.height * f[0],
      bottom: box.height * f[1],
      left: box.width * f[2],
      right: box.width * f[3],
    );
  }

  Future<void> _shareImage() async {
    final path = await capturePng(_previewKey);
    if (path == null) {
      if (mounted) showErrorSnack(context, 'Could not capture sticker');
      return;
    }
    try {
      await _keepRecent(path);
      await Share.shareXFiles(
        [XFile(path)],
        text: '$_caption\n\n${shareUrlFor(_boardHandle)}',
        subject: '$_caption\n\n${shareUrlFor(_boardHandle)}',
      );
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not share sticker');
    } finally {
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  /// Recents tray: last 6 shared/saved stickers on-device for one-tap reshare.
  Future<Directory> _recentsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}recents');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _loadRecents() async {
    try {
      final dir = await _recentsDir();
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      if (!mounted) return;
      setState(() => _recents = files.take(6).toList());
    } catch (_) {}
  }

  Future<void> _keepRecent(String pngPath) async {
    try {
      final dir = await _recentsDir();
      final name = 'sticker_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(pngPath).copy('${dir.path}${Platform.pathSeparator}$name');
      final files = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));
      for (final extra in files.skip(6)) {
        try {
          await extra.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() => _recents = files.take(6).toList());
    } catch (_) {}
  }

  Future<void> _reshareRecent(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)], text: shareUrlFor(_boardHandle));
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not share sticker');
    }
  }

  Future<void> _saveImage() async {
    File? capture;
    try {
      final hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        if (mounted) showErrorSnack(context, 'Gallery access denied — use Share instead.');
        return;
      }
      final path = await capturePng(_previewKey);
      if (path == null) {
        if (mounted) showErrorSnack(context, 'Could not capture sticker');
        return;
      }
      capture = File(path);
      await Gal.putImageBytes(await capture.readAsBytes(), name: 'secretmsg-sticker');
      if (mounted) showSuccessSnack(context, 'Sticker saved to gallery');
    } catch (_) {
      if (mounted) showErrorSnack(context, 'Could not save sticker');
    } finally {
      if (capture != null) {
        try {
          await capture.delete();
        } catch (_) {}
      }
    }
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
                Text(
                  'Build a story-worthy sticker in seconds',
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick a vibe, add your board link, and share it to your story. 9:16, ready to post.',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 12.5, height: 1.5),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (_, cons) {
                    final box = Size(cons.maxWidth, cons.maxWidth * 16 / 9);
                    return AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Stack(
                        children: [
                          RepaintBoundary(
                            key: _previewKey,
                            child: _StickerPreview(
                              caption: _caption,
                              theme: _STICKER_THEME_BY_ID[_themeId]!,
                              handle: _boardHandle,
                              seed: _avatarSeed,
                              layout: _layout,
                              fontSize: _fontSize,
                              insets: _insetsFor(box),
                            ),
                          ),
                          // Guides overlay: editor-only danger bands, never
                          // exported (the capture boundary above excludes it).
                          if (_showGuides)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: _GuidesOverlay(
                                  fractions: _platformInsets[_platform] ??
                                      _platformInsets['generic']!,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                if (_recents.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _buildRecents(),
                ],
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
                    backgroundColor: context.colors.accent,
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
                  child: Text('Save image', style: TextStyle(color: context.colors.accentSoft)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent stickers — tap to reshare',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _recents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final f = _recents[i];
              return Semantics(
                button: true,
                label: 'Reshare recent sticker ${i + 1}',
                child: GestureDetector(
                  onTap: () => _reshareRecent(f),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(f, width: 54, height: 96, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 54, height: 96)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Caption', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton.icon(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                final pick = STORY_PRESETS[DateTime.now().millisecondsSinceEpoch % STORY_PRESETS.length];
                setState(() {
                  _presetId = pick.id;
                  _captionCtrl.text = pick.text;
                });
              },
              icon: const Icon(Icons.casino, size: 15),
              label: const Text('Ideas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in STORY_PRESETS)
              ChoiceChip(
                label: Text(p.label, style: const TextStyle(fontSize: 12)),
                selected: _presetId == p.id,
                selectedColor: context.colors.accent.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _presetId == p.id ? context.colors.textPrimary : context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: _presetId == p.id ? context.colors.accent : context.colors.border),
                onSelected: (_) => _pickPreset(p.id),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Theme', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final t in STICKER_THEMES) ...[
              _ThemeSwatch(
                label: t.name,
                gradient: [for (final c in t.gradient) _parseHex(c)],
                selected: _themeId == t.id,
                onTap: () => _pickTheme(t.id),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text('Layout', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final l in const [
              ('top', Icons.vertical_align_top, 'Top'),
              ('center', Icons.vertical_align_center, 'Center'),
              ('bottom', Icons.vertical_align_bottom, 'Bottom'),
              ('card', Icons.format_quote_outlined, 'Card'),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _layout = l.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _layout == l.$1
                            ? context.colors.accent.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _layout == l.$1 ? context.colors.accent : context.colors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(l.$2, size: 18, color: _layout == l.$1 ? context.colors.textPrimary : context.colors.textSecondary),
                          const SizedBox(height: 2),
                          Text(l.$3, style: TextStyle(fontSize: 10, color: _layout == l.$1 ? context.colors.textPrimary : context.colors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Text size', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            const Spacer(),
            for (var i = 0; i < _fontSizes.length; i++)
              Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: InkWell(
                      onTap: () => setState(() => _fontSize = _fontSizes[i]),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 40,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _fontSize == _fontSizes[i]
                              ? context.colors.accent.withValues(alpha: 0.18)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _fontSize == _fontSizes[i] ? context.colors.accent : context.colors.border,
                          ),
                        ),
                        child: Text(_fontLabels[i],
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _fontSize == _fontSizes[i]
                                    ? context.colors.textPrimary
                                    : context.colors.textSecondary)),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Fits', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            const Spacer(),
            InkWell(
              onTap: () => setState(() => _showGuides = !_showGuides),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _showGuides ? context.colors.accent : context.colors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_on_outlined, size: 14,
                        color: _showGuides ? context.colors.textPrimary : context.colors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Guides',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _showGuides ? context.colors.textPrimary : context.colors.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in _platformLabels.entries)
              ChoiceChip(
                label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                selected: _platform == entry.key,
                selectedColor: context.colors.accent.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _platform == entry.key ? context.colors.textPrimary : context.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                    color: _platform == entry.key ? context.colors.accent : context.colors.border),
                onSelected: (_) => setState(() => _platform = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Your caption (optional)', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: _captionCtrl,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Custom caption… (clears to the preset if blank)',
            filled: true,
            fillColor: context.colors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.colors.border),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('Your board link', style: TextStyle(color: context.colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (_identityHandle != null)
          _AccountHandleCard(
            handle: _identityHandle!,
            seed: _identitySeed ?? _identityHandle!,
            onCopy: _copyLink,
            onShare: () => Share.share('Send me anonymous messages — ${shareUrlFor(_boardHandle)}'),
          )
        else
          TextField(
            controller: _linkCtrl,
            autocorrect: false,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixText: '$kPublicBaseUrl/',
              filled: true,
              fillColor: context.colors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.colors.border),
              ),
            ),
          ),
      ],
    );
  }
}

/// Platform safe-area insets as fractions of the 9:16 canvas. Backgrounds
/// bleed full-bleed; only content respects these, so stickers look native
/// under each app's profile bars, rails, and input rows.
const _platformInsets = {
  'generic': [0.05, 0.05, 0.05, 0.05], // top, bottom, left, right
  'instagram': [0.14, 0.18, 0.05, 0.08],
  'tiktok': [0.08, 0.25, 0.05, 0.14],
  'snapchat': [0.12, 0.16, 0.05, 0.05],
};

const _platformLabels = {
  'generic': 'Generic',
  'instagram': 'Instagram',
  'tiktok': 'TikTok',
  'snapchat': 'Snapchat',
};

const _fontSizes = [32.0, 38.0, 46.0];
const _fontLabels = ['S', 'M', 'L'];

Color _parseHex(String hex) {
  final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
  return Color(0xFF000000 | value);
}

const _STICKER_THEME_BY_ID = {
  'neon': StickerTheme('neon', 'Cyber Neon', ['#2E1065', '#1E1B4B', '#090A0F'], '#6366F1', '#818CF8'),
  'sunset': StickerTheme('sunset', 'Amber Sunset', ['#78350F', '#1E1B4B', '#090A0F'], '#F59E0B', '#FBBF24'),
  'emerald': StickerTheme('emerald', 'Emerald Velvet', ['#022C22', '#042F2E', '#090A0F'], '#10B981', '#34D399'),
  'candy': StickerTheme('candy', 'Cotton Candy', ['#831843', '#3B0764', '#090A0F'], '#EC4899', '#F9A8D4'),
  'brand': StickerTheme('brand', 'SecretMsg Violet', ['#4F46E5', '#6366F1', '#1E1B4B'], '#A5B4FC', '#C7D2FE'),
  'paper': StickerTheme('paper', 'Clean Paper', ['#FFFFFF', '#F1F5F9'], '#CBD5E1', '#6366F1', isLight: true),
  'obsidian': StickerTheme('obsidian', 'Pure Obsidian', ['#0F111A', '#090A0F'], '#FFFFFF', '#FFFFFF'),
};

class _ThemeSwatch extends StatelessWidget {
  final String label;
  final List<Color> gradient;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeSwatch({required this.label, required this.gradient, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Use $label theme',
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? context.colors.textPrimary : context.colors.borderStrong,
              width: selected ? 2 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Signed-in owner's handle card: avatar + @handle + link, with copy and
/// share actions right where the sticker is built.
class _AccountHandleCard extends StatelessWidget {
  final String handle;
  final String seed;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  const _AccountHandleCard({
    required this.handle,
    required this.seed,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        children: [
          UserAvatar(seed: seed, fallbackInitials: handle, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$handle',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
                const SizedBox(height: 2),
                Text(shareUrlFor(handle).replaceFirst('https://', ''),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: context.colors.textMuted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy link',
            onPressed: onCopy,
            icon: Icon(Icons.copy, size: 18, color: context.colors.accentSoft),
          ),
          IconButton(
            tooltip: 'Share link',
            onPressed: onShare,
            icon: Icon(Icons.ios_share, size: 18, color: context.colors.accentSoft),
          ),
        ],
      ),
    );
  }
}

/// Editor-only safe-area guides: striped danger bands for the active
/// platform preset. Never captured (lives outside the RepaintBoundary).
class _GuidesOverlay extends StatelessWidget {
  final List<double> fractions; // top, bottom, left, right
  const _GuidesOverlay({required this.fractions});

  @override
  Widget build(BuildContext context) {
    Widget band(String label) => Container(
          alignment: Alignment.center,
          color: const Color(0xFFE11D48).withValues(alpha: 0.22),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: LayoutBuilder(
        builder: (_, cons) {
          final w = cons.maxWidth;
          final h = cons.maxHeight;
          return Stack(
            children: [
              Positioned(
                  left: 0, right: 0, top: 0, height: h * fractions[0],
                  child: band('KEEP CLEAR')),
              Positioned(
                  left: 0, right: 0, bottom: 0, height: h * fractions[1],
                  child: band('KEEP CLEAR')),
              Positioned(
                  left: 0, top: h * fractions[0], bottom: h * fractions[1], width: w * fractions[2],
                  child: band('')),
              Positioned(
                  right: 0, top: h * fractions[0], bottom: h * fractions[1], width: w * fractions[3],
                  child: band('')),
            ],
          );
        },
      ),
    );
  }
}

class _StickerPreview extends StatelessWidget {
  final String caption;
  final StickerTheme theme;
  final String handle;
  final String seed;
  final String layout; // top | center | bottom | card
  final double fontSize;
  final EdgeInsets insets;
  const _StickerPreview({
    required this.caption,
    required this.theme,
    this.handle = 'yourname',
    this.seed = 'secretmsg',
    this.layout = 'bottom',
    this.fontSize = 38,
    this.insets = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final colors = [for (final c in theme.gradient) _parseHex(c)];
    final accent = _parseHex(theme.accent);
    final border = _parseHex(theme.border);
    // Paper theme carries dark ink; every other theme carries white ink.
    final ink = theme.isLight ? const Color(0xFF0F172A) : Colors.white;
    final inkSoft = theme.isLight
        ? const Color(0xFF475569)
        : Colors.white.withValues(alpha: 0.8);
    final captionBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caption,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: ink, fontSize: fontSize, fontWeight: FontWeight.w900, height: 1.1),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap here to send me an anonymous message',
          style: TextStyle(color: inkSoft, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          height: 3,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
    // Card layout wraps the caption in a quote card so no layout leaves a
    // void: the middle band is always composed.
    final Widget body = layout == 'card'
        ? Center(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (theme.isLight ? Colors.white : Colors.black).withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: border.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('“', style: TextStyle(color: accent, fontSize: 34, fontWeight: FontWeight.w900, height: 1)),
                  Text(
                    caption,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ink, fontSize: fontSize * 0.68, fontWeight: FontWeight.w800, height: 1.25),
                  ),
                ],
              ),
            ),
          )
        : captionBlock;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border.withValues(alpha: 0.6), width: 1.4),
      ),
      padding: insets,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(seed: seed, fallbackInitials: handle, size: 44),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'secretmsg.net/$handle',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(4),
                        child: QrImageView(
                          data: 'https://secretmsg.net/$handle',
                          size: 56,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (layout == 'bottom') const Spacer(),
            if (layout == 'center' || layout == 'card') const Spacer(),
            body,
            if (layout == 'center' || layout == 'card') const Spacer(),
            if (layout == 'top') const Spacer(),
          ],
        ),
      );
  }
}