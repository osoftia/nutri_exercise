import '../domain/i18n/app_language.dart';

/// Contract for persisting the user's selected [AppLanguage].
///
/// Implementations may use SQLite, shared preferences or an in-memory store;
/// the controller only depends on this narrow contract, so adding a language
/// never touches persistence logic.
abstract interface class LanguageRepository {
  /// Returns the persisted language, or `null` when none has been stored yet.
  Future<AppLanguage?> get();

  /// Persists the selected [language].
  Future<void> save(AppLanguage language);
}
