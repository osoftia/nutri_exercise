# Milestone 23: Smart Autocomplete Logger & Profile Quick-Edit

## Overview

This milestone introduces three user-facing improvements:
1. **Sensible profile defaults** (60 kg, 1.70 m) so new users see realistic BMI calculations.
2. **Profile info card** next to the avatar, showing weight/height with a quick-edit icon.
3. **Smart autocomplete logger** that suggests previous entries and caches exact matches to avoid redundant AI calls.

The core architectural change is a **cache-first parsing strategy**: when the user submits a daily log, the app checks the local SQLite cache for an exact text match. If found, it loads the previously parsed data directly. If not found, it calls the backend AI parser, then caches the result for future use.

---

## 1. UserProfile Defaults

### Current State
`UserProfile.empty` has `weightKg: 0, heightCm: 0`. This causes:
- BMI calculation to fail (division by zero or invalid result).
- Profile form to show empty fields, requiring manual entry.

### Change
Update `lib/core/models/user_profile.dart`:
```dart
static const UserProfile empty = UserProfile(
  name: '',
  age: 0,
  weightKg: 60,  // was 0
  heightCm: 170, // was 0
  goal: FitnessGoal.muscleGain,
);
```

### Impact
- **Profile form**: Pre-fills with 60 kg / 170 cm when no profile is saved.
- **BMI calculation**: `HomePage._bodyWidthFactor` now computes a valid BMI even before the user saves a profile (60 kg / 1.70 m = BMI 20.8, normal range).
- **Avatar width**: The avatar renders with a realistic baseline width instead of the fallback `1.0`.

### Testing
- Unit test: `UserProfile.empty.weightKg == 60` and `UserProfile.empty.heightCm == 170`.
- Widget test: Profile form pre-fills with "60" and "170" when no profile is saved.

---

## 2. Profile Info Card UI

### Current State
`HomePage` renders `MuscleGroupVisualizer` (the avatar) but no profile summary. The user must navigate to the Profile tab to see their weight/height.

### Change
Add a **profile info card** next to the avatar in `HomePage._buildDashboard`:

```dart
Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      child: MuscleGroupVisualizer(
        tamagotchiState: _tamagotchi,
        bodyWidthFactor: _bodyWidthFactor,
      ),
    ),
    const SizedBox(width: AppSpacing.md),
    _ProfileInfoCard(
      profile: widget.profile,
      onEdit: () => _navigateToProfile(),
    ),
  ],
)
```

### `_ProfileInfoCard` Widget
A compact card showing:
- Weight: "70 kg"
- Height: "175 cm"
- Edit icon (pencil) in the top-right corner.

```dart
class _ProfileInfoCard extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${profile?.weightKg ?? 60} kg'),
          Text('${profile?.heightCm ?? 170} cm'),
        ],
      ),
    );
  }
}
```

### Navigation
`_navigateToProfile()` uses `Navigator.push` to open the Profile tab (or a dedicated profile edit page). The exact navigation depends on the app's routing structure (currently `MainShellPage` uses a `BottomNavBar`, so we may need to switch tabs programmatically or push a new route).

### Testing
- Widget test: `_ProfileInfoCard` renders weight/height and edit icon.
- Widget test: Tapping the edit icon triggers `onEdit` callback.

---

## 3. DailyLogRepository Schema Change

### Current State
`DailyLogRepository` saves `DailyLog(date, text)` to SQLite. The schema is:
```sql
CREATE TABLE daily_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  text TEXT NOT NULL
)
```

The parsed `LogParseResponse` is not persisted. Each time the user submits the same text, the backend is called again.

### Change
Add a `parsed_json` column to store the `LogParseResponse` as JSON:
```sql
CREATE TABLE daily_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  text TEXT NOT NULL,
  parsed_json TEXT  -- nullable, stores LogParseResponse as JSON
)
```

### Database Migration
Bump `DatabaseHelper._dbVersion` from 3 to 4. Add migration logic:
```dart
if (oldVersion < 4) {
  await db.execute('ALTER TABLE daily_logs ADD COLUMN parsed_json TEXT');
}
```

### Repository Interface
Extend `DailyLogRepository`:
```dart
abstract class DailyLogRepository {
  Future<DailyLog?> getByDate(String date);
  Future<void> save(DailyLog log);
  
  // New methods for M23:
  Future<LogParseResponse?> getByExactText(String text);
  Future<void> saveWithParse(DailyLog log, LogParseResponse parsed);
  Future<List<String>> getAllTexts();  // for autocomplete suggestions
}
```

