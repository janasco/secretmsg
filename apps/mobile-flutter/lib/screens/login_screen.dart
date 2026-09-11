import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../theme.dart';
import 'app_shell.dart';
import 'backup_codes_screen.dart';
import 'recovery_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool showRecovery;
  const LoginScreen({super.key, this.showRecovery = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _handleCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isRecovery = false;

  @override
  void initState() {
    super.initState();
    _isRecovery = widget.showRecovery;
  }

  @override
  void dispose() {
    _handleCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final handle = _handleCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'PIN must be 4-6 digits');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiClient.authSignup(handle: handle, pin: pin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => BackupCodesScreen(
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
      setState(() { _loading = false; _error = 'Could not reach SecretMsg. Check your connection.'; });
    }
  }

  Future<void> _handleLogin() async {
    final handle = _handleCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (handle.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Enter your handle and PIN');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiClient.authLogin(handle: handle, pin: pin);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell(initialTab: AppTab.inbox)),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Login failed. Please try again.'; });
    }
  }

  Future<void> _handleRecovery() async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RecoveryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRecovery ? 'Recover Account' : 'SecretMsg')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isRecovery ? 'Recover with backup code' : 'Your secret link, protected by PIN',
                  style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecovery
                      ? 'Enter your handle and one of your backup codes to set a new PIN.'
                      : 'No email needed. Choose a handle, set a PIN, and save your backup codes.',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.55),
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
                TextField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  enabled: !_loading,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: _isRecovery ? 'Backup Code' : 'PIN',
                    hintText: _isRecovery ? 'XXXX-XXXX' : '4-6 digits',
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
                    counterText: '',
                  ),
                  onSubmitted: (_) => _isRecovery ? _handleRecovery() : _handleLogin(),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading ? null : (_isRecovery ? _handleRecovery : _handleLogin),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isRecovery ? 'Recover Account' : 'Log In', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.5)),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => setState(() { _isRecovery = !_isRecovery; _error = null; }),
                  child: Text(
                    _isRecovery ? 'Back to login' : 'Forgot PIN? Recover account',
                    style: const TextStyle(color: Color(0xFFA5B4FC)),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF1E293B)),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loading ? null : _handleSignup,
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 18),
                  label: const Text('Create new account', style: TextStyle(color: Color(0xFF10B981))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
