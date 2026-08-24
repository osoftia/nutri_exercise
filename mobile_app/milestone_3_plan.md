---

# MILESTONE 3 — Technical Blueprint
## AI Routine Generation Wizard — Multi-Step Form Architecture

---

## 0. DESIGN TOKEN REFERENCE (from `app_theme.dart`)

| Role | Token | Hex | Usage in Wizard |
|---|---|---|---|
| Canvas BG | `AppColors.surface900` | `#0F172A` | Wizard page scaffold background |
| Card surface | `AppColors.surface800` | `#1E293B` | Step cards, input containers, selection tiles |
| Border / divider | `AppColors.surface700` | `#334155` | Inactive step borders, ghost button outlines |
| Primary glow | `AppColors.primary500` | `#3B82F6` | Active step indicator, focused input border, progress fill |
| Primary light | `AppColors.primary300` | `#93C5FD` | Completed step check icon, progress trail |
| Primary mid | `AppColors.primary400` | `#60A5FA` | Icons inside active elements |
| Accent CTA | `AppColors.accent` | `#F97316` | "Generate Routine" button, highlight badges |
| Text high | `AppColors.textHigh` | `#F8FAFC` | Step titles, selected option labels |
| Text medium | `AppColors.textMedium` | `#CBD5E1` | Step descriptions, input hint text |
| Text low | `AppColors.textLow` | `#64748B` | Inactive step labels, captions |
| Success | `AppColors.success` | `#22C55E` | Confirmation checkmarks |
| Danger | `AppColors.danger` | `#EF4444` | Validation error messages |

| Spacing Token | Value | Usage |
|---|---|---|
| `AppSpacing.xs` | 4 px | Icon-to-label gaps |
| `AppSpacing.sm` | 8 px | Tight inner padding |
| `AppSpacing.md` | 12 px | Field-to-field gaps |
| `AppSpacing.lg` | 16 px | Card inner padding |
| `AppSpacing.xl` | 24 px | Section gaps, page padding |
| `AppSpacing.xxl` | 32 px | Major section separators |
| `AppSpacing.xxxl` | 48 px | Top/bottom page breathing room |

| Radius Token | Value | Usage |
|---|---|---|
| `AppRadius.sm` | 8 px | Chips, pills, small badges |
| `AppRadius.md` | 12 px | Buttons, input fields |
| `AppRadius.lg` | 20 px | Step cards, dialog surfaces |

---

## 1. WIZARD STEP ARCHITECTURE

### 1a. Step Order & Data Model

```
STEP 0          STEP 1           STEP 2            STEP 3           STEP 4
┌──────────┐   ┌──────────┐    ┌──────────┐     ┌──────────┐    ┌──────────┐
│   AGE    │──▶│   GOAL   │───▶│  FITNESS │────▶│   DAYS   │───▶│ CONFIRM  │
│  (int)   │   │  (enum)  │    │  (enum)  │     │  (int)   │    │ & GENER. │
└──────────┘   └──────────┘    └──────────┘     └──────────┘    └──────────┘
```

### 1b. Step Definitions

| Step | Field | Type | Validation Rule | Default |
|---|---|---|---|---|
| 0 — Age | `age` | `int` | `14 ≤ age ≤ 80`; non-null | `null` (required) |
| 1 — Goal | `goal` | `FitnessGoal` enum | Must select one of 4 options | `null` (required) |
| 2 — Fitness Level | `fitnessLevel` | `FitnessLevel` enum | Must select one of 3 options | `null` (required) |
| 3 — Available Days | `availableDays` | `int` | `2 ≤ days ≤ 6` | `null` (required) |
| 4 — Confirm & Generate | — | — | All prior steps non-null | — |

### 1c. Enum Definitions

```dart
// lib/core/models/wizard_models.dart

enum FitnessGoal {
  loseWeight,
  buildMuscle,
  maintain,
  endurance;

  String get label => switch (this) {
    loseWeight  => 'Lose Weight',
    buildMuscle => 'Build Muscle',
    maintain    => 'Maintain',
    endurance   => 'Endurance',
  };

  String get apiValue => switch (this) {
    loseWeight  => 'lose_weight',
    buildMuscle => 'build_muscle',
    maintain    => 'maintain',
    endurance   => 'endurance',
  };

  IconData get icon => switch (this) {
    loseWeight  => Icons.monitor_weight_outlined,
    buildMuscle => Icons.fitness_center,
    maintain    => Icons.balance_outlined,
    endurance   => Icons.directions_run,
  };
}

enum FitnessLevel {
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
    beginner     => 'Beginner',
    intermediate => 'Intermediate',
    advanced     => 'Advanced',
  };

  String get apiValue => name; // 'beginner', 'intermediate', 'advanced'

  IconData get icon => switch (this) {
    beginner     => Icons.looks_one,
    intermediate => Icons.looks_two,
    advanced     => Icons.looks_3,
  };

  String get description => switch (this) {
    beginner     => 'New to training or returning after a long break.',
    intermediate => 'Consistent training for 6+ months.',
    advanced     => '2+ years of structured programming.',
  };
}
```

### 1d. WizardData Value Object

