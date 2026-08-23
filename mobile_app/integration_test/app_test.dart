import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';
import 'package:nutri_mobile_app/ui/atoms/projection_avatar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder navTab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  ProjectionAvatarPainter projectionPainter(WidgetTester tester) {
    final customPaint = tester.widget<CustomPaint>(
      find.byKey(const Key('projection_avatar')),
    );
    return customPaint.painter! as ProjectionAvatarPainter;
  }

  testWidgets('full app flow: tabs, profile persistence and avatar morph', (
    tester,
  ) async {
    // Boot the full application (dev config, mock-backed repositories).
    await tester.pumpWidget(
      const NutriApp(config: AppConfig(name: 'dev', useMocks: true)),
    );
    await tester.pumpAndSettle();

    // 1. Routines tab (default) shows the projection timeline + avatar.
    expect(find.text('Body Projection'), findsOneWidget);
    expect(find.byKey(const Key('timeline_0')), findsOneWidget);
    expect(find.byKey(const Key('timeline_6')), findsOneWidget);
    expect(projectionPainter(tester).shoulderFactor, 0.5);

    // 2. Nutrition tab shows the dashboard.
    await tester.tap(navTab('Nutrition'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calorie_summary')), findsOneWidget);
    expect(find.text('1000 of 2000 kcal'), findsOneWidget);

    // 3. Schedule tab shows the calendar grid.
    await tester.tap(navTab('Schedule'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar_grid')), findsOneWidget);

    // 4. Profile tab: fill the neumorphic form and save (persists via the
    //    repository; SQLite-backed in production).
    await tester.tap(navTab('Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile_name_field')),
      'Jane Doe',
    );
    await tester.enterText(find.byKey(const Key('profile_age_field')), '28');
    await tester.enterText(
      find.byKey(const Key('profile_weight_field')),
      '65',
    );
    await tester.enterText(
      find.byKey(const Key('profile_height_field')),
      '170',
    );
    await tester.ensureVisible(find.byKey(const Key('profile_save_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Jane Doe'), findsOneWidget);

    // 5. Back to Routines: select the 6-month milestone and verify the avatar
    //    morphs (muscle gain -> broadest shoulders).
    await tester.tap(navTab('Routines'));
    await tester.pumpAndSettle();

    final baselineShoulder = projectionPainter(tester).shoulderFactor;
    await tester.tap(find.byKey(const Key('timeline_6')));
    await tester.pumpAndSettle();

    final morphedShoulder = projectionPainter(tester).shoulderFactor;
    expect(morphedShoulder, greaterThan(baselineShoulder));
    expect(morphedShoulder, 1.0);
  });
}
