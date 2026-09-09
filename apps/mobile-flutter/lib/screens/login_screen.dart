import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefillUsername;
  const LoginScreen({super.key, this.prefillUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _requesting = false;
  bool _verifying = false;
  bool _emailSent = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _usernameCtrl.text = widget.prefillUsername ?? '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _requesting = true;
      _error = null;
      _info = null;
    });
    try {
      await ApiClient.requestOtp(email);
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _emailSent = true;
        _info = 'A 6-digit code has been sent to $email. It expires in 15 minutes.';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _error = e.statusCode == 429
            ? 'Too many requests. Please wait a moment and try again.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _requesting = false;
        _error = 'Could not reach SecretMsg. Check your connection and try again.';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _error = 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final username = _usernameCtrl.text.trim();
      await ApiClient.verifyOtp(email, otp, username: username.isEmpty ? null : username.toLowerCase());
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = e.statusCode == 429
            ? 'Too many attempts. Please request a new code.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = 'Verification failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Create your inbox'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Passwordless. Anonymous-by-default. Yours to control.',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, height: 1.25),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your secret link with just an email — no password to leak, ever. Messages stay anonymous; you stay in control.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_requesting && !_verifying,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
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
                const SizedBox(height: 10),
                TextField(
                  controller: _usernameCtrl,
                  autocorrect: false,
                  enabled: !_requesting && !_verifying,
                  decoration: InputDecoration(
                    labelText: 'Username (choose your link)',
                    hintText: 'janasco',
                    prefixText: '@ ',
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
                const SizedBox(height: 6),
                const Text(
                  '4–30 characters: lowercase letters, numbers, dashes, underscores, or dots. This becomes your public link.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 11, height: 1.45),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _requesting || _verifying ? null : (_emailSent ? _verifyOtp : _requestOtp),
                  child: (_requesting || _verifying)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _emailSent ? 'Verify Code' : 'Send me a code',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
                if (_info != null) ...[
                  const SizedBox(height: 12),
                  Text(_info!, style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, height: 1.5)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.5)),
                ],
                if (_emailSent) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    enabled: !_verifying,
                    decoration: InputDecoration(
                      labelText: '6-digit code',
                      hintText: '123456',
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
                    onSubmitted: (_) => _verifyOtp(),
                  ),
                  TextButton(
                    onPressed: (_requesting || _verifying) ? null : _requestOtp,
                    child: const Text('Resend code', style: TextStyle(color: Color(0xFFA5B4FC))),
                  ),
                ],
                const SizedBox(height: 24),
                const SizedBox(
                  child: Text(
                    'Existing user? Logging in with the same email restores your inbox and settings.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}