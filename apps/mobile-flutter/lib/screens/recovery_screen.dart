import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../theme.dart';
import 'backup_codes_screen.dart';

class RecoveryScreen extends StatefulWidget {
  final String initialHandle;
  final String initialCode;
  const RecoveryScreen({super.key, this.initialHandle = '', this.initialCode = ''});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _handleCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _handleCtrl.text = widget.initialHandle;
    _codeCtrl.text = widget.initialCode;
  }

  @override
  void dispose() {
    _handleCtrl.dispose();
    _codeCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _recover() async {
    final handle = _handleCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (handle.isEmpty || code.isEmpty || pin.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'New PIN must be 4-6 digits');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiClient.authRecover(handle: handle, backupCode: code, newPin: pin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => BackupCodesScreen(
          handle: result.handle,
          backupCodes: result.backupCodes,
        )),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Recovery failed. Please try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recover Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Use a backup code to recover your account',
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 19, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your handle, one of your backup codes, and set a new PIN.',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _handleCtrl,
                  autocorrect: false,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: 'Handle',
                    hintText: 'lumen4821',
                    filled: true,
                    fillColor: context.colors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeCtrl,
                  autocorrect: false,
                  enabled: !_loading,
                  decoration: InputDecoration(
                    labelText: 'Backup Code',
                    hintText: 'XXXX-XXXX',
                    filled: true,
                    fillColor: context.colors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  enabled: !_loading,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'New PIN',
                    hintText: '4-6 digits',
                    filled: true,
                    fillColor: context.colors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.colors.border)),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading ? null : _recover,
                  child: _loading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textPrimary))
                      : const Text('Recover Account', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12, height: 1.5)),
                ],
                const SizedBox(height: 16),
                Text(
                  'Lost your backup codes as well? Without them — and without your PIN — an account cannot be recovered by anyone, including us. You can always create a fresh inbox.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
