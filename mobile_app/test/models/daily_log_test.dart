import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/daily_log.dart';

void main() {
  group('DailyLog model', () {
    test('constructs with a date and text', () {
      const log = DailyLog(date: '2026-09-03', text: 'Ate chicken, trained chest');

      expect(log.date, '2026-09-03');
      expect(log.text, 'Ate chicken, trained chest');
    });

    test('dateKey formats a DateTime as YYYY-MM-DD', () {
      expect(DailyLog.dateKey(DateTime(2026, 9, 3)), '2026-09-03');
      expect(DailyLog.dateKey(DateTime(2026, 12, 31)), '2026-12-31');
      expect(DailyLog.dateKey(DateTime(2026, 1, 5)), '2026-01-05');
    });

    test('toMap/fromMap round-trips', () {
      const log = DailyLog(date: '2026-09-03', text: 'Trained legs');

      final restored = DailyLog.fromMap(log.toMap());

      expect(restored.date, '2026-09-03');
      expect(restored.text, 'Trained legs');
    });
  });
}
