import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';

void main() {
  group('SymptomType.fromId', () {
    test('resolves every known id', () {
      for (final type in SymptomType.values) {
        expect(SymptomType.fromId(type.name), type);
      }
    });

    test('returns null for unknown or null ids', () {
      expect(SymptomType.fromId('nope'), isNull);
      expect(SymptomType.fromId(null), isNull);
    });
  });

  group('SymptomLog', () {
    test('dateKey pads the date to YYYY-MM-DD', () {
      expect(SymptomLog.dateKey(DateTime(2026, 5, 3)), '2026-05-03');
    });

    test('toMap/fromMap round-trips', () {
      const log = SymptomLog(
        date: '2026-09-21',
        symptom: SymptomType.discomfort,
        level: 2,
      );

      final restored = SymptomLog.fromMap(log.toMap());

      expect(restored.date, '2026-09-21');
      expect(restored.symptom, SymptomType.discomfort);
      expect(restored.level, 2);
    });

    test('fromMap tolerates unknown symptoms and clamps the level', () {
      final restored = SymptomLog.fromMap({
        'date': '2026-09-21',
        'symptom': 'mystery',
        'level': 9,
      });

      expect(restored.symptom, SymptomType.pain);
      expect(restored.level, SymptomLog.maxLevel);
    });
  });
}
