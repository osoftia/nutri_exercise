import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_view_model.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/blueprint_grid_painter.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/unified_body_blueprint.dart';

const _size = Size(112, 112);
const _cell = 28.0;

Future<Uint8List> _renderPixels(CustomPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final image = await recorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}

int _alphaAt(Uint8List pixels, int x, int y) {
  final width = _size.width.toInt();
  return pixels[(y * width + x) * 4 + 3];
}

void main() {
  group('M44 BlueprintGridPainter', () {
    test('repaints only when its geometry or palette changes', () {
      const base = BlueprintGridPainter();
      expect(base.shouldRepaint(const BlueprintGridPainter()), isFalse);
      expect(base.shouldRepaint(const BlueprintGridPainter(cell: 20)), isTrue);
      expect(
        base.shouldRepaint(const BlueprintGridPainter(majorEvery: 8)),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const BlueprintGridPainter(lineColor: Color(0xFFFFFFFF)),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const BlueprintGridPainter(minorOpacity: 0.5),
        ),
        isTrue,
      );
      expect(
        base.shouldRepaint(
          const BlueprintGridPainter(axisOpacity: 0.5),
        ),
        isTrue,
      );
    });

    testWidgets('paints fine lines, brighter majors and a centre crosshair', (
      tester,
    ) async {
      final pixels = (await tester.runAsync(
        () => _renderPixels(const BlueprintGridPainter(), _size),
      ))!;

      final minor = _alphaAt(pixels, _cell.toInt(), 20);
      final major = _alphaAt(pixels, 0, 20);
      final axis = _alphaAt(pixels, _size.width ~/ 2, 20);
      final background = _alphaAt(pixels, (_cell / 2).toInt(), 20);

      expect(background, 0, reason: 'empty cells stay transparent');
      expect(minor, greaterThan(0));
      expect(major, greaterThan(minor));
      expect(axis, greaterThan(minor));
    });

    testWidgets('renders behind the unified blueprint', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 560,
              height: 420,
              child: UnifiedBodyBlueprint(
                viewModel: const BodyDiagramViewModel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_blueprint_grid')), findsOneWidget);
    });

    testWidgets('the grid can be disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 560,
              height: 420,
              child: UnifiedBodyBlueprint(
                viewModel: const BodyDiagramViewModel(),
                showGrid: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('body_blueprint_grid')), findsNothing);
    });
  });
}
