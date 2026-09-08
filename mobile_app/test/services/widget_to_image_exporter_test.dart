import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/widget_to_image_exporter.dart';

void main() {
  late Directory tempDir;
  late WidgetToImageExporter exporter;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('share_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  testWidgets('captures a RepaintBoundary as a PNG byte stream', (tester) async {
    final key = GlobalKey();
    exporter = WidgetToImageExporter(
      temporaryDirectoryProvider: () async => tempDir,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 120,
            height: 120,
            child: ColoredBox(color: Colors.red),
          ),
        ),
      ),
    );
    await tester.pump();

    Uint8List? png;
    await tester.runAsync(() async {
      png = await exporter.capturePng(key);
    });

    expect(png, isNotNull);
    expect(png!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('saves the PNG to the temporary directory', (tester) async {
    final key = GlobalKey();
    exporter = WidgetToImageExporter(
      temporaryDirectoryProvider: () async => tempDir,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 80,
            height: 80,
            child: ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );
    await tester.pump();

    Uint8List? png;
    File? file;
    var exists = false;
    Uint8List? written;
    await tester.runAsync(() async {
      png = await exporter.capturePng(key);
      file = await exporter.saveToTemp(png!, fileName: 'progress.png');
      exists = await file!.exists();
      written = await file!.readAsBytes();
    });

    expect(exists, isTrue);
    expect(written, png);
  });

  testWidgets('throws when the key is not attached to a RepaintBoundary', (
    tester,
  ) async {
    final key = GlobalKey();
    exporter = WidgetToImageExporter(
      temporaryDirectoryProvider: () async => tempDir,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(key: key, width: 50, height: 50),
      ),
    );
    await tester.pump();

    expect(() => exporter.capturePng(key), throwsStateError);
  });
}