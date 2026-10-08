import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/theme/app_design_tokens.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/core/theme/app_theme_mode.dart';
import 'package:nutri_mobile_app/core/theme/apple_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('theme factory selects the appropriate global design language', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forMode(AppThemeMode.technicalBlueprint),
        home: const Scaffold(body: Text('Theme factory probe')),
      ),
    );
    expect(
      Theme.of(tester.element(find.text('Theme factory probe'))).brightness,
      Brightness.dark,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forMode(AppThemeMode.appleMinimalist),
        home: Builder(
          builder: (context) => Text(
            Theme.of(context).brightness.name,
            key: const Key('apple_theme_brightness'),
          ),
        ),
      ),
    );
    final apple = AppTheme.forMode(AppThemeMode.appleMinimalist);
    expect(apple.brightness, Brightness.light);
    expect(apple.scaffoldBackgroundColor, AppleTheme.background);
    expect(apple.textTheme.bodyLarge?.fontWeight, FontWeight.w400);
    expect(apple.extension<AppDesignTokens>()?.frostedGlass, isTrue);
  });

  testWidgets('Apple Minimalist custom surfaces use glass card tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppleTheme.theme,
        home: const Scaffold(
          body: NeumorphicContainer(
            key: Key('apple_card'),
            child: Text('Frosted surface'),
          ),
        ),
      ),
    );

    expect(find.byType(BackdropFilter), findsOneWidget);
    final surface = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const Key('apple_card')),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, AppleTheme.surface);
    expect(decoration.border, isNotNull);
    expect(decoration.borderRadius, AppleTheme.cardBorderRadius);
    expect(decoration.boxShadow, hasLength(1));
  });
}