```dart
// lib/core/models/wizard_models.dart (continued)

class WizardData {
  const WizardData({
    required this.age,
    required this.goal,
    required this.fitnessLevel,
    required this.availableDays,
  });

  final int age;
  final FitnessGoal goal;
  final FitnessLevel fitnessLevel;
  final int availableDays;

  /// Builds the preference string consumed by
  /// `RoutineRepository.generateRoutine(String)`.
  ///
  /// Example outputs:
  ///   "Age: 28, Goal: build_muscle, Level: intermediate, Days: 4"
  ///   "Age: 35, Goal: lose_weight, Level: beginner, Days: 3"
  String toPreferencesString() {
    return 'Age: $age, '
        'Goal: ${goal.apiValue}, '
        'Level: ${fitnessLevel.apiValue}, '
        'Days: $availableDays';
  }

  /// Immutable copy-with for step updates.
  WizardData copyWith({
    int? age,
    FitnessGoal? goal,
    FitnessLevel? fitnessLevel,
    int? availableDays,
  }) {
    return WizardData(
      age: age ?? this.age,
      goal: goal ?? this.goal,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      availableDays: availableDays ?? this.availableDays,
    );
  }
}
```

### 1e. Navigation & Progress

```
PROGRESS STEPPER (horizontal, top of wizard page)
═══════════════════════════════════════════════════════════════════════

  ┌───┐         ┌───┐         ┌───┐         ┌───┐
  │ ✓ │━━━━━━━━━│ ● │━━━━━━━━━│ ○ │━━━━━━━━━│ ○ │
  └───┘         └───┘         └───┘         └───┘
  Age           Goal          Level         Days

  ● = active step   → primary500 fill + primary300 glow (σ=8)
  ✓ = completed     → success fill + white check icon
  ○ = upcoming      → surface700 fill + textLow number
  ━ = trail         → completed: primary300; upcoming: surface700

  Progress fraction: (currentStep) / (totalSteps - 1)
  LinearProgressIndicator behind stepper bar:
    value: currentStep / 4.0
    backgroundColor: surface700
    valueColor: primary500
```

### 1f. Step Navigation Rules

```
FORWARD (Next):
  1. Validate current step
  2. If invalid → show inline error (danger color, shake animation)
  3. If valid → store answer in provider, animate to next step
  4. On step 3 (Days) → "Next" becomes "Review & Generate"

BACKWARD (Back):
  1. Always allowed (no data loss)
  2. Previous answers are preserved in provider state
  3. System back button / AppBar back arrow → go to previous step
  4. On step 0 → back exits wizard (pop to home)

SKIP:
  Not allowed — all steps are required.
```

---

## 2. STATE MANAGEMENT STRATEGY

### 2a. New Provider: `RoutineWizardProvider`

```dart
// lib/core/providers/wizard_provider.dart

enum WizardStatus { editing, generating, generated, error }

class RoutineWizardProvider extends ChangeNotifier {
  RoutineWizardProvider(this._repository);

  final RoutineRepository _repository;

  // ── Wizard step state ──────────────────────────────────────────────
  int _currentStep = 0;
  static const int totalSteps = 4; // 0..3 = data steps, 4 = confirm

  int? _age;
  FitnessGoal? _goal;
  FitnessLevel? _fitnessLevel;
  int? _availableDays;

  WizardStatus _status = WizardStatus.editing;
  String? _generatedText;
  String? _error;

  // ── Getters ────────────────────────────────────────────────────────
  int get currentStep => _currentStep;
  int? get age => _age;
  FitnessGoal? get goal => _goal;
  FitnessLevel? get fitnessLevel => _fitnessLevel;
  int? get availableDays => _availableDays;
  WizardStatus get status => _status;
  String? get generatedText => _generatedText;
  String? get error => _error;

  double get progress => _currentStep / totalSteps;

  bool get isCurrentStepValid => switch (_currentStep) {
    0 => _age != null && _age! >= 14 && _age! <= 80,
    1 => _goal != null,
    2 => _fitnessLevel != null,
    3 => _availableDays != null && _availableDays! >= 2 && _availableDays! <= 6,
    _ => false,
  };

  bool get canGoForward => isCurrentStepValid && _currentStep < totalSteps;
  bool get canGoBack => _currentStep > 0;
  bool get isOnConfirmStep => _currentStep == totalSteps;

  /// Builds WizardData snapshot (non-null assertion safe when on confirm step).
  WizardData? get wizardData {
    if (_age == null || _goal == null ||
        _fitnessLevel == null || _availableDays == null) return null;
    return WizardData(
      age: _age!,
      goal: _goal!,
      fitnessLevel: _fitnessLevel!,
      availableDays: _availableDays!,
    );
  }

  String? get preferencesPreview => wizardData?.toPreferencesString();

  // ── Step setters ───────────────────────────────────────────────────
  void setAge(int value) {
    _age = value;
    notifyListeners();
  }

  void setGoal(FitnessGoal value) {
    _goal = value;
    notifyListeners();
  }

  void setFitnessLevel(FitnessLevel value) {
    _fitnessLevel = value;
    notifyListeners();
  }

  void setAvailableDays(int value) {
    _availableDays = value;
    notifyListeners();
  }

  // ── Navigation ─────────────────────────────────────────────────────
  void nextStep() {
    if (!isCurrentStepValid) return;
    if (_currentStep < totalSteps) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    // Only allow going back to completed steps
    if (step < _currentStep) {
      _currentStep = step;
      notifyListeners();
    }
  }

  // ── Generation ─────────────────────────────────────────────────────
  Future<void> generateRoutine() async {
    final data = wizardData;
    if (data == null) return;

    _status = WizardStatus.generating;
    _error = null;
    notifyListeners();

    try {
      final preferences = data.toPreferencesString();
      _generatedText = await _repository.generateRoutine(preferences);
      _status = WizardStatus.generated;
    } catch (e) {
      _error = e.toString();
      _status = WizardStatus.error;
    }
    notifyListeners();
  }

  // ── Reset ──────────────────────────────────────────────────────────
  void reset() {
    _currentStep = 0;
    _age = null;
    _goal = null;
    _fitnessLevel = null;
    _availableDays = null;
    _status = WizardStatus.editing;
    _generatedText = null;
    _error = null;
    notifyListeners();
  }
}
```

