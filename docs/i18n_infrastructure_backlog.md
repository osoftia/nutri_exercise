# i18n Infrastructure Backlog

- [x] Task 1: Language Domain & Enum - Create a clean domain value object/enum representing supported locales (`AppLanguage` with codes 'es', 'en' and fallback mechanisms).
- [ ] Task 2: Persistent Language Controller - Implement a `ChangeNotifier` / State provider (`LanguageController`) that persists the user's language choice locally (via SharedPreferences or SQLite) so it restores on app launch.
- [ ] Task 3: Translation Dictionary Structure - Create a modular localization dictionary structure (or delegate to Flutter's official localization setup) supporting typed keys for screens, navigation, dialogs, and quick-add actions.
- [ ] Task 4: User Settings UI Toggle - Add a clean language switcher toggle inside the User Settings / Profile section allowing real-time switching between Spanish and English with instant UI refresh.
- [ ] Task 5: Testing & Verification - Write unit and widget tests for language switching persistence and dictionary lookups. Run `flutter test` and verify clean analyzer output.
