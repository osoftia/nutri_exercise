import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';

void main() {
  group('AppLanguage (i18n Task 1)', () {
    test('ships english and spanish with the expected codes', () {
      expect(AppLanguage.english.code, 'en');
      expect(AppLanguage.spanish.code, 'es');
      expect(AppLanguage.values, hasLength(2));
    });

    test('exposes its Locale and the supported locale list', () {
      expect(AppLanguage.spanish.locale, const Locale('es'));
      expect(AppLanguage.supportedLocales, const [Locale('en'), Locale('es')]);
    });

    test('falls back to english for unknown or missing codes', () {
      expect(AppLanguage.fallback, AppLanguage.english);
      expect(AppLanguage.fromCode(null), AppLanguage.english);
      expect(AppLanguage.fromCode(''), AppLanguage.english);
      expect(AppLanguage.fromCode('fr'), AppLanguage.english);
      expect(AppLanguage.tryParse('fr'), isNull);
    });

    test('parses plain, region-qualified and cased codes', () {
      expect(AppLanguage.tryParse('en'), AppLanguage.english);
      expect(AppLanguage.tryParse('es'), AppLanguage.spanish);
      expect(AppLanguage.tryParse('es-ES'), AppLanguage.spanish);
      expect(AppLanguage.tryParse('en_US'), AppLanguage.english);
      expect(AppLanguage.fromCode('ES'), AppLanguage.spanish);
    });
  });
}
