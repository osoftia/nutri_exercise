import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_container.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const jane = UserProfile(
    name: 'Jane Doe',
    age: 28,
    weightKg: 65,
    heightCm: 170,
    goal: FitnessGoal.muscleGain,
  );

  Future<MockProfileRepository> pumpProfile(
    WidgetTester tester, {
    UserProfile? profile,
  }) async {
    final repo = MockProfileRepository(profile: profile);
    final controller = UserProfileController(repository: repo);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfilePage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Finder field(String name) => find.byKey(Key('profile_$name'));

  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(field('save_button'));
    await tester.pumpAndSettle();
    await tester.tap(field('save_button'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the saved personal details', (tester) async {
    await pumpProfile(tester, profile: jane);

    expect(field('name_field'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(field('name_field'))
          .controller
          ?.text,
      'Jane Doe',
    );
    expect(
      tester.widget<TextFormField>(field('age_field')).controller?.text,
      '28',
    );
    expect(
      tester.widget<TextFormField>(field('weight_field')).controller?.text,
      '65',
    );
    expect(
      tester.widget<TextFormField>(field('height_field')).controller?.text,
      '170',
    );
    expect(find.text('Muscle Gain'), findsOneWidget);
  });

  testWidgets('editing details and saving reflects immediately and persists', (
    tester,
  ) async {
    final repo = await pumpProfile(tester, profile: jane);

    await tester.enterText(field('name_field'), 'Jane Smith');

    await tester.ensureVisible(field('goal_field'));
    await tester.pumpAndSettle();
    await tester.tap(field('goal_field'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fat Loss').last);
    await tester.pumpAndSettle();

    await tapSave(tester);

    final saved = await repo.getProfile();
    expect(saved?.name, 'Jane Smith');
    expect(saved?.goal, FitnessGoal.fatLoss);
    expect(find.text('Jane Smith'), findsOneWidget);
    expect(find.text('Fat Loss'), findsOneWidget);
  });

  testWidgets('accepts numeric weight and height', (tester) async {
    final repo = await pumpProfile(tester);

    await tester.enterText(field('name_field'), 'Alex');
    await tester.enterText(field('age_field'), '30');
    await tester.enterText(field('weight_field'), '70');
    await tester.enterText(field('height_field'), '175');
    await tapSave(tester);

    final saved = await repo.getProfile();
    expect(saved?.name, 'Alex');
    expect(saved?.age, 30);
    expect(saved?.weightKg, 70.0);
    expect(saved?.heightCm, 175.0);
  });

  testWidgets('blocks saving with an empty name', (tester) async {
    final repo = await pumpProfile(tester, profile: jane);

    await tester.enterText(field('name_field'), '');
    await tapSave(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect((await repo.getProfile())?.name, 'Jane Doe');
  });

  testWidgets('profile form is rendered inside a neumorphic container', (
    tester,
  ) async {
    await pumpProfile(tester, profile: jane);

    expect(find.byType(NeumorphicContainer), findsWidgets);
  });
}