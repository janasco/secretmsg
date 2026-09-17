import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'send_screen.dart';

/// Standalone "who are you sending to?" step for signed-out senders.
/// Deliberately outside the AppShell: no bottom menu, no account needed —
/// just a handle field that opens the composer addressed to that board.
class SendLookupScreen extends StatefulWidget {
  const SendLookupScreen({super.key});

  @override
  State<SendLookupScreen> createState() => _SendLookupScreenState();
}

class _SendLookupScreenState extends State<SendLookupScreen> {
  final _handleCtrl = TextEditingController();
  String? _error;

  static final _handleRe = RegExp(r'^[a-z0-9_\-\.]{4,30}$');

  @override
  void dispose() {
    _handleCtrl.dispose();
    super.dispose();
  }

  void _continue() {
    final handle =
        _handleCtrl.text.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '');
    if (!_handleRe.hasMatch(handle)) {
      setState(() => _error =
          'Enter their link name (4-30 characters, e.g. alex) — it\'s the part after secretmsg.net/');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SendScreen(initialUsername: handle)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: const AppTopBar(title: 'Send a message'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        children: [
          const Text('💌', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text("Who's it for?",
              style: TextStyle(color: context.colors.textPrimary, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            'Type their SecretMsg link name — no account needed to send.',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _handleCtrl,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _continue(),
            decoration: InputDecoration(
              labelText: 'Their link name',
              hintText: 'e.g. alex',
              prefixText: 'secretmsg.net/',
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
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!,
                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12, height: 1.5)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _continue,
            child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
