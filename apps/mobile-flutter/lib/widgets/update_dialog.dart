import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ritual/update_check.dart';
import '../theme.dart';

/// Skippable "new version available" dialog. Update opens the download page
/// for this build's own distribution track in the browser; Later just closes
/// (it shows again on next cold start).
///
/// Refuses to open anything when the feed named no destination for this
/// track, which callers are expected to have filtered out already via
/// [UpdateInfo.hasDestination]; the check is repeated here so the dialog can
/// never be the thing that sends a user to the wrong track.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info) async {
  final url = info.url;
  if (url == null || url.isEmpty) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Update available',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.colors.textPrimary)),
          ),
        ],
      ),
      content: Text(
        'v${info.latest} is out — you have v${info.current}.\nUpdate for the latest Drops, streaks and fixes.',
        style: TextStyle(fontSize: 13.5, height: 1.55, color: context.colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Later', style: TextStyle(color: context.colors.textMuted, fontWeight: FontWeight.w700)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.emerald,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.of(ctx).pop();
            final uri = Uri.tryParse(url);
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
