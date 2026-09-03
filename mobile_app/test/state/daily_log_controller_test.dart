import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';

void main() {
  group('DailyLogController', () {
    test('load populates the text from the repository', () async {
      final repo = MockDailyLogRepository(
        seed: {'2026-09-03': 'Trained chest'},
      );
      final controller = DailyLogController(repository: repo);

      await controller.load(date: '2026-09-03');

      expect(controller.text, 'Trained chest');
    });

    test('load with no saved log leaves the text empty', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(repository: repo);

      await controller.load(date: '2026-09-03');

      expect(controller.text, '');
    });

    test('save persists a trimmed summary and returns true', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(repository: repo);
      await controller.load(date: '2026-09-03');

      final saved = await controller.save('  Ate chicken and rice  ');

      expect(saved, isTrue);
      expect(controller.text, 'Ate chicken and rice');
      expect((await repo.getByDate('2026-09-03'))?.text, 'Ate chicken and rice');
    });

    test('save rejects an empty summary', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(repository: repo);
      await controller.load(date: '2026-09-03');

      final saved = await controller.save('   ');

      expect(saved, isFalse);
      expect(await repo.getByDate('2026-09-03'), isNull);
    });
  });
}
