---

# MILESTONE 4 — Technical Blueprint
## Offline-First SQLite Architecture

---

## 0. DESIGN TOKEN REFERENCE (from `app_theme.dart`)

| Role | Token | Hex | Usage in M4 |
|---|---|---|---|
| Canvas BG | `AppColors.surface900` | `#0F172A` | Scaffold / page background |
| Card surface | `AppColors.surface800` | `#1E293B` | Cards, dialogs, list tiles |
| Border / divider | `AppColors.surface700` | `#334155` | Inactive borders, ghost outlines |
| Primary glow | `AppColors.primary500` | `#3B82F6` | Active state, focus, progress |
| Primary light | `AppColors.primary300` | `#93C5FD` | Completed indicators |
| Primary mid | `AppColors.primary400` | `#60A5FA` | Icons inside active elements |
| Accent CTA | `AppColors.accent` | `#F97316` | "Save to Dashboard" / environment toggle highlight |
| Text high | `AppColors.textHigh` | `#F8FAFC` | Titles, values |
| Text medium | `AppColors.textMedium` | `#CBD5E1` | Secondary info |
| Text low | `AppColors.textLow` | `#64748B` | Captions, tertiary labels |
| Success | `AppColors.success` | `#22C55E` | Saved confirmation, completed sets |
| Danger | `AppColors.danger` | `#EF4444` | Delete / error states |

| Spacing Token | Value | Usage |
|---|---|---|
| `AppSpacing.xs` | 4 px | Icon-to-label gaps |
| `AppSpacing.sm` | 8 px | Tight inner padding |
| `AppSpacing.md` | 12 px | Field-to-field gaps |
| `AppSpacing.lg` | 16 px | Card inner padding |
| `AppSpacing.xl` | 24 px | Section gaps, page padding |
| `AppSpacing.xxl` | 32 px | Major section separators |

| Radius Token | Value | Usage |
|---|---|---|
| `AppRadius.sm` | 8 px | Chips, pills |
| `AppRadius.md` | 12 px | Buttons, input fields |
| `AppRadius.lg` | 20 px | Cards, dialogs |

---

## 1. PACKAGE INTEGRATION

### 1a. Current State

`pubspec.yaml` dependencies:
```
flutter, cupertino_icons, http, sqflite: ^2.4.1, path_provider: ^2.1.5,
connectivity_plus, flutter_local_notifications, provider: ^6.1.2
```

- `sqflite` is **already present** (used by `DatabaseHelper`).
- `path` is **NOT present** — must be added.

### 1b. Required Change

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  http: ^1.6.0
  sqflite: ^2.4.1
  path: ^1.9.0          # NEW — cross-platform path joining
  path_provider: ^2.1.5
  connectivity_plus: ^7.3.1
  flutter_local_notifications: ^19.4.0
  provider: ^6.1.2
```

### 1c. Why `path`?

`DatabaseHelper` currently builds the DB path with string concatenation:
```dart
final dir = await getApplicationDocumentsDirectory();
_database = await openDatabase('${dir.path}/$_dbName', ...);
```

The canonical sqflite location is `getDatabasesPath()` (from `package:sqflite/sqflite.dart`), which returns a platform-appropriate directory. Joining paths with `path.join()` is cross-platform safe (handles `/` vs `\`):

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final dbPath = p.join(await getDatabasesPath(), _dbName);
_database = await openDatabase(dbPath, ...);
```

This removes the `path_provider` dependency from `DatabaseHelper` (it remains used elsewhere, e.g. notifications).

---

## 2. EXERCISE MODEL EXTENSION

The mock payload includes `weight: String?` on every exercise, but the `Exercise` model does not carry it. M4 adds it so generated routines persist weights.

### 2a. `lib/core/models/routine_models.dart` — `Exercise`

```dart
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.weight,
  });

  final int id;
  final String name;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? weight;   // NEW

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      sets: (json['series'] ?? json['sets']) as int,
      reps: json['reps'] as String,
      restSeconds: json['restSeconds'] as int,
      weight: json['weight'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
      if (weight != null) 'weight': weight,
    };
  }
}
```

No other model changes required. `WorkoutDay` and `NutritionInfo` stay as-is.

---

## 3. DATABASEHELPER v2 — NORMALIZED SCHEMA

### 3a. Schema Design

