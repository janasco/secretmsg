import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../api/config.dart';
import '../theme.dart';
import '../widgets/turnstile_widget.dart';

/// Diagnostics-only screen (enabled with --dart-define=SMS_TURNSTILE_TEST=true).
///
/// Renders the Turnstile widget on the real secretmsg.net origin inside an
/// Android WebView, then POSTs the minted token to the live API for a
/// non-existent user. A 404 proves the token was accepted server-side; a 403
/// proves it was rejected. Results are printed to the log as
/// `SMSTURNSTILE_RESULT=...` for adb logcat collection.
class TurnstileDiagScreen extends StatefulWidget {
  const TurnstileDiagScreen({super.key});

  @override
  State<TurnstileDiagScreen> createState() => _TurnstileDiagScreenState();
}

class _TurnstileDiagScreenState extends State<TurnstileDiagScreen> {
  final _boxKey = GlobalKey();
  String _status = 'Initializing…';
  String? _token;
  bool _testing = false;
  String _result = '';

  static Future<void> _logLine(String line) async {
    try {
      final f = File(
        '/data/data/net.secretmsg.secretmsg_mobile/files/smsturnstile_diag.txt',
      );
      await f.writeAsString('${line}\n', mode: FileMode.append);
    } catch (_) {}
    // ignore: avoid_print
    print(line);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) {
          await _logLine('SMSTURNSTILE_BOX=null');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _logBox();
          });
          return;
        }
        await _logBox();
      } catch (e) {
        await _logLine('SMSTURNSTILE_BOX_ERR=$e');
      }
    });
  }

  Future<void> _logBox() async {
    final box = _boxKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final topLeft = box.localToGlobal(Offset.zero);
    final size = box.size;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    await _logLine(
      'SMSTURNSTILE_BOX=${(topLeft.dx * dpr).round()},'
      '${(topLeft.dy * dpr).round()},'
      '${(size.width * dpr).round()},'
      '${(size.height * dpr).round()}',
    );
  }

  void _emitResult(String key, String value) {
    // ignore: unawaited_futures
    _logLine('SMSTURNSTILE_RESULT=$key=$value');
  }

  Future<void> _onToken(String token) async {
    _emitResult('TOKEN', token.substring(0, token.length > 12 ? 12 : token.length));
    if (!mounted) return;
    setState(() {
      _token = token;
      _status = 'Token minted ✓ — verifying with API…';
    });
    await _verify(token);
  }

  Future<void> _verify(String token) async {
    setState(() {
      _testing = true;
    });
    try {
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl/api/message/qax9tnonexist'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'content': 'smsturnstile-diag',
              'turnstileToken': token,
              'allowClue': false,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      final accepted = res.statusCode == 404;
      final rejected = res.statusCode == 403;
      final result = accepted
          ? 'ACCEPTED (404 → token valid, turnstile passed) ✓'
          : rejected
              ? 'REJECTED (403 → token failed siteverify) ✗'
              : 'HTTP ${res.statusCode}: ${res.body}';
      _emitResult(accepted ? 'PASS_404' : 'FAIL', '${res.statusCode}');
      setState(() {
        _testing = false;
        _result = result;
        _status = result;
      });
    } catch (e) {
      _emitResult('FAIL_NET', e.toString());
      if (!mounted) return;
      setState(() {
        _testing = false;
        _result = 'Network error: $e';
        _status = _result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turnstile Diag', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'This build was compiled with SMS_TURNSTILE_TEST=true.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Step 1: mint a Turnstile token inside the real secretmsg.net origin.',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  key: _boxKey,
                  child: TurnstileWidget(
                    height: 120,
                    autoExecuteFallback: true,
                    onToken: _onToken,
                    onError: (err) {
                      _emitResult('WIDGET_ERROR', err ?? 'unknown');
                      if (mounted) {
                        setState(() => _status = 'Widget error: $err');
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Step 2: send the token to /api/message/qax9tnonexist using the real siteverify secret.',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1220),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _token == null ? AppColors.border : AppColors.accent,
                    ),
                  ),
                  child: Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, height: 1.4),
                  ),
                ),
                if (_result.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _result.startsWith('ACCEPTED')
                          ? const Color(0xFF06281D)
                          : const Color(0xFF330F13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      _result,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: _testing || _token == null
                      ? null
                      : () async {
                          await _verify(_token!);
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-verify with current token'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}