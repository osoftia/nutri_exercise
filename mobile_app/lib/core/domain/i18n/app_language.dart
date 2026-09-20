import 'dart:ui' show Locale;

/// The languages the app ships with.
///
/// Adding a language is a two-step, business-logic-free change: append an enum
/// value here and provide its `AppStrings` implementation. Every other layer
/// (controller, persistence, UI) is language-agnostic because it works with this
/// enum rather than with raw strings.
enum AppLanguage {
  /// English (default / fallback).
  english(code: 'en', label: 'English'),

  /// Spanish.
  spanish(code: 'es', label: 'Español');

  const AppLanguage({required this.code, required this.label});

  /// ISO-639-1 primary language subtag (e.g. `en`, `es`).
  final String code;

  /// Endonym shown in the language switcher (e.g. `Español`).
  final String label;

  /// The [Locale] this language maps to.
  Locale get locale => Locale(code);

  /// Used whenever a stored or requested language cannot be resolved.
  static const AppLanguage fallback = AppLanguage.english;

  /// Every supported language, in display order.
  static List<AppLanguage> get supported => values;

  /// Every supported [Locale], in display order.
  static List<Locale> get supportedLocales => [
        for (final language in values) language.locale,
      ];

  /// Resolves [code] to a supported language, or `null` when it is unknown.
  ///
  /// Accepts plain (`es`), region-qualified (`es-ES`, `en_US`) and any casing.
  static AppLanguage? tryParse(String? code) {
    if (code == null) return null;
    final normalized = code.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final primary = normalized.split(RegExp(r'[-_]')).first;
    for (final language in values) {
      if (language.code == primary) return language;
    }
    return null;
  }

  /// Resolves [code] to a supported language, falling back to [fallback].
  static AppLanguage fromCode(String? code) => tryParse(code) ?? fallback;
}
