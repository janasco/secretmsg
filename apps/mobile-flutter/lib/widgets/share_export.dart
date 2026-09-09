import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Captures [key]'s RepaintBoundary to a PNG file in temp storage.
Future<String?> capturePng(GlobalKey key) async {
  try {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}secretmsg_story_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(byteData.buffer.asUint8List());
    return file.path;
  } catch (_) {
    return null;
  }
}

/// Opens the share sheet with the captured image and optional text.
Future<bool> sharePng(GlobalKey key, {String? subject}) async {
  final path = await capturePng(key);
  if (path == null) return false;
  await Share.shareXFiles(
    [XFile(path)],
    text: subject,
    subject: subject,
  );
  return true;
}