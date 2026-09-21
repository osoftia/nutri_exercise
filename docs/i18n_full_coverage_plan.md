# i18n Full Coverage — Plan

## Git branch
`feature/i18n-full-coverage` (delivered as per-task commits on `main`).

## Goal
Reach 100% UI localization: every visible string in the app resolves from the
typed `AppStrings` dictionary for both English and Spanish, so switching the
language via `LanguageController` refreshes the entire UI.

## Gherkin contract
`mobile_app/test/features/i18n_infrastructure.feature` (extended by this sweep)

## Task breakdown
1. **Audit & Expand Dictionaries**
   - Grew `AppStrings` from ~35 to ~120 typed members covering the Routines,
     Nutrition, Schedule and Profile pages, the quick-add dialog, workout
     completion / food / exercise detail sheets, the routine summary, the
     weekly stats sheet, the history dialog + editor, the daily-log sheet, the
     AI chat, the offline dialog, and all validation/status texts.
   - Added date helpers (`monthYear`, `weekdayNarrow`, `weekdayShort`,
     `agendaTitle`), macro/calorie formatters and a structural `BodyRegion` enum.
   - `RecoveryLevel` / `FitnessGoal` reuse the existing domain enums.

2. **Replace Hardcoded Strings in UI Components**
   - Every widget under `lib/ui` now reads `LocalizationScope.stringsOf(context)`
     (directly or through `AppStrings` passed down to child widgets). No screen,
     sheet, dialog, button, tooltip or validation message keeps an inline
     literal (brand name `NutriExercise` and physical units `kg`/`cm`/`g` stay).

3. **Comprehensive Language Switcher Test**
   - `test/i18n/full_coverage_test.dart` — a probe renders **every** contract
     getter in both languages and asserts completeness + en/es divergence.
   - `test/features/i18n_full_coverage_widget_test.dart` — live switch tests for
     the Nutrition, Routines and Profile tabs plus the validation messages.

4. **Verification & Analysis**
   - `fvm flutter analyze` clean; full `fvm flutter test` green.

## Design notes
- The dictionary is **compile-checked**: adding a language requires implementing
  `AppStrings`, so a missing translation fails the build rather than silently
  falling back.
- `LocalizationScope` creates an inherited dependency, so a language change
  rebuilds dependents in place — instant switching without navigation.
- Screens that render their own `ListenableBuilder` (e.g. sheet internals) take
  the resolved `AppStrings` as a parameter so localized labels never mix with
  untranslated ones.