### 2b. Provider Registration in `app.dart`

```
MODIFY: lib/app.dart
─────────────────────────────────────────────────────────────────────

Current tree:
  ChangeNotifierProvider<RoutineProvider>
    └── MaterialApp

New tree:
  MultiProvider
    ├── ChangeNotifierProvider<RoutineProvider>     (existing)
    └── ChangeNotifierProvider<RoutineWizardProvider>  (NEW)
        └── MaterialApp

Code change:
  Replace:
    ChangeNotifierProvider(
      create: (_) => RoutineProvider(routineRepository)..loadRoutine(),
      child: MaterialApp(...),
    )

  With:
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RoutineProvider(routineRepository)..loadRoutine(),
        ),
        ChangeNotifierProvider(
          create: (_) => RoutineWizardProvider(routineRepository),
        ),
      ],
      child: MaterialApp(...),
    )
```

### 2c. Provider Consumption Pattern

```
HomePage:
  context.watch<RoutineProvider>()          // existing — dashboard data
  context.read<RoutineWizardProvider>()     // on "Ask AI" tap → reset + navigate

WizardPage:
  context.watch<RoutineWizardProvider>()    // drives step UI, progress, validation
  context.read<RoutineProvider>()           // on generation success → loadRoutine()

GeneratedRoutineDialog:
  (no provider dependency — receives text as parameter)
```

---

## 3. INTEGRATION WITH MockRoutineRepository

### 3a. Generation Flow Sequence

```
┌──────────┐     ┌────────────────────┐     ┌──────────────────────┐     ┌──────────────────┐
│ WizardPage│     │RoutineWizardProvider│     │MockRoutineRepository │     │RoutineProvider   │
└────┬─────┘     └─────────┬──────────┘     └──────────┬───────────┘     └────────┬─────────┘
     │                     │                           │                          │
     │  tap "Generate"     │                           │                          │
     │────────────────────▶│                           │                          │
     │                     │  generateRoutine()        │                          │
     │                     │  status = generating      │                          │
     │                     │  notifyListeners()        │                          │
     │                     │──────────────────────────▶│                          │
     │                     │                           │  Future.delayed(latency) │
     │                     │                           │  returns description     │
     │                     │◀──────────────────────────│  with {userPreferences}  │
     │                     │  _generatedText = result  │                          │
     │                     │  status = generated       │                          │
     │                     │  notifyListeners()        │                          │
     │◀────────────────────│                           │                          │
     │  show result dialog │                           │                          │
     │                     │                           │                          │
     │  on dialog close:   │                           │                          │
     │  call RoutineProvider│                           │                          │
     │  .loadRoutine()     │                           │                          │
     │─────────────────────┼───────────────────────────┼─────────────────────────▶│
     │                     │                           │                          │
     │                     │                           │  getWeeklyRoutine()      │
     │                     │                           │◀─────────────────────────│
     │                     │                           │  returns updated routine │
     │  dashboard rebuilds │                           │                          │
     │◀────────────────────┼───────────────────────────┼──────────────────────────│
     │                     │                           │                          │
```

### 3b. Preferences String Mapping

The `WizardData.toPreferencesString()` method produces a structured string that the mock repository interpolates into the response template.

**Template** (from `mock_routine_payload.dart`):
```
'Mock AI routine for: {userPreferences}\n\n'
'Generated by llama3 using retrieved exercise and nutrition context.'
```

**Concrete Example 1:**
```
Input:  WizardData(age: 28, goal: buildMuscle, fitnessLevel: intermediate, availableDays: 4)
Output: "Age: 28, Goal: build_muscle, Level: intermediate, Days: 4"

Mock response:
  "Mock AI routine for: Age: 28, Goal: build_muscle, Level: intermediate, Days: 4

   Generated by llama3 using retrieved exercise and nutrition context."
```

**Concrete Example 2:**
```
Input:  WizardData(age: 45, goal: loseWeight, fitnessLevel: beginner, availableDays: 3)
Output: "Age: 45, Goal: lose_weight, Level: beginner, Days: 3"

Mock response:
  "Mock AI routine for: Age: 45, Goal: lose_weight, Level: beginner, Days: 3

   Generated by llama3 using retrieved exercise and nutrition context."
```

### 3c. Post-Generation Dashboard Refresh

After the `GeneratedRoutineDialog` is dismissed, the wizard page triggers:

```dart
// In WizardPage, after dialog closes:
final routineProvider = context.read<RoutineProvider>();
await routineProvider.loadRoutine();
```