```
┌─────────────────────────────┐
│         routines            │
│─────────────────────────────│
│ id            INTEGER PK    │
│ weekday       TEXT NOT NULL │
│ focus         TEXT NOT NULL │
│ created_at    TEXT          │
│ is_generated  INTEGER (0/1) │
└──────────────┬──────────────┘
               │ 1
               │
               │ N
┌──────────────▼──────────────┐
│         exercises           │
│─────────────────────────────│
│ id            INTEGER PK AI │
│ routine_id    INTEGER FK    │  → routines.id ON DELETE CASCADE
│ name          TEXT NOT NULL │
│ muscle_group  TEXT NOT NULL │
│ sets          INTEGER       │
│ reps          TEXT          │
│ rest_seconds  INTEGER       │
│ weight        TEXT NULL     │
│ position      INTEGER       │  → ordering within routine
└──────────────┬──────────────┘
               │ 1
               │
               │ N
┌──────────────▼──────────────┐
│           sets              │
│─────────────────────────────│
│ id            INTEGER PK AI │
│ exercise_id   INTEGER FK    │  → exercises.id ON DELETE CASCADE
│ set_number    INTEGER       │
│ reps          INTEGER       │
│ weight        TEXT NULL     │
│ is_completed  INTEGER (0/1) │
└─────────────────────────────┘
```

