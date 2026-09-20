import '../database/database_helper.dart';
import '../domain/i18n/app_language.dart';
import 'language_repository.dart';

/// SQLite-backed [LanguageRepository].
///
/// Stores the selected language code under a single `app_settings` key so it is
/// restored on the next launch. An unknown/absent value resolves to `null`, and
/// the controller falls back to [AppLanguage.fallback].
class LocalLanguageRepository implements LanguageRepository {
  /// Creates a repository, defaulting to the app's [DatabaseHelper].
  LocalLanguageRepository({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper();

  /// Key under which the language code is persisted.
  static const String settingKey = 'language';

  final DatabaseHelper _databaseHelper;

  @override
  Future<AppLanguage?> get() async {
    final raw = await _databaseHelper.getSetting(settingKey);
    return AppLanguage.tryParse(raw);
  }

  @override
  Future<void> save(AppLanguage language) =>
      _databaseHelper.upsertSetting(settingKey, language.code);
}
