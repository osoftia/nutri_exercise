import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/language_repository.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/mocks/mock_language_repository.dart';
import 'package:nutri_mobile_app/core/state/language_controller.dart';

class _RecordingRepository implements LanguageRepository {
  _RecordingRepository([this.stored]);

  AppLanguage? stored;
  int saves = 0;

  @override
  Future<AppLanguage?> get() async => stored;

  @override
  Future<void> save(AppLanguage language) async {
    stored = language;
    saves++;
  }
}

void main() {
  group('LanguageController (i18n Task 2)', () {
    test('defaults to the fallback language', () {
      final controller = LanguageController();
      expect(controller.language, AppLanguage.english);
      expect(controller.locale.languageCode, 'en');
    });

    test('restore hydrates the persisted language', () async {
      final repository = _RecordingRepository(AppLanguage.spanish);
      final controller = LanguageController(repository: repository);

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.restore();

      expect(controller.language, AppLanguage.spanish);
      expect(controller.locale.languageCode, 'es');
      expect(notifications, 1);
    });

    test('restore with nothing persisted keeps the fallback', () async {
      final controller = LanguageController(repository: _RecordingRepository());
      await controller.restore();
      expect(controller.language, AppLanguage.english);
    });

    test('setLanguage notifies immediately and persists', () async {
      final repository = _RecordingRepository();
      final controller = LanguageController(repository: repository);

      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.setLanguage(AppLanguage.spanish);

      expect(controller.language, AppLanguage.spanish);
      expect(notifications, 1);
      expect(repository.stored, AppLanguage.spanish);
      expect(repository.saves, 1);
    });

    test('setLanguage to the same language is a no-op', () async {
      final repository = _RecordingRepository();
      final controller = LanguageController(repository: repository);

      await controller.setLanguage(AppLanguage.english);

      expect(repository.saves, 0);
    });

    test('works without a repository (in-memory only)', () async {
      final controller = LanguageController();
      await controller.setLanguage(AppLanguage.spanish);
      expect(controller.language, AppLanguage.spanish);
    });

    test('round-trips through the mock repository', () async {
      final repository = MockLanguageRepository();
      final controller = LanguageController(repository: repository);
      await controller.setLanguage(AppLanguage.spanish);

      final restored = LanguageController(repository: repository);
      await restored.restore();

      expect(restored.language, AppLanguage.spanish);
    });
  });
}
