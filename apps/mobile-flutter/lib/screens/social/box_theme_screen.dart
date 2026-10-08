import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'custom_handle_screen.dart';
import 'social_api.dart';
import 'social_widgets.dart';

/// Box appearance editor.
///
/// Only a fixed enum (pattern, font) or a 6-digit hex color can be chosen —
/// there is no CSS field, no font URL, no upload, and no `@font-face`. Colors
/// are gated at WCAG AA with the failing pair named before saving. Fonts are
/// Google Fonts families that SecretMsg self-hosts; this screen only ever
/// references family names.
class BoxThemeScreen extends StatefulWidget {
  const BoxThemeScreen({super.key});

  @override
  State<BoxThemeScreen> createState() => _BoxThemeScreenState();
}

const List<String> _kPatterns = <String>['none', 'dots', 'grid', 'waves', 'confetti', 'aurora'];
const List<String> _kFonts = <String>['inter', 'lora', 'space-grotesk', 'bitter', 'ibm-plex-sans'];

String _fontFamily(String id) {
  switch (id) {
    case 'lora':
      return 'Lora';
    case 'space-grotesk':
      return 'Space Grotesk';
    case 'bitter':
      return 'Bitter';
    case 'ibm-plex-sans':
      return 'IBM Plex Sans';
    case 'inter':
    default:
      return 'Inter';
  }
}

int? _hexToInt(String value) {
  final String v = value.trim();
  if (!RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(v)) return null;
  return int.parse(v.substring(1), radix: 16);
}