This causes the dashboard to rebuild with fresh data from `getWeeklyRoutine()`, reflecting any changes the "generation" may have caused (in mock mode, the same payload is returned, but the flow is production-ready).

### 3d. Loading State UI During Generation

```
WHILE status == WizardStatus.generating:
  ┌──────────────────────────────────────────────────────┐
  │  surface800 card, centered content                   │
  │                                                      │
  │  ┌──────────────────────────────────────────────┐    │
  │  │  ShimmerLoading (skeleton placeholder)       │    │
  │  │  ┌────────────────────────────────────────┐  │    │
  │  │  │ ████████████████████████████████████   │  │    │
  │  │  │ ██████████████████████                 │  │    │
  │  │  │ ████████████████████████████████████   │  │    │
  │  │  │ ████████████████                       │  │    │
  │  │  └────────────────────────────────────────┘  │    │
  │  └──────────────────────────────────────────────┘    │
  │                                                      │
  │  CircularProgressIndicator(                           │
  │    color: primary500,                                 │
  │    strokeWidth: 3,                                    │
  │  )                                                    │
  │  SizedBox(height: AppSpacing.lg)                      │
  │  AppHeading('Generating your routine...', h3)         │
  │  AppText('AI is crafting your personalized plan')     │
  │                                                      │
  └──────────────────────────────────────────────────────┘

  Shimmer effect:
    LinearGradient(
      colors: [surface800, surface700, surface800],
      stops: [0.0, 0.5, 1.0],
    )
    Animated with Transform.translate, duration: 1500ms, repeat
```

---

## 4. UI GUIDELINES — "Dark Anatomy" Aesthetic

### 4a. Wizard Page Scaffold

```
Scaffold(
  backgroundColor: AppColors.surface900,    // charcoal canvas
  appBar: AppBar(
    backgroundColor: AppColors.surface900,   // seamless blend
    leading: BackButton(color: textMedium),
    title: AppHeading('AI Routine Wizard', h3),
  ),
  body: SafeArea(
    child: Column(
      children: [
        WizardStepper(...),       // progress indicator
        Expanded(
          child: AnimatedSwitcher(  // step transitions
            duration: 300ms,
            child: _buildCurrentStep(),
          ),
        ),
        WizardNavBar(...),        // Back / Next buttons
      ],
    ),
  ),
)
```

### 4b. Step Card Design

Each step's content is wrapped in a card:

```
Container(
  margin: EdgeInsets.all(AppSpacing.xl),
  padding: EdgeInsets.all(AppSpacing.xl),
  decoration: BoxDecoration(
    color: AppColors.surface800,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: AppColors.surface700, width: 1),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary500.withValues(alpha: 0.05),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: Column(...),
)
```

### 4c. Step 0 — Age Input

```
┌──────────────────────────────────────────────────────────┐
│  surface800 card                                         │
│                                                          │
│  AppHeading('How old are you?', h2)                      │
│  SizedBox(height: AppSpacing.sm)                         │
│  AppText('We use your age to calibrate intensity.')      │
│  SizedBox(height: AppSpacing.xxl)                        │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │  TextField (styled)                              │    │
│  │  keyboardType: number                            │    │
│  │  textAlign: center                               │    │
│  │  style: displayLarge, primary500                 │    │
│  │  decoration:                                     │    │
│  │    filled: true                                  │    │
│  │    fillColor: surface900                         │    │
│  │    border: OutlineInputBorder(                   │    │
│  │      borderRadius: AppRadius.md,                 │    │
│  │      borderSide: surface700,                     │    │
│  │    )                                             │    │
│  │    focusedBorder: OutlineInputBorder(             │    │
│  │      borderSide: primary500, 2px                 │    │
│  │    )                                             │    │
│  │    + primary500 glow shadow on focus              │    │
│  │  hintText: '25'                                  │    │
│  │  hintStyle: displayLarge, textLow                │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  if (validationError)                                    │
│    AppText(errorMsg, style: TextStyle(color: danger))    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 4d. Step 1 — Goal Selection (Tile Grid)

```
┌──────────────────────────────────────────────────────────┐
│  surface800 card                                         │
│                                                          │
│  AppHeading('What is your goal?', h2)                    │
│  SizedBox(height: AppSpacing.sm)                         │
│  AppText('Choose the outcome that matters most.')        │
│  SizedBox(height: AppSpacing.xxl)                        │
│                                                          │
│  ┌─────────────────┐  ┌─────────────────┐               │
│  │  SelectionTile  │  │  SelectionTile  │               │
│  │  ⚖ Lose Weight  │  │  💪 Build Muscle│               │
│  │                 │  │                 │               │
│  │  surface900 bg  │  │  primary500 bg  │ ← selected    │
│  │  surface700 bdr │  │  @ 0.15α fill   │               │
│  │                 │  │  primary500 bdr │               │
│  │                 │  │  + glow shadow  │               │
│  └─────────────────┘  └─────────────────┘               │
│  ┌─────────────────┐  ┌─────────────────┐               │
│  │  SelectionTile  │  │  SelectionTile  │               │
│  │  ⚖ Maintain     │  │  🏃 Endurance   │               │
│  └─────────────────┘  └─────────────────┘               │
│                                                          │
└──────────────────────────────────────────────────────────┘

