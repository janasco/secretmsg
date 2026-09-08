import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final service = MockDataService();

  void _showConfirmModal(String actionType) {
    final isWipe = actionType == 'wipe';
    final title = isWipe ? 'Wipe Inbox?' : 'Delete Account?';
    final desc = isWipe
        ? 'All received anonymous messages and thread replies will be permanently erased.'
        : 'Your vanity slug @${service.currentUser.username} will be released. This cannot be undone.';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.wholesomeRose.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.wholesomeRose.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppTheme.wholesomeRose, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.outline),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        if (isWipe) {
                          service.wipeAllMessages();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All inbox messages wiped permanently.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account scheduled for permanent deletion.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.wholesomeRose,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 0,
                      ),
                      child: Text(
                        isWipe ? 'Wipe All' : 'Delete',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20, color: AppTheme.primaryWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Privacy & Security Vault',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zero-Log Guarantee Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outlineStrong),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryWhite.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_user_rounded, color: AppTheme.primaryWhite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Zero-Log Guarantee',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'ENFORCED',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.emeraldGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'SecretMsg operates on a stateless edge architecture. We never store sender IP addresses, browser fingerprints, or tracking cookies.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Messaging Controls
              const Text(
                'Messaging Controls',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Allow Double-Blind Anonymous Replies',
                      subtitle: 'Senders can view replies without unmasking',
                      value: service.allowDoubleBlindReplies,
                      onChanged: (v) => setState(() => service.allowDoubleBlindReplies = v),
                    ),
                    const Divider(height: 1, color: AppTheme.outline),
                    _buildSwitchTile(
                      title: 'Display Approximate Sender Clues',
                      subtitle: 'Show broad hints like "iOS device" or timezone',
                      value: service.showSenderClues,
                      onChanged: (v) => setState(() => service.showSenderClues = v),
                    ),
                    const Divider(height: 1, color: AppTheme.outline),
                    _buildSwitchTile(
                      title: 'Cloudflare Turnstile Bot Shield',
                      subtitle: 'Block automated scripts & spam submitters',
                      value: service.botShieldActive,
                      onChanged: (v) => setState(() => service.botShieldActive = v),
                    ),
                    const Divider(height: 1, color: AppTheme.outline),
                    _buildSwitchTile(
                      title: 'AI Harassment Filter',
                      subtitle: 'Quarantine abusive or toxic submissions',
                      value: service.aiModerationActive,
                      onChanged: (v) => setState(() => service.aiModerationActive = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account & Credentials
              const Text(
                'Identity & Credentials',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mail_outline_rounded, size: 16, color: AppTheme.textMuted),
                            SizedBox(width: 8),
                            Text('janasco@duck.com', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.primaryWhite)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryWhite.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.primaryWhite)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.alternate_email_rounded, size: 16, color: AppTheme.textMuted),
                            SizedBox(width: 8),
                            Text('@janasco', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.primaryWhite)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDim,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nuclear Options
              const Text(
                'Nuclear Options',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.wholesomeRose),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.wholesomeRose.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => _showConfirmModal('wipe'),
                        icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: AppTheme.wholesomeRose),
                        label: const Text(
                          'Wipe All Inbox Messages',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryWhite),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.outlineStrong),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: OutlinedButton.icon(
                        onPressed: () => _showConfirmModal('delete'),
                        icon: const Icon(Icons.person_off_rounded, size: 16, color: AppTheme.wholesomeRose),
                        label: const Text(
                          'Delete Account Permanently',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.wholesomeRose),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.wholesomeRose.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(21)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryWhite)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryWhite,
            activeTrackColor: AppTheme.surfaceHigh,
          ),
        ],
      ),
    );
  }
}