### 3b. `DatabaseHelper` v2 — Constants & Open

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper({Database? database}) : _databaseOverride = database;

  static const String _dbName = 'nutri_exercise.db';
  static const int _dbVersion = 2;   // bumped from 1

  final Database? _databaseOverride;
  Database? _database;

  Future<Database> get database async {
    final override = _databaseOverride;
    if (override != null) return override;
    final existing = _database;
    if (existing != null) return existing;
    final dbPath = p.join(await getDatabasesPath(), _dbName);
    _database = await openDatabase(
      dbPath,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }
}
```

### 3c. `_onCreate` — Fresh Install (v2 schema)

```dart
Future<void> _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE routines (
      id INTEGER PRIMARY KEY,
      weekday TEXT NOT NULL,
      focus TEXT NOT NULL,
      created_at TEXT,
      is_generated INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE exercises (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      routine_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      muscle_group TEXT NOT NULL,
      sets INTEGER NOT NULL,
      reps TEXT NOT NULL,
      rest_seconds INTEGER NOT NULL,
      weight TEXT,
      position INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (routine_id) REFERENCES routines (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE sets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise_id INTEGER NOT NULL,
      set_number INTEGER NOT NULL,
      reps INTEGER NOT NULL,
      weight TEXT,
      is_completed INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
    )
  ''');
  await db.execute('''
    CREATE TABLE diets (
      id INTEGER PRIMARY KEY,
      date TEXT NOT NULL,
      total_calories INTEGER NOT NULL,
      meals_json TEXT NOT NULL
    )
  ''');
}
```

### 3d. `_onUpgrade` — Migration v1 → v2

The v1 `routines` table stored exercises as a JSON blob (`exercises_json`). Migration:

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    // 1. Create the new normalized tables.
    await db.execute('''
      CREATE TABLE routines_v2 (
        id INTEGER PRIMARY KEY,
        weekday TEXT NOT NULL,
        focus TEXT NOT NULL,
        created_at TEXT,
        is_generated INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        routine_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        muscle_group TEXT NOT NULL,
        sets INTEGER NOT NULL,
        reps TEXT NOT NULL,
        rest_seconds INTEGER NOT NULL,
        weight TEXT,
        position INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (routine_id) REFERENCES routines_v2 (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE sets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        set_number INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        weight TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (exercise_id) REFERENCES exercises (id) ON DELETE CASCADE
      )
    ''');

    // 2. Migrate rows: read old blob, parse JSON, insert normalized.
    final oldRows = await db.query('routines');
    for (final row in oldRows) {
      final id = row['id'] as int;
      final weekday = row['weekday'] as String;
      final focus = row['focus'] as String;
      final exercisesJson = row['exercises_json'] as String? ?? '[]';
      final exercises = (jsonDecode(exercisesJson) as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();

      await db.insert('routines_v2', {
        'id': id,
        'weekday': weekday,
        'focus': focus,
        'created_at': DateTime.now().toIso8601String(),
        'is_generated': 0,
      });
      for (var i = 0; i < exercises.length; i++) {
        final ex = exercises[i];
        final exId = await db.insert('exercises', {
          'routine_id': id,
          'name': ex.name,
          'muscle_group': ex.muscleGroup,
          'sets': ex.sets,
          'reps': ex.reps,
          'rest_seconds': ex.restSeconds,
          'weight': ex.weight,
          'position': i,
        });
        // Seed one set row per planned set (reps parsed from range).
        for (var s = 1; s <= ex.sets; s++) {
          await db.insert('sets', {
            'exercise_id': exId,
            'set_number': s,
            'reps': _parseReps(ex.reps),
            'weight': ex.weight,
            'is_completed': 0,
          });
        }
      }
    }

    // 3. Swap tables.
    await db.execute('DROP TABLE routines');
    await db.execute('ALTER TABLE routines_v2 RENAME TO routines');
  }
}

int _parseReps(String reps) {
  final match = RegExp(r'\d+').firstMatch(reps);
  return match == null ? 10 : int.parse(match.group(0)!);
}
```

### 3e. CRUD Methods

```dart
// ── Routines ──────────────────────────────────────────────
Future<List<Map<String, Object?>>> getRoutines() async {
  final db = await database;
  return db.query('routines', orderBy: 'id');
}

Future<Map<String, Object?>?> getRoutineById(int id) async {
  final db = await database;
  final rows = await db.query('routines', where: 'id = ?', whereArgs: [id]);
  return rows.isEmpty ? null : rows.first;
}

Future<int> insertRoutine({
  required int id,
  required String weekday,
  required String focus,
  bool isGenerated = false,
}) async {
  final db = await database;
  return db.insert('routines', {
    'id': id,
    'weekday': weekday,
    'focus': focus,
    'created_at': DateTime.now().toIso8601String(),
    'is_generated': isGenerated ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> deleteRoutine(int id) async {
  final db = await database;
  await db.delete('routines', where: 'id = ?', whereArgs: [id]);
}

// ── Exercises ─────────────────────────────────────────────
Future<List<Map<String, Object?>>> getExercisesForRoutine(int routineId) async {
  final db = await database;
  return db.query('exercises',
      where: 'routine_id = ?', whereArgs: [routineId], orderBy: 'position');
}

Future<int> insertExercise({
  required int routineId,
  required Exercise exercise,
  required int position,
}) async {
  final db = await database;
  return db.insert('exercises', {
    'routine_id': routineId,
    'name': exercise.name,
    'muscle_group': exercise.muscleGroup,
    'sets': exercise.sets,
    'reps': exercise.reps,
    'rest_seconds': exercise.restSeconds,
    'weight': exercise.weight,
    'position': position,
  });
}

// ── Sets ──────────────────────────────────────────────────
Future<List<Map<String, Object?>>> getSetsForExercise(int exerciseId) async {
  final db = await database;
  return db.query('sets',
      where: 'exercise_id = ?', whereArgs: [exerciseId], orderBy: 'set_number');
}

Future<int> insertSet({
  required int exerciseId,
  required int setNumber,
  required int reps,
  String? weight,
}) async {
  final db = await database;
  return db.insert('sets', {
    'exercise_id': exerciseId,
    'set_number': setNumber,
    'reps': reps,
    'weight': weight,
    'is_completed': 0,
  });
}

// ── Maintenance ───────────────────────────────────────────
Future<void> clearAll() async {
  final db = await database;
  await db.delete('sets');
  await db.delete('exercises');
  await db.delete('routines');
  await db.delete('diets');
}
```

### 3f. Transactional Write Helper

```dart
/// Persists a full [WorkoutDay] (routine + exercises + sets) atomically.
Future<void> saveWorkoutDay(WorkoutDay day, {bool isGenerated = false}) async {
  final db = await database;
  await db.transaction((txn) async {
    await txn.insert('routines', {
      'id': day.id,
      'weekday': day.weekday,
      'focus': day.focus,
      'created_at': DateTime.now().toIso8601String(),
      'is_generated': isGenerated ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Remove stale children before re-inserting (idempotent upsert).
    await txn.delete('exercises', where: 'routine_id = ?', whereArgs: [day.id]);

    for (var i = 0; i < day.exercises.length; i++) {
      final ex = day.exercises[i];
      final exId = await txn.insert('exercises', {
        'routine_id': day.id,
        'name': ex.name,
        'muscle_group': ex.muscleGroup,
        'sets': ex.sets,
        'reps': ex.reps,
        'rest_seconds': ex.restSeconds,
        'weight': ex.weight,
        'position': i,
      });
      for (var s = 1; s <= ex.sets; s++) {
        await txn.insert('sets', {
          'exercise_id': exId,
          'set_number': s,
          'reps': _parseReps(ex.reps),
          'weight': ex.weight,
          'is_completed': 0,
        });
      }
    }
  });
}
```

---

## 4. LOCALROUTINEREPOSITORY v2 — FULL CRUD

### 4a. Class Shape

```dart
class LocalRoutineRepository implements RoutineRepository {
  LocalRoutineRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;
  bool _seeded = false;
```

### 4b. `getWeeklyRoutine()` — Assemble from Normalized Tables

```dart
@override
Future<List<WorkoutDay>> getWeeklyRoutine() async {
  await _seedIfNeeded();
  final rows = await _databaseHelper.getRoutines();
  final days = <WorkoutDay>[];
  for (final row in rows) {
    final id = row['id'] as int;
    final exerciseRows = await _databaseHelper.getExercisesForRoutine(id);
    final exercises = <Exercise>[];
    for (final exRow in exerciseRows) {
      final exId = exRow['id'] as int;
      final setRows = await _databaseHelper.getSetsForExercise(exId);
      exercises.add(Exercise(
        id: exId,
        name: exRow['name'] as String,
        muscleGroup: exRow['muscle_group'] as String,
        sets: exRow['sets'] as int,
        reps: exRow['reps'] as String,
        restSeconds: exRow['rest_seconds'] as int,
        weight: exRow['weight'] as String?,
      ));
    }
    days.add(WorkoutDay(
      id: id,
      weekday: row['weekday'] as String,
      focus: row['focus'] as String,
      exercises: exercises,
    ));
  }
  return days;
}
```

### 4c. `saveRoutine(WorkoutDay)` — Transactional Upsert

```dart
Future<void> saveRoutine(WorkoutDay day) async {
  await _seedIfNeeded();
  await _databaseHelper.saveWorkoutDay(day);
}
```

### 4d. `generateRoutine(String)` — Build Real Routine from Preferences

The M3 wizard passes a preferences string like:
```
"Age: 28, Goal: build_muscle, Level: intermediate, Days: 4"
```

Parse it and build a `WorkoutDay` with exercises selected from the mock exercise library, then persist:

```dart
@override
Future<String> generateRoutine(String userPreferences) async {
  await _seedIfNeeded();

  final goal = _extractGoal(userPreferences);       // 'build_muscle' etc.
  final days = _extractDays(userPreferences);       // 4
  final level = _extractLevel(userPreferences);     // 'intermediate'

  final exercises = _selectExercises(goal, days, level);
  final day = WorkoutDay(
    id: DateTime.now().millisecondsSinceEpoch,
    weekday: 'Weekly',
    focus: _focusLabel(goal),
    exercises: exercises,
  );
  await _databaseHelper.saveWorkoutDay(day, isGenerated: true);

  return 'Offline AI routine for: $userPreferences\n\n'
      'Generated locally from the exercise library. '
      '${exercises.length} exercises saved to your dashboard.';
}

String _extractGoal(String prefs) {
  final match = RegExp(r'Goal:\s*(\w+)').firstMatch(prefs);
  return match?.group(1) ?? 'build_muscle';
}

int _extractDays(String prefs) {
  final match = RegExp(r'Days:\s*(\d+)').firstMatch(prefs);
  return int.tryParse(match?.group(1) ?? '') ?? 4;
}

String _extractLevel(String prefs) {
  final match = RegExp(r'Level:\s*(\w+)').firstMatch(prefs);
  return match?.group(1) ?? 'intermediate';
}

String _focusLabel(String goal) => switch (goal) {
  'lose_weight' => 'Fat Loss Routine',
  'build_muscle' => 'Muscle Building Routine',
  'maintain' => 'Maintenance Routine',
  'endurance' => 'Endurance Routine',
  _ => 'AI Generated Routine',
};

List<Exercise> _selectExercises(String goal, int days, String level) {
  // Pull from the mock payload's exercise library, deduplicated by name.
  final library = <Exercise>[];
  for (final day in mockWorkoutRoutines) {
    for (final ex in day.exercises) {
      if (!library.any((e) => e.name == ex.name)) library.add(ex);
    }
  }
  // Scale volume by level: beginner 3 sets, intermediate 4, advanced 5.
  final setMultiplier = switch (level) {
    'beginner' => 3,
    'advanced' => 5,
    _ => 4,
  };
  final count = days.clamp(2, 6);
  final selected = library.take(count * 2).toList();
  return selected
      .map((ex) => Exercise(
            id: ex.id,
            name: ex.name,
            muscleGroup: ex.muscleGroup,
            sets: setMultiplier,
            reps: ex.reps,
            restSeconds: ex.restSeconds,
            weight: ex.weight,
          ))
      .toList();
}
```

### 4e. Delete & Clear

```dart
Future<void> deleteRoutine(int id) async {
  await _databaseHelper.deleteRoutine(id);
}

Future<void> clearAll() async {
  await _databaseHelper.clearAll();
  _seeded = false;
}
```

### 4f. Seeding (unchanged behavior)

```dart
Future<void> _seedIfNeeded() async {
  if (_seeded) return;
  final rows = await _databaseHelper.getRoutines();
  if (rows.isEmpty) {
    for (final day in mockWorkoutRoutines) {
      await _databaseHelper.saveWorkoutDay(day);
    }
  }
  _seeded = true;
}
```

---

## 5. WIZARD → SQLITE PERSISTENCE

### 5a. Recommended Integration: Option (a) — Repository Persists

`RoutineWizardProvider.generateRoutine()` already calls `_repository.generateRoutine(preferences)`. With `LocalRoutineRepository.generateRoutine()` now persisting the built `WorkoutDay` (section 4d), **no provider changes are required** — the persistence happens inside the repository.

### 5b. WizardPage "Apply to Dashboard" Flow

Current flow (M3):
```dart
// wizard_page.dart — after GeneratedRoutineDialog closes
final routineProvider = context.read<RoutineProvider>();
await routineProvider.loadRoutine();
wizardProvider.reset();
```

With M4, this already refreshes the dashboard from SQLite (since `RoutineProvider` is backed by `LocalRoutineRepository`). **No change needed** in `wizard_page.dart` for persistence — the generated routine is already in the DB.

### 5c. Optional Enhancement — GeneratedRoutineDialog

Add a "Saved to Dashboard" confirmation state. In `generated_routine_dialog.dart`, after "Apply to Dashboard" is tapped, show a success snackbar:

```dart
// In WizardPage, after dialog apply:
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Routine saved to your dashboard.')),
);
```

### 5d. Verification Path

1. Run with `Flavor.local` (useLocalDatabase: true).
2. Open wizard → complete steps → Generate.
3. `LocalRoutineRepository.generateRoutine()` builds + persists a `WorkoutDay` with `is_generated: 1`.
4. "Apply to Dashboard" → `RoutineProvider.loadRoutine()` reads from SQLite → dashboard shows the new routine.

---

## 6. ENVIRONMENT TOGGLING VIA PROVIDER

### 6a. New File: `lib/core/providers/environment_provider.dart`

```dart
import 'package:flutter/foundation.dart';

import '../config/environment_config.dart';
import '../data/diet_repository.dart';
import '../data/http_diet_repository.dart';
import '../data/http_routine_repository.dart';
import '../data/local_diet_repository.dart';
import '../data/local_routine_repository.dart';
import '../data/routine_repository.dart';
import '../mocks/mock_diet_repository.dart';
import '../mocks/mock_routine_repository.dart';

/// Runtime-switchable repository factory.
///
/// Holds the active [Flavor] and exposes the matching repository
/// implementations. Call [setFlavor] to switch Mock / Local / API at
/// runtime; listeners (RoutineProvider, RoutineWizardProvider) rebuild.
class EnvironmentProvider extends ChangeNotifier {
  EnvironmentProvider({required EnvironmentConfig config})
      : _config = config;

  EnvironmentConfig _config;
  late DietRepository _dietRepository = _buildDietRepository();
  late RoutineRepository _routineRepository = _buildRoutineRepository();

  EnvironmentConfig get config => _config;
  Flavor get flavor => _config.flavor;
  DietRepository get dietRepository => _dietRepository;
  RoutineRepository get routineRepository => _routineRepository;

  void setFlavor(Flavor flavor) {
    if (flavor == _config.flavor) return;
    _config = EnvironmentConfig.fromFlavor(flavor);
    _dietRepository = _buildDietRepository();
    _routineRepository = _buildRoutineRepository();
    notifyListeners();
  }

  DietRepository _buildDietRepository() {
    if (_config.useMockApi) return MockDietRepository();
    if (_config.useLocalDatabase) return LocalDietRepository();
    return HttpDietRepository(
      _config.apiBaseUrl.isEmpty
          ? ApiConstants.baseUrl
          : _config.apiBaseUrl,
      fallback: LocalDietRepository(),
    );
  }

  RoutineRepository _buildRoutineRepository() {
    if (_config.useMockApi) {
      return MockRoutineRepository(latency: _config.mockLatency);
    }
    if (_config.useLocalDatabase) return LocalRoutineRepository();
    return HttpRoutineRepository(
      _config.apiBaseUrl.isEmpty
          ? ApiConstants.baseUrl
          : _config.apiBaseUrl,
      fallback: LocalRoutineRepository(),
    );
  }
}
```

### 6b. `app.dart` — ProxyProvider Wiring

```dart
return MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => EnvironmentProvider(config: resolvedConfig),
    ),
    ProxyProvider<EnvironmentProvider, RoutineProvider>(
      update: (_, env, __) =>
          RoutineProvider(env.routineRepository)..loadRoutine(),
    ),
    ProxyProvider<EnvironmentProvider, RoutineWizardProvider>(
      update: (_, env, __) => RoutineWizardProvider(env.routineRepository),
    ),
  ],
  child: MaterialApp(
    ...
    home: HomePage(
      dietRepository: ... // read from env via context
    ),
  ),
);
```

> Note: `ProxyProvider` recreates the provider when `EnvironmentProvider` notifies, so switching flavor rebuilds `RoutineProvider` with the new repository and reloads the routine.

### 6c. HomePage — Environment Toggle UI

Add a debug dropdown in the dashboard AppBar:

```dart
// home_page.dart — AppBar actions
actions: [
  PopupMenuButton<Flavor>(
    icon: const Icon(Icons.settings_outlined, color: AppColors.textMedium),
    onSelected: (flavor) {
      final env = context.read<EnvironmentProvider>();
      env.setFlavor(flavor);
      // RoutineProvider is recreated by ProxyProvider; nothing else needed.
    },
    itemBuilder: (_) => [
      for (final flavor in Flavor.values)
        PopupMenuItem(value: flavor, child: Text(flavor.name)),
    ],
  ),
],
```

### 6d. Consumption Pattern

```
HomePage:
  context.watch<EnvironmentProvider>()   // flavor label, toggle
  context.watch<RoutineProvider>()       // dashboard data (recreated on flavor change)

RoutineProvider / RoutineWizardProvider:
  created by ProxyProvider with env.routineRepository
```

---

## 7. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `lib/core/providers/environment_provider.dart` | Runtime Mock/Local/API repository factory (ChangeNotifier) |
| **MODIFY** | `pubspec.yaml` | Add `path: ^1.9.0` dependency |
| **MODIFY** | `lib/core/models/routine_models.dart` | Add `weight: String?` to `Exercise` + fromJson/toJson |
| **MODIFY** | `lib/core/database/database_helper.dart` | v2 normalized schema (routines/exercises/sets), `onUpgrade` migration, CRUD, `saveWorkoutDay` transaction, `getDatabasesPath()` + `path.join` |
| **MODIFY** | `lib/core/data/local_routine_repository.dart` | Full CRUD, `generateRoutine()` builds real exercises from preferences, transactional writes |
| **MODIFY** | `lib/app.dart` | `ProxyProvider<EnvironmentProvider, RoutineProvider/WizardProvider>` wiring |
| **MODIFY** | `lib/ui/pages/home_page.dart` | Environment toggle (PopupMenuButton) in AppBar |
| **MODIFY** | `lib/ui/molecules/generated_routine_dialog.dart` | Optional "Saved to Dashboard" confirmation snackbar |

---

## 8. DEPENDENCY GRAPH

```
pubspec.yaml
  ├── sqflite: ^2.4.1   (present)
  └── path: ^1.9.0      (NEW)

DatabaseHelper
  ├── sqflite (getDatabasesPath, openDatabase)
  └── path (p.join)

LocalRoutineRepository
  ├── DatabaseHelper (CRUD)
  └── mock_routine_payload (exercise library for generateRoutine)

EnvironmentProvider
  ├── EnvironmentConfig / FlavorFactors
  ├── MockRoutineRepository / MockDietRepository
  ├── LocalRoutineRepository / LocalDietRepository
  └── HttpRoutineRepository / HttpDietRepository

app.dart
  └── MultiProvider
        ├── ChangeNotifierProvider<EnvironmentProvider>
        ├── ProxyProvider<EnvironmentProvider, RoutineProvider>
        └── ProxyProvider<EnvironmentProvider, RoutineWizardProvider>

RoutineProvider / RoutineWizardProvider
  └── consume env.routineRepository (recreated on flavor switch)

HomePage
  ├── context.watch<EnvironmentProvider>   (toggle UI)
  └── context.watch<RoutineProvider>       (dashboard)
```

---

## 9. IMPLEMENTATION ORDER (Recommended)

```
PHASE 1 — Foundation
  ├── Step 1.1: Add `path` to pubspec.yaml; flutter pub get
  ├── Step 1.2: Extend Exercise model with weight field
  └── Step 1.3: Rewrite DatabaseHelper (v2 schema + migration + CRUD)

PHASE 2 — Repository v2
  ├── Step 2.1: Rewrite LocalRoutineRepository (CRUD + generateRoutine)
  └── Step 2.2: Verify seeding + getWeeklyRoutine round-trip

PHASE 3 — Wizard Persistence
  ├── Step 3.1: Verify generateRoutine persists (no provider change needed)
  └── Step 3.2: Add "Saved to Dashboard" snackbar in wizard flow

PHASE 4 — Environment Toggle
  ├── Step 4.1: Create EnvironmentProvider
  ├── Step 4.2: Rewire app.dart with ProxyProvider
  └── Step 4.3: Add PopupMenuButton toggle in HomePage AppBar

PHASE 5 — Verification
  ├── Step 5.1: flutter analyze
  ├── Step 5.2: Manual test — Flavor.local wizard → SQLite persistence
  └── Step 5.3: Manual test — toggle Mock ↔ Local at runtime
```

---

## 10. TESTING CHECKLIST

| # | Scenario | Expected Result |
|---|---|---|
| 1 | Fresh install (no DB) | v2 schema created, seeded from mock payload |
| 2 | Upgrade from v1 DB | Old JSON-blob rows migrated to normalized tables |
| 3 | getWeeklyRoutine() | Returns WorkoutDay list with exercises + sets |
| 4 | saveRoutine() twice (same id) | Idempotent upsert, no duplicate exercises |
| 5 | deleteRoutine() | Cascades to exercises + sets |
| 6 | Wizard generate (Flavor.local) | Real routine persisted with is_generated=1 |
| 7 | Wizard "Apply to Dashboard" | Dashboard shows generated routine from SQLite |
| 8 | Toggle Mock → Local | RoutineProvider reloads from SQLite |
| 9 | Toggle Local → API | RoutineProvider reloads from HTTP (fallback local) |
| 10 | clearAll() | All tables emptied, re-seeds on next getWeeklyRoutine |
| 11 | Exercise weight field | Persisted and read back correctly |
| 12 | flutter analyze | 0 errors, 0 warnings (pre-existing infos OK) |

---

## 11. RISKS & NOTES

- **Migration safety**: `_onUpgrade` runs once per install. If a v1 DB exists, rows are migrated; fresh installs use `_onCreate` directly. The `routines_v2` temp-table swap avoids data loss.
- **`ProxyProvider` recreation**: switching flavor disposes the old `RoutineProvider` and creates a new one — any in-flight `loadRoutine()` on the old instance is abandoned. Acceptable for a debug toggle.
- **`path` vs `path_provider`**: `DatabaseHelper` moves to `getDatabasesPath()`; `path_provider` remains for notification/other uses.
- **Sets table**: seeded with one row per planned set using parsed reps. Future milestones can track per-set completion (`is_completed`).

---