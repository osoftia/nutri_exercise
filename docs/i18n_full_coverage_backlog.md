# i18n Full Coverage Backlog

- [x] Task 1: Audit & Expand Dictionaries - Add missing translation keys to both `EnglishStrings` and `SpanishStrings` for every remaining UI element across the app (Routines page, Nutrition page, Profile, Schedule, Quick-Add dialogs, Workout completion sheets, Food detail sheets, History dialogs, and validation/status texts).
- [x] Task 2: Replace Hardcoded Strings in UI Components - Refactor all remaining widgets, bottom sheets, dialogs, and buttons to pull strings dynamically from `LocalizationScope.of(context)` / `AppStrings` instead of using hardcoded string literals.
- [x] Task 3: Comprehensive Language Switcher Test - Write unit/widget tests asserting that switching the language via `LanguageController` successfully updates every single text field in the app UI.
- [x] Task 4: Verification & Analysis - Run `flutter test` and ensure clean analyzer output with zero issues.
