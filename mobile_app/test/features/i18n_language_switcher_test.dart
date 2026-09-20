import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/mocks/mock_language_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/state/language_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';

Future<LanguageController> _pumpProfile(
  WidgetTester tester, {
  LanguageController? languageController,
}) async {
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = languageController ?? LanguageController();
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => LocalizationScope(
          language: controller.language,
          child: ProfilePage(
            controller: UserProfileController(
              repository: MockProfileRepository(),
            ),
            languageController: controller,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  group('M-i18n language switcher (Task 4)', () {
    testWidgets('is hidden without a language controller', (tester) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ProfilePage(
            controller: UserProfileController(
              repository: MockProfileRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('language_option_en')), findsNothing);
    });

    testWidgets('shows both language options and the English heading', (
      tester,
    ) async {
      await _pumpProfile(tester);

      expect(find.byKey(const Key('language_option_en')), findsOneWidget);
      expect(find.byKey(const Key('language_option_es')), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('switching to Spanish refreshes the UI instantly', (
      tester,
    ) async {
      final controller = await _pumpProfile(tester);

      await tester.tap(find.byKey(const Key('language_option_es')));
      await tester.pumpAndSettle();

      expect(controller.language, AppLanguage.spanish);
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('Inglés'), findsOneWidget);
      expect(find.text('Language'), findsNothing);
    });

    testWidgets('persists the choice and restores it on relaunch', (
      tester,
    ) async {
      final repository = MockLanguageRepository();
      final controller = LanguageController(repository: repository);
      await _pumpProfile(tester, languageController: controller);

      await tester.tap(find.byKey(const Key('language_option_es')));
      await tester.pumpAndSettle();
      expect(repository.get(), completion(AppLanguage.spanish));

      final restored = await tester.runAsync(
        () async {
          final next = LanguageController(repository: repository);
          await next.restore();
          return next;
        },
      );
      expect(restored!.language, AppLanguage.spanish);
    });
  });
}
