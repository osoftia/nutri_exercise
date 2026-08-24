import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Montserrat typography', () {
    testWidgets('exposes Montserrat as the global font family', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const SizedBox()),
      );
      expect(AppTheme.fontFamily, 'Montserrat');
    });

    testWidgets('dark theme text styles use the Montserrat family', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: const SizedBox()),
      );
      expect(
        AppTheme.dark.textTheme.bodyLarge?.fontFamily,
        contains('Montserrat'),
      );
      expect(
        AppTheme.dark.textTheme.displayMedium?.fontFamily,
        contains('Montserrat'),
      );
    });

    testWidgets('light theme aliases the dark theme and keeps Montserrat', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const SizedBox()),
      );
      expect(
        AppTheme.light.textTheme.bodyLarge?.fontFamily,
        contains('Montserrat'),
      );
      expect(
        AppTheme.light.textTheme.displayMedium?.fontFamily,
        contains('Montserrat'),
      );
    });
  });

  group('Neumorphic design tokens', () {
    test('light shadow is offset to the top-left', () {
      expect(NeumorphicStyles.lightShadow.offset.dx, lessThan(0));
      expect(NeumorphicStyles.lightShadow.offset.dy, lessThan(0));
      expect(NeumorphicStyles.lightShadow.blurRadius, greaterThan(0));
    });

    test('dark shadow is offset to the bottom-right', () {
      expect(NeumorphicStyles.darkShadow.offset.dx, greaterThan(0));
      expect(NeumorphicStyles.darkShadow.offset.dy, greaterThan(0));
      expect(NeumorphicStyles.darkShadow.blurRadius, greaterThan(0));
    });
  });
}