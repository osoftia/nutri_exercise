import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_clinical_profile_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition_profile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('clinical profile survives repository recreation', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        singleInstance: false,
        onCreate: DatabaseSchema.createAll,
      ),
    );
    addTearDown(db.close);
    final helper = DatabaseHelper(database: db);
    final repository = LocalClinicalProfileRepository(databaseHelper: helper);
    final profile = ClinicalConditionProfile(
      conditions: {
        ClinicalCondition.diabetes: ClinicalSeverity.moderate,
        ClinicalCondition.hypertension: ClinicalSeverity.high,
      },
      mockCase: ClinicalMockCase.diabetes,
    );

    await repository.save(profile);
    final restored = await LocalClinicalProfileRepository(
      databaseHelper: helper,
    ).load();

    expect(restored, profile);
  });
}
