import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/bottom_nav_bar.dart';
import 'package:nutri_mobile_app/ui/pages/main_shell_page.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';
import 'package:nutri_mobile_app/ui/pages/schedule_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpShell(WidgetTester tester) async {
    final controller = UserProfileController(
      repository: MockProfileRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MainShellPage(profileController: controller),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder navTab(String label) => find.descendant(
    of: find.byType(BottomNavBar),
    matching: find.text(label),
  );

  group('Main Navigation Shell', () {
    testWidgets('bottom navigation shows the four main tabs', (tester) async {
      await pumpShell(tester);

      expect(navTab('Routines'), findsOneWidget);
      expect(navTab('Nutrition'), findsOneWidget);
      expect(navTab('Schedule'), findsOneWidget);
      expect(navTab('Profile'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
    });

    testWidgets('navigating to the Routines tab shows mock routines', (
      tester,
    ) async {
      await pumpShell(tester);

      expect(find.byType(RoutinesPage), findsOneWidget);
      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Push Day'), findsOneWidget);
    });

    testWidgets('navigating to the Nutrition tab shows a mock nutrition plan', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(navTab('Nutrition'));
      await tester.pumpAndSettle();

      expect(find.byType(NutritionPage), findsOneWidget);
      expect(find.text('Oatmeal & Berries'), findsOneWidget);
      expect(find.text('Grilled Chicken Bowl'), findsOneWidget);
    });

    testWidgets('navigating to the Schedule tab shows a calendar view', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(navTab('Schedule'));
      await tester.pumpAndSettle();

      expect(find.byType(SchedulePage), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.byKey(const Key('calendar_grid')), findsOneWidget);
    });

    testWidgets('navigating to the Profile tab shows the profile form', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(navTab('Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.byKey(const Key('profile_name_field')), findsOneWidget);
      expect(find.byKey(const Key('profile_save_button')), findsOneWidget);
    });

    testWidgets('each tab retains its mock content when revisited', (
      tester,
    ) async {
      await pumpShell(tester);

      await tester.tap(navTab('Nutrition'));
      await tester.pumpAndSettle();
      expect(find.text('Oatmeal & Berries'), findsOneWidget);

      await tester.tap(navTab('Routines'));
      await tester.pumpAndSettle();
      expect(find.text('Monday'), findsOneWidget);

      await tester.tap(navTab('Nutrition'));
      await tester.pumpAndSettle();
      expect(find.text('Oatmeal & Berries'), findsOneWidget);
      expect(find.text('Grilled Chicken Bowl'), findsOneWidget);
    });
  });
}