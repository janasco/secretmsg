import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';
import 'app_shell.dart';

/// Backup codes gate: the Continue button stays disabled until the user
/// confirms they saved the codes (screenshot, .txt file, or written down).
/// Codes are shown once — losing them without the PIN means losing the
/// account, so this screen refuses to be skipped accidentally.
class BackupCodesScreen extends StatefulWidget {
  final String handle;
  final List<String> backupCodes;
  const BackupCodesScreen({super.key, required this.handle, required this.backupCodes});

  @override
  State<BackupCodesScreen> createState() => _BackupCodesScreenState();
}

class _BackupCodesScreenState extends State<BackupCodesScreen> {
  bool _saved = false;
  bool _saving = false;

  Future<void> _saveTxt() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}secretmsg-backup-codes-${widget.handle}.txt');
      await file.writeAsString(
        'SecretMsg backup codes for secretmsg.net/${widget.handle}\n'
        'Each code works once. Keep this file somewhere safe.\n\n'
        '${widget.backupCodes.join('\n')}\n',
      );
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'SecretMsg backup codes',
        text: 'My SecretMsg backup codes — keep these safe.',
      );
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the file — take a screenshot instead.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _continue() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell(initialTab: AppTab.inbox)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Your Backup Codes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF101A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These codes will NEVER be shown again. Without them and without your PIN, your account is gone forever. Each code works once.',
                          style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your link: secretmsg.net/${widget.handle}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1220),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < widget.backupCodes.length; i += 2)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.backupCodes[i],
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (i + 1 < widget.backupCodes.length)
                                Expanded(
                                  child: Text(
                                    widget.backupCodes[i + 1],
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace', fontWeight: FontWeight.w600),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.backupCodes.join('\n')));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied — paste them somewhere safe, then confirm below.')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy all'),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _saveTxt,
                        icon: const Icon(Icons.save_alt, size: 16),
                        label: Text(_saving ? 'Saving…' : 'Save .txt'),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _saved,
                  onChanged: (v) => setState(() => _saved = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.accent,
                  title: const Text(
                    'I saved my codes (screenshot or file)',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _saved ? _continue : null,
                  child: const Text('Continue to my inbox', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
