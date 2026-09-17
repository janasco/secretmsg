import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ritual/update_check.dart';
import '../theme.dart';

/// Skippable "new version available" dialog. Update opens the download page
/// in the browser; Later just closes (it shows again on next cold start).
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Text('🎉', style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Expanded(
            child: Text('Update available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          ),
        ],
      ),
      content: Text(
        'v${info.latest} is out — you have v${info.current}.\nUpdate for the latest Drops, streaks and fixes.',
        style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.of(ctx).pop();
            final uri = Uri.tryParse(info.url);
            if (uri != null) {
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (_) {}
            }
          },
          child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}
