import '../data/language_repository.dart';
import '../domain/i18n/app_language.dart';

/// In-memory [LanguageRepository] used by the dev/test flavors.
///
/// It survives for the lifetime of the process, matching the mock-based
/// persistence strategy of the rest of the app while staying deterministic.
class MockLanguageRepository implements LanguageRepository {
  /// Creates a mock repository, optionally pre-seeded with [initial].
  MockLanguageRepository({AppLanguage? initial}) : _language = initial;

  AppLanguage? _language;

  @override
  Future<AppLanguage?> get() async => _language;

  @override
  Future<void> save(AppLanguage language) async => _language = language;
}
