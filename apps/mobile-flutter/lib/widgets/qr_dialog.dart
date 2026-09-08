import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class QrDialog extends StatelessWidget {
  final String vanityUrl;

  const QrDialog({super.key, required this.vanityUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.outlineStrong, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your QR Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryWhite,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // High-contrast QR canvas
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: QrPatternPainter(),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              vanityUrl,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryWhite,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Scan with phone camera to open instant TBH prompt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'https://$vanityUrl'));
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Public link copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF1E293B),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF0B0E14)),
                label: const Text(
                  'Copy Public Link',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B0E14),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0B0E14)
      ..style = PaintingStyle.fill;

    // Corner Finder Patterns
    _drawFinderPattern(canvas, paint, 0, 0, 48);
    _drawFinderPattern(canvas, paint, size.width - 48, 0, 48);
    _drawFinderPattern(canvas, paint, 0, size.height - 48, 48);

    // Decorative data cells
    final cellW = size.width / 14;
    final cellH = size.height / 14;

    const dataMatrix = [
      [7, 2], [8, 2], [9, 2], [6, 4], [7, 4], [8, 5], [9, 5],
      [2, 7], [3, 7], [4, 7], [7, 7], [8, 7], [10, 7], [11, 7],
      [6, 8], [7, 8], [9, 8], [11, 8], [2, 9], [4, 9], [7, 9],
      [8, 9], [11, 9], [6, 10], [8, 10], [9, 10], [7, 11], [8, 11],
      [10, 11], [11, 11], [12, 11],
    ];

    for (final pt in dataMatrix) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pt[0] * cellW, pt[1] * cellH, cellW - 1, cellH - 1),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, double x, double y, double s) {
    // Outer border
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x, y, s, s), const Radius.circular(8)),
      paint,
    );
    // Inner white
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 7, y + 7, s - 14, s - 14), const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
    // Inner black dot
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x + 14, y + 14, s - 28, s - 28), const Radius.circular(4)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
