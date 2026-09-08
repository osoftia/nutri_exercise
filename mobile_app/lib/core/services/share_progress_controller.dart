import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import 'widget_to_image_exporter.dart';

/// Orchestrates sharing the user's progress: captures the [RepaintBoundary]
/// behind a [GlobalKey] as a PNG and opens the native OS share sheet.
///
/// The exporter and share function are injectable for tests.
class ShareProgressController {
  ShareProgressController({
    WidgetToImageExporter? exporter,
    Future<void> Function(List<XFile> files, {String? text})? share,
  }) : _exporter = exporter ?? WidgetToImageExporter(),
       _share = share ?? _defaultShare;

  final WidgetToImageExporter _exporter;
  final Future<void> Function(List<XFile> files, {String? text}) _share;

  static Future<void> _defaultShare(
    List<XFile> files, {
    String? text,
  }) =>
      Share.shareXFiles(files, text: text);

  /// Captures [repaintKey], saves it to the temporary directory and opens the
  /// share sheet. Returns the captured file path.
  Future<String?> shareCard(
    GlobalKey repaintKey, {
    String? text,
    String fileName = 'share_progress.png',
  }) async {
    final file = await _exporter.exportShareImage(
      repaintKey,
      fileName: fileName,
    );
    await _share([XFile(file.path)], text: text);
    return file.path;
  }
}