SelectionTile states:
  UNSELECTED:
    fill: surface900
    border: surface700, 1.5px
    icon: textLow
    label: textMedium

  SELECTED:
    fill: primary500 @ 0.12α
    border: primary500, 2px
    glow: BoxShadow(primary500 @ 0.25α, blur: 16)
    icon: primary400
    label: textHigh
    checkmark: success icon, top-right corner

  Tile dimensions: Expanded in 2-column grid
  Tile padding: AppSpacing.xl vertical, AppSpacing.lg horizontal
  Tile radius: AppRadius.lg
  Icon size: 36
```

### 4e. Step 2 — Fitness Level (Vertical Cards)

```
┌──────────────────────────────────────────────────────────┐
│  surface800 card                                         │
│                                                          │
│  AppHeading('Your fitness level', h2)                    │
│  SizedBox(height: AppSpacing.sm)                         │
│  AppText('Be honest — this shapes volume and load.')     │
│  SizedBox(height: AppSpacing.xxl)                        │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │  ① Beginner                                     │    │
│  │  New to training or returning after a long break.│    │
│  └──────────────────────────────────────────────────┘    │
│  SizedBox(height: AppSpacing.md)                         │
│  ┌──────────────────────────────────────────────────┐    │
│  │  ② Intermediate                          ✓      │    │ ← selected
│  │  Consistent training for 6+ months.              │    │
│  └──────────────────────────────────────────────────┘    │
│  SizedBox(height: AppSpacing.md)                         │
│  ┌──────────────────────────────────────────────────┐    │
│  │  ③ Advanced                                     │    │
│  │  2+ years of structured programming.             │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘

Each option card:
  Container(
    padding: EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: selected ? primary500 @ 0.10α : surface900,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: selected ? primary500 : surface700,
        width: selected ? 2 : 1,
      ),
    ),
    child: Row(
      children: [
        Icon(level.icon, color: selected ? primary400 : textLow, size: 28),
        SizedBox(width: AppSpacing.lg),
        Expanded(Column(
          crossAxisAlignment: start,
          children: [
            AppHeading(level.label, h3),
            AppText(level.description),
          ],
        )),
        if (selected) Icon(Icons.check_circle, color: success),
      ],
    ),
  )
```

### 4f. Step 3 — Available Days (Slider + Chips)

```
┌──────────────────────────────────────────────────────────┐
│  surface800 card                                         │
│                                                          │
│  AppHeading('Days per week', h2)                         │
│  SizedBox(height: AppSpacing.sm)                         │
│  AppText('How many days can you commit to training?')    │
│  SizedBox(height: AppSpacing.xxl)                        │
│                                                          │
│                    ┌─────────┐                            │
│                    │    4    │  ← displayLarge, primary500│
│                    │  days   │  ← bodyMedium, textMedium  │
│                    └─────────┘                            │
│                                                          │
│  2 ───●━━━━━━━━━━━━━━━━●━━━━━━━━━●─── 6                 │
│       Slider (min:2, max:6, divisions:4)                 │
│       activeColor: primary500                            │
│       inactiveColor: surface700                          │
│       thumb: primary500 with primary300 glow             │
│                                                          │
│  Day chips row:                                          │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐            │
│  │ Mo │ │ Tu │ │ We │ │ Th │ │ Fr │ │ Sa │            │
│  └────┘ └────┘ └────┘ └────┘ └────┘ └────┘            │
│  ◀── first N chips highlighted (primary500 fill) ──▶    │
│  remaining chips: surface700 fill, textLow               │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 4g. Step 4 — Confirmation & Generate