### Implementation
`LocalDailyLogRepository` implements the new methods:
- `getByExactText(text)`: Query `SELECT parsed_json FROM daily_logs WHERE text = ?`. Deserialize JSON to `LogParseResponse`.
- `saveWithParse(log, parsed)`: Insert/update with `parsed_json = jsonEncode(parsed.toJson())`.
- `getAllTexts()`: Query `SELECT DISTINCT text FROM daily_logs ORDER BY date DESC LIMIT 50`.

### LogParseResponse Serialization
Add `toJson()` method to `LogParseResponse`:
```dart
Map<String, dynamic> toJson() => {
  'calories': calories,
  'protein': protein,
  'carbs': carbs,
  'fat': fat,
  'muscleGroups': muscleGroups,
};
```

### Testing
- Unit test: `saveWithParse` persists both text and parsed JSON.
- Unit test: `getByExactText` returns cached `LogParseResponse` for exact match.
- Unit test: `getByExactText` returns `null` for non-match.
- Unit test: `getAllTexts` returns distinct texts ordered by date.

---

## 4. SmartLogger Service

### Purpose
A cache-first parsing service that wraps `LogParseService`. It checks the local cache for an exact text match before calling the backend.

### Interface
```dart
class SmartLogger {
  final DailyLogRepository repository;
  final LogParseService parseService;

  SmartLogger({required this.repository, required this.parseService});

  /// Parses [text] using cache-first strategy.
  /// Returns cached LogParseResponse if exact match found, else calls backend.
  Future<LogParseResponse> parse(String text) async {
    // 1. Check cache
    final cached = await repository.getByExactText(text);
    if (cached != null) {
      return cached;
    }

    // 2. Cache miss → call backend
    final parsed = await parseService.parse(text);

    // 3. Save to cache (caller is responsible for saving the DailyLog)
    // Note: We don't save here because the caller (DailyLogController)
    // needs to save the DailyLog with the parsed data atomically.
    return parsed;
  }
}
```

### Integration with DailyLogController
Replace `LogParseService` with `SmartLogger` in `DailyLogController`:
```dart
class DailyLogController extends ChangeNotifier {
  final DailyLogRepository repository;
  final SmartLogger smartLogger;  // was LogParseService

  DailyLogController({
    required this.repository,
    required this.smartLogger,
  });

  Future<bool> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isParsing = true;
    _parseError = null;
    _parseResult = null;
    notifyListeners();

    try {
      // SmartLogger handles cache-first logic
      final parsed = await smartLogger.parse(trimmed);
      _parseResult = parsed;

      // Save DailyLog with parsed data
      final log = DailyLog(date: _date, text: trimmed);
      await repository.saveWithParse(log, parsed);

      _text = trimmed;
    } catch (e) {
      _parseError = 'Failed to parse: $e';
    } finally {
      _isParsing = false;
      notifyListeners();
    }

    return _parseResult != null;
  }
}
```

### Testing
- Unit test: `SmartLogger.parse` returns cached result for exact match (no backend call).
- Unit test: `SmartLogger.parse` calls backend for non-match, then returns parsed result.
- Unit test: `DailyLogController.submit` saves both text and parsed data to repository.

---

## 5. DailyLogSheet Autocomplete

### Current State
`DailyLogSheet` uses a plain `TextField` for input. No suggestions are provided.

### Change
Replace `TextField` with `Autocomplete<String>`:
```dart
Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<String>.empty();
    }
    return widget.suggestions.where((String option) {
      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
    });
  },
  onSelected: (String selection) {
    _controller.text = selection;
  },
  fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
    return TextField(
      key: const Key('daily_log_input'),
      controller: controller,
      focusNode: focusNode,
      maxLines: 5,
      textInputAction: TextInputAction.newline,
      decoration: const InputDecoration(
        hintText: 'Type your summary…',
        border: OutlineInputBorder(),
      ),
    );
  },
)
```

### Suggestions Source
`DailyLogSheet` receives `suggestions` as a parameter:
```dart
class DailyLogSheet extends StatefulWidget {
  final DailyLogController controller;
  final List<String> suggestions;  // from DailyLogRepository.getAllTexts()

  const DailyLogSheet({
    super.key,
    required this.controller,
    required this.suggestions,
  });
}
```

`showDailyLogSheet` fetches suggestions before opening the sheet:
```dart
Future<void> showDailyLogSheet(
  BuildContext context,
  DailyLogController controller,
  DailyLogRepository repository,
) async {
  final suggestions = await repository.getAllTexts();
  if (!context.mounted) return;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DailyLogSheet(
      controller: controller,
      suggestions: suggestions,
    ),
  );
}
```

### Testing
- Widget test: `Autocomplete` renders suggestions when user types.
- Widget test: Selecting a suggestion fills the input.

---

## 6. DailyLogController Integration

