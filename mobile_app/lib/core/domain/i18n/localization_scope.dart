import 'package:flutter/widgets.dart';

import 'app_language.dart';
import 'app_strings.dart';

/// Exposes the active [AppLanguage] / [AppStrings] to the widget tree.
///
/// Widgets read translations through [stringsOf], which creates an inherited
/// dependency: when the language changes the scope notifies and every dependent
/// rebuilds in place, giving instant runtime switching. When no scope is present
/// (isolated widget tests, legacy pages) it safely falls back to English.
class LocalizationScope extends InheritedWidget {
  /// Creates a scope for [language].
  const LocalizationScope({
    super.key,
    required this.language,
    required super.child,
  });

  /// The active language.
  final AppLanguage language;

  /// The active language, defaulting to [AppLanguage.fallback].
  static AppLanguage languageOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<LocalizationScope>()
          ?.language ??
      AppLanguage.fallback;

  /// The dictionary for the active language.
  static AppStrings stringsOf(BuildContext context) =>
      AppStrings.of(languageOf(context));

  @override
  bool updateShouldNotify(LocalizationScope oldWidget) =>
      oldWidget.language != language;
}