```
┌──────────────────────────────────────────────────────────┐
│  surface800 card                                         │
│                                                          │
│  AppHeading('Review your profile', h2)                   │
│  SizedBox(height: AppSpacing.xl)                         │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │  SummaryRow                                      │    │
│  │  ┌────────┐                                      │    │
│  │  │  🎂    │  Age              28                │    │
│  │  └────────┘                                      │    │
│  │  ─────────────────────────────────────────────── │    │
│  │  ┌────────┐                                      │    │
│  │  │  🎯    │  Goal             Build Muscle       │    │
│  │  └────────┘                                      │    │
│  │  ─────────────────────────────────────────────── │    │
│  │  ┌────────┐                                      │    │
│  │  │  💪    │  Level            Intermediate       │    │
│  │  └────────┘                                      │    │
│  │  ─────────────────────────────────────────────── │    │
│  │  ┌────────┐                                      │    │
│  │  │  📅    │  Days/week        4                  │    │
│  │  └────────┘                                      │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
│  SizedBox(height: AppSpacing.sm)                         │
│  AppCaption('Preferences: "Age: 28, Goal: build_muscle, │
│              Level: intermediate, Days: 4"')              │
│                                                          │
│  SizedBox(height: AppSpacing.xxl)                        │
│                                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │         ⚡ GENERATE MY ROUTINE                    │    │
│  │                                                  │    │
│  │  Container(                                      │    │
│  │    width: double.infinity,                       │    │
│  │    padding: v: AppSpacing.lg,                    │    │
│  │    decoration: BoxDecoration(                    │    │
│  │      gradient: LinearGradient(                   │    │
│  │        colors: [accent, accent @ 0.85α],         │    │
│  │      ),                                          │    │
│  │      borderRadius: AppRadius.md,                 │    │
│  │      boxShadow: [                                │    │
│  │        BoxShadow(                                │    │
│  │          color: accent @ 0.40α,                  │    │
│  │          blurRadius: 24,                         │    │
│  │          spreadRadius: -4,                       │    │
│  │          offset: Offset(0, 8),                   │    │
│  │        ),                                        │    │
│  │      ],                                          │    │
│  │    ),                                            │    │
│  │    child: Row(                                   │    │
│  │      mainAxisAlignment: center,                │    │
│  │      children: [                                 │    │
│  │        Icon(Icons.auto_awesome, textHigh),       │    │
│  │        SizedBox(w: sm),                          │    │
│  │        Text('GENERATE MY ROUTINE',               │    │
│  │          style: titleLarge, textHigh),            │    │
│  │      ],                                          │    │
│  │    ),                                            │    │
│  │  )                                               │    │
│  └──────────────────────────────────────────────────┘    │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 4h. Wizard Bottom Navigation Bar

```
┌──────────────────────────────────────────────────────────┐
│  Container(                                              │
│    color: surface900,                                    │
│    padding: EdgeInsets.all(AppSpacing.xl),               │
│    child: Row(                                           │
│      mainAxisAlignment: spaceBetween,                   │
│      children: [                                         │
│        CustomButton(                                     │
│          label: 'Back',                                  │
│          variant: ghost,                                 │
│          onPressed: canGoBack ? previousStep : null,     │
│        ),                                                │
│        CustomButton(                                     │
│          label: currentStep < 3 ? 'Next' : 'Review',    │
│          variant: primary,                               │
│          onPressed: canGoForward ? nextStep : null,      │
│          // primary500 bg, disabled: surface700 bg       │
│        ),                                                │
│      ],                                                  │
│    ),                                                    │
│  )                                                        │
└──────────────────────────────────────────────────────────┘
```

---

## 5. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `lib/core/models/wizard_models.dart` | `FitnessGoal` enum, `FitnessLevel` enum, `WizardData` value object |
| **CREATE** | `lib/core/providers/wizard_provider.dart` | `RoutineWizardProvider` ChangeNotifier + `WizardStatus` enum |
| **CREATE** | `lib/ui/pages/wizard_page.dart` | Top-level wizard page: stepper, animated step content, nav bar |
| **CREATE** | `lib/ui/organisms/wizard_stepper.dart` | Horizontal progress stepper with glow states |
| **CREATE** | `lib/ui/organisms/wizard_nav_bar.dart` | Bottom Back/Next button bar |
| **CREATE** | `lib/ui/molecules/wizard_step_age.dart` | Step 0 — Age input with styled TextField |
| **CREATE** | `lib/ui/molecules/wizard_step_goal.dart` | Step 1 — Goal selection tile grid (2×2) |
| **CREATE** | `lib/ui/molecules/wizard_step_fitness.dart` | Step 2 — Fitness level vertical card list |
| **CREATE** | `lib/ui/molecules/wizard_step_days.dart` | Step 3 — Days slider + day chips |
| **CREATE** | `lib/ui/molecules/wizard_step_confirm.dart` | Step 4 — Summary review + Generate CTA |
| **CREATE** | `lib/ui/molecules/selection_tile.dart` | Reusable selectable tile (icon + label, selected/unselected states) |
| **CREATE** | `lib/ui/molecules/shimmer_loading.dart` | Shimmer skeleton placeholder widget |
| **CREATE** | `lib/ui/molecules/generating_overlay.dart` | Loading state with shimmer + spinner + message |
| **MODIFY** | `lib/app.dart` | Replace `ChangeNotifierProvider` with `MultiProvider`; add `RoutineWizardProvider` |
| **MODIFY** | `lib/ui/pages/home_page.dart` | Replace `_promptForPreferences()` + `_askAi()` with wizard navigation; fix controller bug; add "Generate Routine" button alongside "Ask AI" |
| **MODIFY** | `lib/ui/molecules/generated_routine_dialog.dart` | Accept optional `WizardData` for richer display; add "Apply to Dashboard" action |
| **MODIFY** | `lib/ui/atoms/custom_button.dart` | Add `CustomButtonVariant.accent` variant (orange CTA for Generate button) |

---

## 6. WIZARD UX FLOW — Complete User Journey

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         USER JOURNEY MAP                                    │
└─────────────────────────────────────────────────────────────────────────────┘

 ① HOME PAGE (Dashboard)
 │
 │  User sees "Ask AI" button (top-right of dashboard)
 │  OR new "Generate Routine" button (accent variant, more prominent)
 │
 │  tap →
 ▼
 ② NAVIGATE TO WIZARD PAGE
 │
 │  context.read<RoutineWizardProvider>().reset()
 │  Navigator.push(WizardPage)
 │
 │  Wizard page opens with:
 │    - Stepper showing Step 0 active
 │    - Age input card with autofocus
 │    - "Back" disabled, "Next" disabled until valid input
 │
 ▼
 ③ STEP 0: AGE
 │
 │  User types age (e.g. "28")
 │  Provider.setAge(28) → isCurrentStepValid becomes true
 │  "Next" button enables (primary500 glow)
 │
 │  tap "Next" →
 ▼
 ④ STEP 1: GOAL
 │
 │  AnimatedSwitcher transitions to goal grid
 │  Stepper: Step 0 shows ✓, Step 1 shows ●
 │  User taps "Build Muscle" tile
 │  Provider.setGoal(FitnessGoal.buildMuscle)
 │  Tile highlights with primary500 border + glow
 │
 │  tap "Next" →
 ▼
 ⑤ STEP 2: FITNESS LEVEL
 │
 │  Three vertical option cards
 │  User taps "Intermediate"
 │  Card highlights, check icon appears
 │
 │  tap "Next" →
 ▼
 ⑥ STEP 3: AVAILABLE DAYS
 │
 │  Large number display + slider + day chips
 │  User drags slider to 4
 │  Day chips: Mon–Thu light up in primary500
 │
 │  tap "Review" →
 ▼
 ⑦ STEP 4: CONFIRMATION
 │
 │  Summary card shows all 4 answers
 │  Preferences string preview shown as caption
 │  "GENERATE MY ROUTINE" button (accent orange, glowing)
 │
 │  tap "Generate" →
 ▼
 ⑧ GENERATING STATE
 │
 │  WizardStatus.generating
 │  Step content replaced by GeneratingOverlay:
 │    - Shimmer skeleton lines
 │    - CircularProgressIndicator (primary500)
 │    - "Generating your routine..." heading
 │    - "AI is crafting your personalized plan" subtitle
 │  Back/Next buttons hidden
 │  Stepper shows all steps completed (✓)
 │
 │  MockRoutineRepository.generateRoutine() runs
 │  (simulates latency: 500ms default)
 │
 │  on complete →
 ▼
 ⑨ RESULT DIALOG
 │
 │  WizardStatus.generated
 │  GeneratedRoutineDialog appears with:
 │    - smart_toy icon (primary400)
 │    - Generated text content
 │    - "Apply to Dashboard" button (accent)
 │    - "Close" button (ghost)
 │
 │  tap "Apply" →
 ▼
 ⑩ DASHBOARD REFRESH
 │
 │  Navigator.pop() closes dialog
 │  Navigator.pop() returns to home page
 │  RoutineProvider.loadRoutine() called
 │  Dashboard rebuilds with fresh routine data
 │  WizardProvider.reset() called for next session
 │
 └── DONE ──────────────────────────────────────────────────────────────────
```