### Current State
`DailyLogController` uses `LogParseService` directly. The `submit` method calls `parseService.parse(text)` and saves the `DailyLog` (without parsed data).

### Change
- Replace `LogParseService` with `SmartLogger`.
- Update `submit` to save both text and parsed data using `repository.saveWithParse`.
- Add `loadSuggestions()` method to fetch autocomplete options.

### Updated Controller
```dart
class DailyLogController extends ChangeNotifier {
  final DailyLogRepository repository;
  final SmartLogger smartLogger;

  DailyLogController({
    required this.repository,
    required this.smartLogger,
  });

  // ... existing fields ...

  Future<List<String>> loadSuggestions() async {
    return await repository.getAllTexts();
  }

  Future<bool> submit(String text) async {
    // ... (see Section 4 for implementation)
  }
}
```

### Dependency Injection
Update `app.dart` to construct `SmartLogger` and inject it into `DailyLogController`:
```dart
final repository = LocalDailyLogRepository();
final parseService = LogParseService(baseUrl: ApiConstants.baseUrl);
final smartLogger = SmartLogger(repository: repository, parseService: parseService);

final dailyLogController = DailyLogController(
  repository: repository,
  smartLogger: smartLogger,
);
```

---

## 7. Files to Modify/Create

### Modified Files
1. `lib/core/models/user_profile.dart` — Update `UserProfile.empty` defaults.
2. `lib/core/models/log_parse_response.dart` — Add `toJson()` method.
3. `lib/core/database/database_helper.dart` — Bump version to 4, add migration for `parsed_json` column.
4. `lib/core/data/daily_log_repository.dart` — Add `getByExactText`, `saveWithParse`, `getAllTexts` methods.
5. `lib/core/data/local_daily_log_repository.dart` — Implement new methods.
6. `lib/core/mocks/mock_daily_log_repository.dart` — Implement new methods (in-memory cache).
7. `lib/core/state/daily_log_controller.dart` — Replace `LogParseService` with `SmartLogger`, update `submit` to save parsed data.
8. `lib/ui/molecules/daily_log_sheet.dart` — Replace `TextField` with `Autocomplete<String>`, accept `suggestions` parameter.
9. `lib/ui/pages/home_page.dart` — Add `_ProfileInfoCard` next to avatar, implement `_navigateToProfile`.
10. `lib/app.dart` — Construct `SmartLogger`, inject into `DailyLogController`.

### New Files
1. `lib/core/services/smart_logger.dart` — Cache-first parsing service.

---

## 8. Testing Strategy

### Unit Tests
- `test/models/user_profile_test.dart` — Verify `UserProfile.empty` defaults.
- `test/models/log_parse_response_test.dart` — Verify `toJson()` serialization.
- `test/data/daily_log_repository_test.dart` — Test `getByExactText`, `saveWithParse`, `getAllTexts`.
- `test/services/smart_logger_test.dart` — Test cache-first logic (hit/miss scenarios).
- `test/state/daily_log_controller_test.dart` — Test `submit` saves parsed data, `loadSuggestions` returns texts.

### Widget Tests
- `test/ui/daily_log_sheet_test.dart` — Test `Autocomplete` renders suggestions, selection fills input.
- `test/ui/home_page_test.dart` — Test `_ProfileInfoCard` renders, edit icon triggers navigation.

### Integration Tests
- End-to-end: User submits "Ate chicken and rice" → backend parses → cache stores → user submits same text again → cache hit (no backend call).

---

## 9. Risks & Mitigations

### Risk 1: Database Migration Failure
**Mitigation**: Test migration on a copy of the production database. Provide rollback script.

### Risk 2: Autocomplete Performance with Large Dataset
**Mitigation**: Limit `getAllTexts()` to 50 most recent entries. Use case-insensitive substring matching.

### Risk 3: Cache Invalidation
**Mitigation**: For M23, no cache invalidation (entries are append-only). Future milestone can add "delete entry" functionality.

### Risk 4: Profile Navigation Complexity
**Mitigation**: Use `Navigator.push` to open a dedicated profile edit page (simpler than switching tabs programmatically).

---

## 10. Acceptance Criteria

- [ ] Profile form pre-fills with 60 kg / 170 cm when no profile is saved.
- [ ] Profile info card displays weight/height next to avatar.
- [ ] Tapping edit icon navigates to profile page.
- [ ] DailyLogSheet shows autocomplete suggestions as user types.
- [ ] Selecting a suggestion fills the input.
- [ ] Exact text match bypasses backend and loads from cache.
- [ ] Non-exact match calls backend and caches result.
- [ ] All unit/widget tests pass.
- [ ] `flutter analyze` reports no issues.
