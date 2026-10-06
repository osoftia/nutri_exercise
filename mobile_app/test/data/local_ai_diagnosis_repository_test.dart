import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_ai_diagnosis_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:nutri_mobile_app/core/models/ai_diagnosis.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late LocalAiDiagnosisRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onCreate: DatabaseSchema.createAll,
      ),
    );
    repository = LocalAiDiagnosisRepository(
      databaseHelper: DatabaseHelper(database: db),
    );
  });

  tearDown(() => db.close());

  test('saves report, linked menus, and food preferences for offline use', () async {
    final report = AiDiagnosisReport(
      title: 'Nutrition report',
      summary: 'A balanced pattern may help support your goals.',
      considerations: const ['Discuss individual targets with your clinician.'],
      conditionIds: const ['diabetes', 'highCholesterol'],
      foodPreferences: 'Vegetarian; dislikes mushrooms',
      language: 'en',
      menus: const [
        AiSuggestedMenu(
          name: 'Monday',
          day: 'Monday',
          meals: [AiSuggestedMeal(name: 'Oats with berries')],
        ),
      ],
      createdAt: DateTime.utc(2026, 10, 6),
    );

    await repository.save(report);
    await repository.saveFoodPreferences('Vegetarian; dislikes mushrooms');

    final restored = await repository.latest();
    expect(restored, isNotNull);
    expect(restored!.title, report.title);
    expect(restored.conditionIds, report.conditionIds);
    expect(restored.foodPreferences, report.foodPreferences);
    expect(restored.menus.single.name, 'Monday');
    expect(restored.menus.single.meals.single.name, 'Oats with berries');
    expect(await repository.loadFoodPreferences(), report.foodPreferences);
  });
}