### 6a. Error Path

```
IF WizardStatus.error:
  ┌──────────────────────────────────────────────────┐
  │  surface800 card                                 │
  │                                                  │
  │  Icon(Icons.error_outline, danger, size: 48)     │
  │  AppHeading('Generation Failed', h3)             │
  │  AppText(provider.error ?? 'Unknown error')      │
  │  SizedBox(height: AppSpacing.xl)                 │
  │  CustomButton('Try Again', primary)              │
  │    → provider.generateRoutine()                  │
  │  CustomButton('Go Back', ghost)                  │
  │    → provider.previousStep() or Navigator.pop()  │
  │                                                  │
  └──────────────────────────────────────────────────┘
```

### 6b. Cancellation Path

```
System back button on any step:
  → If step > 0: go to previous step
  → If step == 0: show confirmation dialog
      "Discard your progress?"
      [Cancel] [Discard]
  → Discard: Navigator.pop() + provider.reset()
```

---

## 7. BUGFIX — Disposed TextEditingController Lifecycle

### 7a. Root Cause Analysis

**File:** `lib/ui/pages/home_page.dart`, lines 102–133

```dart
Future<String?> _promptForPreferences() {
  final controller = TextEditingController();       // ← created here
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        // ...
        content: TextField(controller: controller, ...),
        // ...
      );
    },
  ).whenComplete(controller.dispose);               // ← BUG
}
```

**The Bug:** `.whenComplete(controller.dispose)` passes a **tear-off** of `controller.dispose`. While this appears correct, the problem manifests in two scenarios:

1. **Widget rebuild during dialog:** If the parent widget rebuilds (e.g., orientation change, theme change, or `setState` from another async operation), the `TextField` inside the dialog may attempt to access the controller after it has been disposed by the `.whenComplete` callback firing prematurely.

2. **Double-dispose risk:** The `_preferencesController` field (line 41) already exists as a class-level controller but is **unused** by `_promptForPreferences()`. This creates confusion and a dangling field-level controller that is disposed in `dispose()` but never used.

3. **Tear-off evaluation timing:** In some Dart versions, `controller.dispose` as a tear-off to `.whenComplete()` can be evaluated at registration time rather than invocation time in edge cases involving microtask scheduling.

### 7b. Fix Strategy — Replace Entirely with Wizard

The `_promptForPreferences()` method and its `AlertDialog` are **completely replaced** by the wizard flow. The fix is architectural, not a patch:

```
REMOVED from home_page.dart:
  ├── _preferencesController field (line 41)
  ├── _preferencesController.dispose() in dispose() (line 51)
  ├── _promptForPreferences() method (lines 102–133)
  └── AlertDialog + TextField inline dialog pattern

REPLACED BY:
  └── _launchWizard() method:
        void _launchWizard() {
          context.read<RoutineWizardProvider>().reset();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WizardPage()),
          );
        }
```

### 7c. Why This Eliminates the Bug

