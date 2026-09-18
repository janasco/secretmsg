import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../theme.dart';
import 'app_shell.dart';
import 'backup_codes_screen.dart';
import 'recovery_screen.dart';
import 'supporters_screen.dart';

/// Auth entry: signup-first when [signup] is true (welcome flow), login
/// otherwise. Handles are optional at signup — empty means the server
/// auto-generates one (e.g. lumen4821); custom names are a supporter perk.
class LoginScreen extends StatefulWidget {
  final bool showRecovery;
  final bool signup;
  const LoginScreen({super.key, this.showRecovery = false, this.signup = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _handleCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _isRecovery = false;
  late bool _isSignup;

  @override
  void initState() {
    super.initState();
    _isRecovery = widget.showRecovery;
    _isSignup = widget.signup && !widget.showRecovery;
  }

  @override
  void dispose() {
    _handleCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final pin = _pinCtrl.text.trim();
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'PIN must be 4-6 digits');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // No handle field: every account gets an auto-generated link.
      // Custom names are claimed later as a supporter perk in settings.
      final result = await ApiClient.authSignup(pin: pin);
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
    // Forward whatever the user already typed so RecoveryScreen starts
    // prefilled instead of discarding the input (recovery needs handle +
    // backup code + new PIN, while this screen only holds handle + PIN).
    final handle = _handleCtrl.text.trim();
    final code = _pinCtrl.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecoveryScreen(initialHandle: handle, initialCode: code),
      ),
    );
  }

  void _switchMode({required bool signup}) {
    setState(() {
      _isSignup = signup;
      _isRecovery = false;
      _error = null;
    });
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
                  _isRecovery
                      ? 'Recover with backup code'
                      : _isSignup
                          ? 'Create your inbox'
                          : 'Welcome back',
                  style: TextStyle(color: context.colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecovery
                      ? 'Enter your handle and one of your backup codes to set a new PIN.'
                      : _isSignup
                          ? 'Set a PIN — no email needed. Your link is auto-generated; custom names are a supporter perk.'
                          : 'Your secret link, protected by PIN.',
                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 20),
                if (_isSignup) _pinField(login: false),
                if (_isSignup) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your link (like secretmsg.net/lumen4821) is created for you automatically.',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SupportersScreen()),
                    ),
                    child: Text(
                      'Want your own name instead? Custom handles are a supporter perk — learn more.',
                      style: TextStyle(color: context.colors.accentSoft, fontSize: 12, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  TextField(
                    controller: _handleCtrl,
                    autocorrect: false,
                    enabled: !_loading,
                    decoration: InputDecoration(
                      labelText: 'Handle',
                      hintText: 'lumen4821',
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
                  const SizedBox(height: 8),
                ],
                // Recovery needs handle + backup code + new PIN (3 fields on the
                // next screen). Only the handle is collected here; the PIN field
                // below is login-only so backup codes are never typed into a
                // digits-only obscured field.
                if (!_isRecovery && !_isSignup) ...[
                  const SizedBox(height: 12),
                  _pinField(login: true),
                ] else if (_isRecovery) ...[
                  const SizedBox(height: 8),
                  Text(
                    'You only need your handle here — the backup code and new PIN go on the next screen.',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12, height: 1.5),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _loading
                      ? null
                      : (_isRecovery ? _handleRecovery : (_isSignup ? _handleSignup : _handleLogin)),
                  child: _loading
                      ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.textPrimary))
                      : Text(
                          _isRecovery ? 'Recover Account' : (_isSignup ? 'Create my inbox' : 'Log In'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: context.colors.roseLight, fontSize: 12, height: 1.5)),
                ],
                const SizedBox(height: 16),
                if (!_isRecovery) ...[
                  TextButton(
                    onPressed: () => _switchMode(signup: !_isSignup),
                    child: Text(
                      _isSignup ? 'I already have an inbox — log in' : 'New here? Create an inbox',
                      style: TextStyle(color: context.colors.accentSoft, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => setState(() { _isRecovery = !_isRecovery; _error = null; }),
                  child: Text(
                    _isRecovery ? 'Back to login' : 'Forgot PIN? Recover account',
                    style: TextStyle(color: context.colors.accentSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pinField({required bool login}) {
    return TextField(
      controller: _pinCtrl,
      keyboardType: TextInputType.number,
      maxLength: 6,
      obscureText: true,
      enabled: !_loading,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'PIN',
        hintText: '4-6 digits',
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
        counterText: '',
      ),
      onSubmitted: (_) => login ? _handleLogin() : _handleSignup(),
    );
  }
}
