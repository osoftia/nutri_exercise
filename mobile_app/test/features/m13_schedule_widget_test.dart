import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_container.dart';
import 'package:nutri_mobile_app/ui/pages/schedule_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ScheduleController> pumpSchedule(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ScheduleController(
      repository: MockScheduleRepository(),
      initialMonth: DateTime(2026, 8),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SchedulePage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  Finder day(int d) => find.byKey(Key('day_$d'));

  group('Schedule & Calendar', () {
    testWidgets('shows the month label, weekday header and day tiles', (
      tester,
    ) async {
      await pumpSchedule(tester);

      expect(find.text('August 2026'), findsOneWidget);
      for (final day in const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']) {
        expect(find.text(day), findsOneWidget);
      }
      expect(day(1), findsOneWidget);
      expect(day(31), findsOneWidget);
      expect(day(32), findsNothing);
    });

    testWidgets('selecting a date shows its events in the daily agenda', (
      tester,
    ) async {
      await pumpSchedule(tester);

      await tester.tap(day(5));
      await tester.pumpAndSettle();

      expect(find.text('Leg Day Workout'), findsOneWidget);
      expect(find.text('High Protein Breakfast'), findsOneWidget);
    });

    testWidgets('selecting a date with no events shows an empty agenda', (
      tester,
    ) async {
      await pumpSchedule(tester);

      await tester.tap(day(3));
      await tester.pumpAndSettle();

      expect(find.text('No events scheduled'), findsOneWidget);
      expect(find.text('Leg Day Workout'), findsNothing);
    });

    testWidgets('selecting another date updates the agenda dynamically', (
      tester,
    ) async {
      await pumpSchedule(tester);

      await tester.tap(day(5));
      await tester.pumpAndSettle();
      expect(find.text('Leg Day Workout'), findsOneWidget);

      await tester.tap(day(12));
      await tester.pumpAndSettle();

      expect(find.text('Pull Day Workout'), findsOneWidget);
      expect(find.text('Leg Day Workout'), findsNothing);
    });

    testWidgets('days that have events are marked on the calendar', (
      tester,
    ) async {
      await pumpSchedule(tester);

      expect(find.byKey(const Key('day_marker_5')), findsOneWidget);
      expect(find.byKey(const Key('day_marker_12')), findsOneWidget);
      expect(find.byKey(const Key('day_marker_3')), findsNothing);
    });

    testWidgets('navigating to the next month updates the calendar', (
      tester,
    ) async {
      await pumpSchedule(tester);

      await tester.tap(find.byKey(const Key('next_month_button')));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('navigating to the previous month updates the calendar', (
      tester,
    ) async {
      await pumpSchedule(tester);

      await tester.tap(find.byKey(const Key('prev_month_button')));
      await tester.pumpAndSettle();

      expect(find.text('July 2026'), findsOneWidget);
    });

    testWidgets('calendar and agenda are rendered in the neumorphic style', (
      tester,
    ) async {
      await pumpSchedule(tester);

      expect(find.byKey(const Key('calendar_grid')), findsOneWidget);
      expect(find.byKey(const Key('daily_agenda')), findsOneWidget);
      expect(find.byType(NeumorphicContainer), findsWidgets);
    });
  });
}