| Aspect | Old Pattern (Bug) | New Pattern (Fix) |
|---|---|---|
| Controller lifecycle | Created/disposed in method scope, fragile | No `TextEditingController` in wizard (age uses `TextEditingController` owned by `WizardStepAge`'s `State`, disposed in `State.dispose()`) |
| Dialog vs Page | `showDialog` creates overlay, rebuild risks | `Navigator.push` creates proper route with full lifecycle |
| State ownership | Controller in closure, disconnected from widget tree | Provider owns wizard state; widgets are stateless consumers |
| Disposal | `.whenComplete` tear-off, timing-sensitive | `State.dispose()` — deterministic, framework-managed |

### 7d. Age Step Controller Pattern (Safe)

```dart
// In WizardStepAge (StatefulWidget):
class _WizardStepAgeState extends State<WizardStepAge> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RoutineWizardProvider>();
    _controller = TextEditingController(
      text: provider.age?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();   // ← deterministic, framework-managed
    super.dispose();
  }

  // onChanged: provider.setAge(int.tryParse(value) ?? 0)
}
```

---

## 8. DEPENDENCY GRAPH

```
pubspec.yaml
  └── provider: ^6.1.2  (already present, no new deps)

app.dart
  └── MultiProvider
        ├── ChangeNotifierProvider<RoutineProvider>      (existing)
        │     └── injects RoutineRepository
        └── ChangeNotifierProvider<RoutineWizardProvider> (NEW)
              └── injects RoutineRepository

RoutineWizardProvider
  ├── consumes: RoutineRepository.generateRoutine(String)
  ├── produces: WizardData, WizardStatus, generatedText
  └── consumed by:
        ├── WizardPage (context.watch — drives step UI)
        ├── WizardStepper (context.watch — progress display)
        ├── WizardNavBar (context.watch — button enablement)
        └── WizardStepConfirm (context.watch — summary data)

WizardPage
  ├── depends on: WizardStepper, WizardNavBar
  ├── depends on: WizardStepAge, WizardStepGoal, WizardStepFitness, WizardStepDays, WizardStepConfirm
  ├── depends on: GeneratingOverlay (loading state)
  └── depends on: GeneratedRoutineDialog (result display)

HomePage (modified)
  ├── depends on: RoutineWizardProvider (context.read — launch wizard)
  ├── depends on: RoutineProvider (context.watch — dashboard data)
  └── "Ask AI" / "Generate Routine" → _launchWizard()

SelectionTile (reusable molecule)
  ├── depends on: AppColors, AppSpacing, AppRadius
  └── standalone, no provider dependency

ShimmerLoading (reusable molecule)
  ├── depends on: AppColors
  └── standalone animation widget
```

---

## 9. CUSTOM BUTTON EXTENSION

Add `accent` variant to `CustomButton` for the "Generate" CTA:

```dart
// ADD to CustomButtonVariant enum:
enum CustomButtonVariant { primary, ghost, text, accent }

// ADD case in build() switch:
CustomButtonVariant.accent => ElevatedButton(
  onPressed: disabled ? null : onPressed,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.textHigh,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.lg,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    elevation: 8,
    shadowColor: AppColors.accent.withValues(alpha: 0.4),
  ),
  child: Text(label),
),
```

---

## 10. IMPLEMENTATION ORDER (Recommended)

```
PHASE 1 — Foundation (no UI)
  ├── Step 1.1: Create wizard_models.dart (enums + WizardData)
  ├── Step 1.2: Create wizard_provider.dart (RoutineWizardProvider)
  └── Step 1.3: Modify app.dart (MultiProvider registration)

PHASE 2 — Atoms & Molecules
  ├── Step 2.1: Add accent variant to CustomButton
  ├── Step 2.2: Create SelectionTile molecule
  ├── Step 2.3: Create ShimmerLoading molecule
  └── Step 2.4: Create GeneratingOverlay molecule

PHASE 3 — Step Widgets
  ├── Step 3.1: Create WizardStepAge
  ├── Step 3.2: Create WizardStepGoal
  ├── Step 3.3: Create WizardStepFitness
  ├── Step 3.4: Create WizardStepDays
  └── Step 3.5: Create WizardStepConfirm

PHASE 4 — Organisms & Page
  ├── Step 4.1: Create WizardStepper organism
  ├── Step 4.2: Create WizardNavBar organism
  └── Step 4.3: Create WizardPage (composes everything)

PHASE 5 — Integration & Bugfix
  ├── Step 5.1: Modify HomePage — replace _promptForPreferences with wizard launch
  ├── Step 5.2: Modify HomePage — remove _preferencesController field
  ├── Step 5.3: Modify GeneratedRoutineDialog — richer display
  └── Step 5.4: Test full flow end-to-end
```

---

## 11. TESTING CHECKLIST

| # | Scenario | Expected Result |
|---|---|---|
| 1 | Open wizard, type age < 14 | "Next" stays disabled, validation error shown |
| 2 | Open wizard, type age = 28, tap Next | Advances to Step 1, stepper updates |
| 3 | Select goal, go back, verify selection preserved | Goal tile still selected on return |
| 4 | Complete all steps, tap Generate | Loading overlay appears, shimmer animates |
| 5 | Generation completes | Result dialog shows with mock text containing preferences |
| 6 | Tap "Apply" in dialog | Returns to dashboard, routine refreshes |
| 7 | Tap back on Step 0 | Confirmation dialog: "Discard progress?" |
| 8 | System back on generating state | Blocked or ignored (generation in progress) |
| 9 | Error during generation | Error card with "Try Again" button |
| 10 | Old "Ask AI" dialog pattern | Completely removed, no controller leak |

---
