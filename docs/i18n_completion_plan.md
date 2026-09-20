# Milestone i18n — Plan (Tasks 2–5)

## Git branch
`feature/i18n-infrastructure` (delivered as per-task commits on `main`).

## Goal
Complete the multi-language infrastructure started in Task 1 (`AppLanguage`):
persist the user's choice, provide typed English/Spanish dictionaries, expose a
reactive switcher in Profile, and verify lookups + persistence.

## Gherkin contract
`mobile_app/test/features/i18n_infrastructure.feature`

## Task breakdown
2. **Persistent Language Controller**
   - `core/data/language_repository.dart` (contract), `local_language_repository.dart`
     (SQLite `app_settings` K/V, schema v11), `mocks/mock_language_repository.dart`.
   - `core/state/language_controller.dart` (`restore`, `setLanguage`, `locale`).
   - `DatabaseHelper`: schema `10→11`, `app_settings` table + `getSetting`/`upsertSetting`.

3. **Translation Dictionaries**
   - `core/domain/i18n/app_strings.dart` (typed contract), `english_strings.dart`,
     `spanish_strings.dart`, `localization_scope.dart` (InheritedWidget).
   - Wired: `BottomNavBar` labels and `NutritionPage` header/quick-add labels
     switch live; `app.dart` provides the scope.

4. **Settings / Profile Language Switcher UI**
   - `ui/molecules/language_switcher.dart` (reactive chips, one per language).
   - `ProfilePage` renders it when a `LanguageController` is supplied; the shell
     passes it through.

5. **Testing & Verification**
   - New tests: `test/i18n/app_language_test.dart` (Task 1),
     `language_controller_test.dart`, `app_strings_test.dart`,
     `test/data/local_language_repository_test.dart`,
     `test/features/i18n_language_switcher_test.dart`.
   - `fvm flutter analyze` clean; full `fvm flutter test` green.

## Key identifiers
- `AppLanguage`, `AppStrings`, `LocalizationScope`, `LanguageController`,
  `language_option_en`, `language_option_es`, `app_settings`, `LocalLanguageRepository.settingKey`

## Risks / notes
- Dictionaries are compile-checked: adding a language requires implementing
  `AppStrings`, so no string can be silently missed.
- Full screen-by-screen localization rollout can continue by reading
  `LocalizationScope.stringsOf(context)`; the infrastructure is complete.