double _channelLuminance(int channel) {
  final double c = channel / 255;
  return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _contrast(String a, String b) {
  final int? ai = _hexToInt(a);
  final int? bi = _hexToInt(b);
  if (ai == null || bi == null) return 0;
  double lum(int value) {
    final int r = (value >> 16) & 0xFF;
    final int g = (value >> 8) & 0xFF;
    final int bl = value & 0xFF;
    return 0.2126 * _channelLuminance(r) +
        0.7152 * _channelLuminance(g) +
        0.0722 * _channelLuminance(bl);
  }

  final double la = lum(ai);
  final double lb = lum(bi);
  final double light = la > lb ? la : lb;
  final double dark = la > lb ? lb : la;
  return (light + 0.05) / (dark + 0.05);
}

class _BoxThemeScreenState extends State<BoxThemeScreen> {
  final TextEditingController _bgLight = TextEditingController(text: '#ffffff');
  final TextEditingController _bgDark = TextEditingController(text: '#0b1020');
  final TextEditingController _accentLight = TextEditingController(text: '#3730a3');
  final TextEditingController _accentDark = TextEditingController(text: '#818cf8');
  String _mode = 'platform';
  String _pattern = 'none';
  String _font = 'inter';
  bool _reactionsEnabled = true;
  bool _loading = true;
  bool _busy = false;
  bool _previewDark = true;
  String? _error;
  String? _activeHandle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bgLight.dispose();
    _bgDark.dispose();
    _accentLight.dispose();
    _accentDark.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> themeData = await SocialApi.getMyBoxTheme();
      final Map<String, dynamic>? theme = themeData['theme'] as Map<String, dynamic>?;
      final Map<String, dynamic> handleData = await SocialApi.getMyHandles();
      final List<dynamic> rawHandles = handleData['handles'] as List<dynamic>? ?? <dynamic>[];
      if (!mounted) return;
      String? active;
      final List<Map<String, dynamic>> handles =
          rawHandles.map((dynamic e) => e as Map<String, dynamic>).toList();
      for (final Map<String, dynamic> handle in handles) {
        if (handle['status'] == 'active') {
          active = handle['display_handle']?.toString() ?? handle['handle']?.toString();
        }
      }
      setState(() {
        if (theme != null) {
          _mode = theme['mode']?.toString() ?? 'platform';
          _bgLight.text = theme['background_light']?.toString() ?? _bgLight.text;
          _bgDark.text = theme['background_dark']?.toString() ?? _bgDark.text;
          _accentLight.text = theme['accent_light']?.toString() ?? _accentLight.text;
          _accentDark.text = theme['accent_dark']?.toString() ?? _accentDark.text;
          _pattern = theme['pattern']?.toString() ?? 'none';
          _font = theme['font']?.toString() ?? 'inter';
          _reactionsEnabled = theme['reactions_enabled'] != 0;
        }
        _activeHandle = active;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is SocialApiException ? e.message : 'Could not load your theme.';
      });
    }
  }

  List<String> _failures() {
    if (_mode != 'custom') return <String>[];
    final List<String> failures = <String>[];
    if (_contrast(_bgLight.text, '#0f172a') < 4.5) {
      failures.add('Body text on the light background is below 4.5:1.');
    }
    if (_contrast(_bgDark.text, '#f8fafc') < 4.5) {
      failures.add('Body text on the dark background is below 4.5:1.');
    }
    if (_contrast(_accentLight.text, _bgLight.text) < 3) {
      failures.add('The light accent is below 3:1 against the light background.');
    }
    if (_contrast(_accentDark.text, _bgDark.text) < 3) {
      failures.add('The dark accent is below 3:1 against the dark background.');
    }
    final double buttonLight = _max2(
      _contrast(_accentLight.text, '#ffffff'),
      _contrast(_accentLight.text, '#0f172a'),
    );
    if (buttonLight < 4.5) failures.add('Button text on the light accent is below 4.5:1.');
    final double buttonDark = _max2(
      _contrast(_accentDark.text, '#ffffff'),
      _contrast(_accentDark.text, '#0f172a'),
    );
    if (buttonDark < 4.5) failures.add('Button text on the dark accent is below 4.5:1.');
    return failures;
  }

  double _max2(double a, double b) => a > b ? a : b;

  void _onHexChanged(String _) {
    // Rebuild so the contrast gate and preview track the field.
    setState(() {});
  }

  Future<void> _save() async {
    if (_failures().isNotEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SocialApi.saveBoxTheme(<String, dynamic>{
        'mode': _mode,
        'background_light': _bgLight.text.trim(),
        'background_dark': _bgDark.text.trim(),
        'accent_light': _accentLight.text.trim(),
        'accent_dark': _accentDark.text.trim(),
        'pattern': _pattern,
        'font': _font,
        'reactions_enabled': _reactionsEnabled,
      });
      if (!mounted) return;
      showSuccessSnack(context, 'Saved. Your box page now shows this theme.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is SocialApiException ? e.message : 'Could not save the theme.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Color _color(String hex, Color fallback) {
    final int? value = _hexToInt(hex);
    if (value == null) return fallback;
    return Color(value | 0xFF000000);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> failures = _failures();
    final String previewBg = _previewDark ? _bgDark.text : _bgLight.text;
    final String previewAccent = _previewDark ? _accentDark.text : _accentLight.text;
    return Scaffold(
      appBar: const AppTopBar(title: 'Box appearance'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              children: <Widget>[
                if (_error != null) ...<Widget>[
                  Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12)),
                  const SizedBox(height: 10),
                ],
                GlassCard(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CustomHandleScreen()),
                    );
                    if (mounted) _load();
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.alternate_email, color: context.colors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _activeHandle == null ? 'Auto handle' : '@$_activeHandle',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _activeHandle == null
                                  ? 'Tap to claim one memorable custom handle.'
                                  : 'Manage your handle, redirects and history.',
                              style: TextStyle(color: context.colors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: context.colors.textMuted, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const SocialHonestLimitsCard(
                  lines: <String>[
                    'Theming affects the public box page only — not the app, not message content.',
                    'No font files, font URLs, custom CSS or scripts are accepted; fonts are a fixed Google Fonts list self-hosted by SecretMsg.',
                    'Patterns are low-opacity and animation stops when reduced motion is on.',
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Theme mode',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'platform', label: Text('Platform default')),
                    ButtonSegment<String>(value: 'custom', label: Text('Custom')),
                  ],
                  selected: <String>{_mode},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() => _mode = selection.first);
                  },
                ),
                if (_mode == 'custom') ...<Widget>[
                  const SizedBox(height: 16),
                  _HexField(label: 'Light background', controller: _bgLight, onChanged: _onHexChanged),
                  _HexField(label: 'Dark background', controller: _bgDark, onChanged: _onHexChanged),
                  _HexField(label: 'Light accent', controller: _accentLight, onChanged: _onHexChanged),
                  _HexField(label: 'Dark accent', controller: _accentDark, onChanged: _onHexChanged),
                  const SizedBox(height: 10),
                  Text(
                    'Pattern',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String pattern in _kPatterns)
                        ChoiceChip(
                          label: Text(pattern),
                          selected: _pattern == pattern,
                          onSelected: (_) => setState(() => _pattern = pattern),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Typeface',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final String font in _kFonts)
                        ChoiceChip(
                          label: Text(_fontFamily(font)),
                          selected: _font == font,
                          onSelected: (_) => setState(() => _font = font),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _reactionsEnabled,
                  onChanged: (bool value) => setState(() => _reactionsEnabled = value),
                  title: const Text('Allow reactions on your box'),
                  subtitle: const Text(
                    'Turning reactions off stops new ones. Existing reactions stay visible until that message is deleted.',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Preview',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(value: 'dark', label: Text('Dark')),
                    ButtonSegment<String>(value: 'light', label: Text('Light')),
                  ],
                  selected: <String>{_previewDark ? 'dark' : 'light'},
                  onSelectionChanged: (Set<String> selection) {
                    setState(() => _previewDark = selection.first == 'dark');
                  },
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _color(previewBg, context.colors.surface),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Send an anonymous message',
                        style: TextStyle(
                          color: _previewDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          fontFamily: _fontFamily(_font),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: _color(previewAccent, context.colors.accent),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Send anonymously',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                if (failures.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  for (final String failure in failures)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '\u2022 $failure',
                        style: TextStyle(color: context.colors.roseLight, fontSize: 12, height: 1.4),
                      ),
                    ),
                  Text(
                    'Saving is blocked until these pass WCAG AA (4.5:1 body text, 3:1 controls).',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_busy || failures.isNotEmpty) ? null : _save,
                    child: Text(_busy ? 'Saving…' : 'Save theme'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HexField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _HexField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: label,
          hintText: '#1a2b3c',
          helperText: 'Six-digit hex only',
        ),
        onChanged: onChanged,
      ),
    );
  }
}
