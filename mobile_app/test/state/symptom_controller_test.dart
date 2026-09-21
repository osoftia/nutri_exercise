import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';

void main() {
  SymptomController build([List<SymptomLog>? seed]) => SymptomController(
    repository: MockSymptomRepository(seed),
    date: DateTime(2026, 9, 21),
  );

  group('SymptomController (M45 Task 2)', () {
    test('defaults every symptom to no severity', () async {
      final controller = build();
      await controller.load();

      for (final type in SymptomType.values) {
        expect(controller.levelOf(type), 0);
      }
      expect(controller.hasAnyLogged, isFalse);
      expect(controller.isLoaded, isTrue);
    });

    test('hydrates severities from the repository', () async {
      final controller = build(
        const [
          SymptomLog(
            date: '2026-09-21',
            symptom: SymptomType.pain,
            level: 2,
          ),
          SymptomLog(
            date: '2026-09-21',
            symptom: SymptomType.stress,
            level: 1,
          ),
        ],
      );

      await controller.load();

      expect(controller.levelOf(SymptomType.pain), 2);
      expect(controller.levelOf(SymptomType.stress), 1);
      expect(controller.loggedTypes, [SymptomType.pain, SymptomType.stress]);
      expect(controller.hasAnyLogged, isTrue);
    });

    test('ignores readings for other days', () async {
      final controller = build(
        const [
          SymptomLog(
            date: '2026-09-20',
            symptom: SymptomType.pain,
            level: 3,
          ),
        ],
      );

      await controller.load();

      expect(controller.levelOf(SymptomType.pain), 0);
    });

    test('setLevel clamps to 0..3 and persists', () async {
      final repository = MockSymptomRepository();
      final controller = SymptomController(
        repository: repository,
        date: DateTime(2026, 9, 21),
      );

      await controller.setLevel(SymptomType.energy, 7);
      expect(controller.levelOf(SymptomType.energy), 3);

      await controller.setLevel(SymptomType.energy, -4);
      expect(controller.levelOf(SymptomType.energy), 0);

      final stored = await repository.getForDate('2026-09-21');
      expect(stored.single.level, 0);
    });

    test('cycle advances and wraps 3 -> 0', () async {
      final controller = build();

      expect(await controller.cycle(SymptomType.pain), 1);
      expect(await controller.cycle(SymptomType.pain), 2);
      expect(await controller.cycle(SymptomType.pain), 3);
      expect(await controller.cycle(SymptomType.pain), 0);
      expect(controller.levelOf(SymptomType.pain), 0);
    });

    test('notifies listeners on every mutation', () async {
      final controller = build();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();
      await controller.setLevel(SymptomType.discomfort, 2);

      expect(notifications, greaterThanOrEqualTo(2));
    });
  });
}
