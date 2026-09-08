import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// Captures a [RepaintBoundary] (identified by its [GlobalKey]) as a PNG and
/// saves it to the temporary directory so it can be shared to social media.
class WidgetToImageExporter {
  WidgetToImageExporter({Future<Directory> Function()? temporaryDirectoryProvider})
    : _temporaryDirectory = temporaryDirectoryProvider ?? getTemporaryDirectory;

  /// Production default resolves the OS temporary directory; tests inject a
  /// provider to avoid platform channels.
  final Future<Directory> Function() _temporaryDirectory;

  /// Rasterizes the render object attached to [repaintKey] into a PNG byte
  /// stream. [pixelRatio] controls the output resolution (2.0 = crisp).
  ///
  /// Throws a [StateError] when the key is not attached to a RepaintBoundary.
  Future<Uint8List> capturePng(
    GlobalKey repaintKey, {
    double pixelRatio = 2.0,
  }) async {
    final renderObject = repaintKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw StateError(
        'The provided key is not attached to a RepaintBoundary.',
      );
    }
    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode the captured image to PNG.');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// Writes [png] to a file in the temporary directory and returns it.
  Future<File> saveToTemp(
    Uint8List png, {
    String fileName = 'share_progress.png',
  }) async {
    final directory = await _temporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(png, flush: true);
    return file;
  }

  /// Convenience that captures [repaintKey] and saves it to the temporary
  /// directory in one call, returning the resulting [File].
  Future<File> exportShareImage(
    GlobalKey repaintKey, {
    double pixelRatio = 2.0,
    String fileName = 'share_progress.png',
  }) async {
    final png = await capturePng(repaintKey, pixelRatio: pixelRatio);
    return saveToTemp(png, fileName: fileName);
  }
}