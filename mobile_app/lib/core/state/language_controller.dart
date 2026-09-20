import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter/foundation.dart';

import '../data/language_repository.dart';
import '../domain/i18n/app_language.dart';

/// ChangeNotifier owning the app's active language.
///
/// [restore] hydrates the persisted choice on launch (falling back to
/// [AppLanguage.fallback]) and [setLanguage] switches immediately — notifying
/// listeners so the UI rebuilds on the same frame — before persisting through
/// the optional [LanguageRepository].
class LanguageController extends ChangeNotifier {
  /// Creates a controller, optionally backed by [repository].
  LanguageController({LanguageRepository? repository})
      : _repository = repository;

  final LanguageRepository? _repository;

  AppLanguage _language = AppLanguage.fallback;
  bool _isLoaded = false;

  /// The active language.
  AppLanguage get language => _language;

  /// The active [Locale].
  Locale get locale => _language.locale;

  /// Whether [restore] has completed at least once.
  bool get isLoaded => _isLoaded;

  /// Loads the persisted language (if any) and notifies listeners.
  ///
  /// A missing or unparsable value keeps [AppLanguage.fallback], so a fresh
  /// install always starts in English.
  Future<void> restore() async {
    final repository = _repository;
    if (repository != null) {
      final stored = await repository.get();
      if (stored != null) _language = stored;
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Switches to [language], notifying immediately and persisting it.
  ///
  /// Setting the current language is a no-op, so the switcher never fires a
  /// redundant rebuild or write.
  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await _repository?.save(language);
  }
}
