import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/share_progress_controller.dart';
import 'package:nutri_mobile_app/core/services/widget_to_image_exporter.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  late Directory tempDir;
  late ShareProgressController controller;
  final sharedFiles = <XFile>[];

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('share_controller_test');
    sharedFiles.clear();
    controller = ShareProgressController(
      exporter: WidgetToImageExporter(
        temporaryDirectoryProvider: () async => tempDir,
      ),
      share: (files, {text}) async => sharedFiles.addAll(files),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('shareCard captures the boundary and opens the share sheet', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 100,
            height: 100,
            child: ColoredBox(color: Colors.teal),
          ),
        ),
      ),
    );
    await tester.pump();

    String? path;
    Uint8List? bytes;
    await tester.runAsync(() async {
      path = await controller.shareCard(key, text: 'Check my progress!');
      bytes = await File(path!).readAsBytes();
    });

    expect(path, isNotNull);
    expect(bytes!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    expect(sharedFiles, hasLength(1));
    expect(sharedFiles.first.path, path);
  });
}