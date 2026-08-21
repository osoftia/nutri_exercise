import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_container.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(body: Center(child: child)),
  );

  Finder containerDecor() => find.descendant(
    of: find.byType(NeumorphicContainer),
    matching: find.byType(Container),
  );

  testWidgets('renders its child inside the neumorphic container', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const NeumorphicContainer(child: Text('Content'))),
    );

    expect(find.byType(NeumorphicContainer), findsOneWidget);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('applies both a light and a dark soft shadow', (tester) async {
    await tester.pumpWidget(
      wrap(const NeumorphicContainer(child: Text('Content'))),
    );

    final container = tester.widget<Container>(containerDecor());
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.boxShadow, hasLength(2));

    final light = decoration.boxShadow![0];
    final dark = decoration.boxShadow![1];
    expect(light.offset.dx, lessThan(0), reason: 'light highlight top-left');
    expect(dark.offset.dx, greaterThan(0), reason: 'dark shadow bottom-right');
  });

  testWidgets('uses the configured border radius and padding', (tester) async {
    await tester.pumpWidget(
      wrap(
        const NeumorphicContainer(
          borderRadius: 28,
          padding: EdgeInsets.all(20),
          child: Text('Content'),
        ),
      ),
    );

    final container = tester.widget<Container>(containerDecor());
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(28));
    expect(container.padding, const EdgeInsets.all(20));
  });
}