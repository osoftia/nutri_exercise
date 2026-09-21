# NutriExercise — Master Milestones Progress Report

> **Document type:** Master progress report (cumulative)
> **Project:** NutriExercise — `mobile_app` (Flutter) + `backend` (.NET) + `web-portal`
> **Scope of this report:** Milestones **M15 → M45**, plus the post-M44 i18n sprint
> **Generated:** 2026-09-21
> **Sources of truth:** `docs/m*_execution_changes.log`, `docs/m*_*backlog.md`,
> `docs/milestone_*_plan.md`, `docs/specs/*.feature`,
> `mobile_app/test/features/*.feature`, `mobile_app/test/**`, and `git log`.

---

## 1. Executive Summary

| Dimension | State | Evidence |
| --- | --- | --- |
| **Overall project health** | 🟢 Green | `flutter analyze` → **No issues found!**; full suite → **723 passed, 0 failed** |
| **Test suite** | 🟢 723 tests passing | `fvm flutter test` (Flutter 3.29.0), 2026-09-21 |
| **Overall line coverage** | 🟡 82.39 % | `coverage/lcov.info` — `LH 5543 / LF 6728` |
| **Domain/logic coverage gate (≥ 95 %)** | 🟢 Met where it applies | `lib/core/domain` **95.56 %**, `lib/core/state` **97.86 %** (M16–M18 peaked at **97.59 %**) |
| **Architecture** | 🟢 Stable, layered, offline-first | Atomic design UI + `core` domain/data/state/services; SQLite schema **v11** |
| **Localization (i18n)** | 🟢 English + Spanish, 100 % of UI literals | Typed `AppStrings` (~120 members), `LanguageController`, `LocalizationScope`, SQLite-persisted choice |
| **SDK pinning** | 🟢 FVM **Flutter 3.29.0** (`.fvmrc`) | Verified with `fvm flutter --version` → `Flutter 3.29.0 • Dart 3.7.0` |
| **Known gaps / tech debt** | 🟡 Tracked | M31 Tasks 2–5 pending; `lib/core/data` host coverage 40.41 %; CI SDK version mismatch (3.38.3 vs 3.29.0); no automated coverage threshold gate |

### 1.1 Project health

The application has matured from a dashboard prototype into a feature-complete,
offline-first fitness/nutrition companion. The `main` branch is **123 commits
ahead of `origin/main`** and carries a clean working tree at the time of this
report. Every milestone since M15 was delivered under a strict TDD loop
(failing tests → implementation → `flutter analyze` + `flutter test` → commit),
and the majority shipped an accompanying Gherkin `.feature` contract.

### 1.2 Test suite health

- **723 tests passing, 0 failures**, run on the project-pinned FVM SDK (3.29.0).
- Suite growth across the ledger: `129 (M15) → 164 (M16) → 172 (M17) → 194 (M18)
  → 239 (M21) → 318 (M26) → 338 (M27) → 354 (M28) → 362 (M29) → 376 (M32)
  → 409 (M33) → 415 (M34) → 641 (M42) → 664 (M43) → 682 (M44) → 693 (M44-exact)
  → 715 (i18n) → 723 (i18n full coverage)`.
- Coverage is measured with `flutter test --coverage` and uploaded as the
  `mobile-coverage` CI artifact.

### 1.3 Architecture state

- **No third-party state-management library.** `ChangeNotifier` controllers
  consumed through `ListenableBuilder`, `StatefulWidget` + `setState` for local
  UI state, and constructor-based dependency injection from `app.dart`.
- **Offline-first SQLite** (`sqflite` + `path_provider`), schema **v11**, with
  forward `onUpgrade` migrations for every added table/column.
- **Atomic-design UI** (`atoms → molecules → organisms → pages`) under `lib/ui`,
  with the domain/data/state/services core under `lib/core`.
- **Local notifications** via `flutter_local_notifications` + `timezone`, with
  Android background-isolate action handling and reboot-safe receivers.
- **Reactive i18n** via an `InheritedWidget` scope wrapping the shell.

### 1.4 Multi-language (i18n) readiness

The i18n sprint (post-M44) delivered a fully reactive, persistent bilingual
experience:

- `AppLanguage` domain enum with locale parsing/fallback (`en`, `es`).
- `AppStrings` typed contract (**~120 members**, including parameterized
  formatters) with complete `english_strings.dart` / `spanish_strings.dart`.
- `LanguageController` persisted to SQLite (`app_settings` table, DB v11),
  restored at startup and switchable from the Profile tab.
- `LocalizationScope` rebuilds dependents in place on language change.
- A `_AllStringsProbe` test renders **every** getter to guarantee no blank keys.

---

## 2. Complete Milestone Ledger (M15 → M45)

**Status legend:** ✅ Completed & tested · 🟡 Partial / Active · ⬜ Planned / Requested

| ID | Title | Core features & scope requested | Status | Key technical artifacts |
| --- | --- | --- | --- | --- |
| **M15** | Long-Term Body Projection & SQLite Planning | 6-month projection engine; milestones at 1/3/6 months; neumorphic timeline selector; avatar morphing shoulders + waist | ✅ 129 tests | `projection_models.dart` (`generateProjectionPlan`), `ProjectionController`, `LocalProjectionRepository`, `ProjectionAvatarPainter`, `NeumorphicTimeline`; **DB v2** (`projection_plan`, `projection_milestone`) |
| **M16** | Total Coverage & Integration Testing | End-to-end integration test; coverage 85.32 % → 94.81 %; close M14→M15→M16 chain | ✅ 164 tests | `integration_test/app_test.dart`; fake platform interfaces (`ConnectivityPlatform`, `FlutterLocalNotificationsPlatform`) |
| **M17** | Neumorphic AI Assistant & Tech Debt Cleanup | Remove orphaned dashboard; circular AI FAB; neumorphic chat sheet; controller-leak & glow-animation fixes | ✅ 172 tests · 97.59 % | `neumorphic_fab.dart`, `ai_chat_sheet.dart` (`AiChatSheet`, `showAiChatSheet`) |
| **M18** | AI Backend Integration (C# .NET & Ollama) | Real HTTP `POST /api/ai/chat`; typed HTTP client; controller transcript/loading/error mapping | ✅ 194 tests · 97.5 % | `ai_chat_service.dart` (+3 typed exceptions), `ai_chat_controller.dart`, `api_constants.aiChatPath` |
| **M19** | Tamagotchi Interactive Avatar | Four muscle groups (Core/Arms/Chest/Legs); growth/decay; tier heatmap (C/B/A/S); size-from-mass body map | ✅ 23 targeted tests | `muscle_tamagotchi_state.dart`, `tamagotchi_groups.dart`, refactored `InteractiveBodyMap` |
| **M20** | — | *No M20 milestone was defined in the ledger.* | ⬜ n/a | — |
| **M21** | Local Notifications & Text Logger | Daily 20:00 "What did you eat and train today?"; tap opens text-log sheet; SQLite per-day summary | ✅ 239 tests | `daily_log.dart`, `DailyLogController`, `NotificationNavigationController`, `DailyLogSheet`, `NotificationScheduler` seam; **DB v3** (`daily_logs`) |
| **M22** | Dynamic BMI Avatar & Nutrition Visualizer | Daily nutrition totals on avatar; BMI-driven baseline width; core bloat turns red and expands; accumulation | ✅ Tested | Dynamic avatar painter, nutrition totals state, `log_parse_response` |
| **M23** | Smart Autocomplete Logger & Profile Quick-Edit | Profile defaults (60 kg / 1.70 m); profile info card + edit icon; autocomplete from history; exact-match cache bypasses AI | ✅ Tested | Profile controller/quick-edit, daily-log autocomplete, raw-text + parsed-JSON cache |
| **M24** | Advanced Graphics & Exercise Color Mapping | `ExerciseMuscleMapper` primary/secondary regions; red/orange overrides; smooth `TweenAnimationBuilder` transitions; clear/replace overrides | ✅ Tested | `ExerciseMuscleMapper`, `regionColorOverrides`, animated body-map colors |
| **M25** | Autonomous Sprint — Layout, Logging, Anatomy, History | Quick Add under body map; exercise logging fix; slimming effect; split arms/legs; calendar history & editor | ✅ 5/5 tasks | Split-limb vectors (upper arms/forearms, thighs/calves), calendar history dialog/editor |
| **M26** | Interactive & Dynamic Notifications | POST_NOTIFICATIONS + exact alarms; top-meals history query; 8/13/19 meal reminders with action buttons; background isolate writes SQLite | ✅ 318 tests | `notification_background_handler.dart` (`@pragma('vm:entry-point')`), `meal_presets.dart`, `MealAction`/`TamagotchiProgress` repos; **DB v6** (`tamagotchi_progress`, `meal_actions`) |
| **M27** | UI Sync, Stats Dashboard & Diet Gamification | AppBar History action; split-anatomy colors fix; Weekly Stats sheet (animated chart); healthy-vs-unhealthy food math; reactive meal notifications | ✅ 338 tests | `weekly_stat.dart`, `computeWeeklyStats`, `WeeklyStatsSheet`, `applyMeal` healthy/unhealthy, reactive notification id 4001 |
| **M28** | Social Sharing & Streak Export | `share_plus`; current-streak engine; Instagram-story `SocialShareCard`; PNG capture utility; native share | ✅ 354 tests | `SocialShareCard` (RepaintBoundary), `WidgetToImageExporter`, `ShareProgressController`, `currentStreak()`; **DB v7** (`healthy_meals`) |
| **M29** | Quick Add & Calendar Sync Fixes | Quick Add exactly below body map; Daily Log header action; persist entries with correct date; calendar instantly marks day | ✅ 362 tests | `daily_log_action`, calendar-sync upsert paths, `InteractiveBodyMap.animate` flag |
| **M30** | — | *No M30 milestone was defined in the ledger.* | ⬜ n/a | — |
| **M31** | Calendar Visual Repair & Nutrition Declutter | Calendar layout/overflow repair; persistence & reactivity fix; daily item "tierlist"; accordions; tamagotchi color/growth | 🟡 Task 1 done, **Tasks 2–5 pending** | Calendar visual repair (task 1); tasks 2–5 remain on the backlog |
| **M32** | 9 PM Exercise Notification & "EXERCISE NOT" | Test-payload button; daily 21:00 workout check-in with Yes/Not-yet; response handler computes burned calories + slimming | ✅ 376 tests | `exercise_response_handler.dart`, exercise reminder id 3201/3202, `exercise_yes`/`exercise_no`; **DB v8** (`daily_entries.burned`) |
| **M33** | Visual Rendering & State Sync Repair | Stomach bloat dynamic scale; notify-on-every-log; override-first color rendering; split anatomy distinct regions | ✅ 409 tests | `coreRenderScale`, `shouldRestartBloat`, `selectionBaseColor`, `sameRegionIdSet`, reverse-order hit testing |
| **M34** | State Binding, Split-Limb Painter & Response Sync | Force rebuild on every mutation; explicit split-limb painter; exercise response syncs state + SQLite + UI | ✅ 415 tests | `ListenableBuilder` rebuild wiring, split-limb painter enforcement |
| **M35** | Red-Flash, Strict Split Limbs & Re-render | Stomach red flash for 2 s on food log; disjoint limb bounding boxes; instant avatar re-render | ✅ Tested | Red-flash effect, strict split-limb gaps, `ListenableBuilder`/`AnimatedBuilder` |
| **M36** | Calendar Date Offset, Deletion & Verification | Day X opens exactly day X; prominent delete control; SQLite delete + state refresh + calendar dot clears | ✅ Tested | Date-alignment util, `calendar_history_dialog` delete, `DailyEntry` deletion path |
| **M37** | Body Blueprint | 12-segment schematic diagram; split limbs with joints; annotation callouts in gutters; tappable segments/callouts; food & exercise detail popups with local AI gap suggestion | ✅ Tested | `body_blueprint_diagram.dart`, `body_segment_geometry.dart`, `BodyBlueprintPainter`, `callout_layout_table.dart`, `BodyDetailController`, `body_food_detail_sheet`, `body_exercise_detail_sheet` |
| **M38** | Popups | Post-workout completion sheet (sets, burn, recovery); itemized consumption list with inline delete + sticky totals; notification action opens completion sheet | ✅ Tested | `exercise_completion_sheet.dart`, `exercise_completion.dart` (`RecoveryLevel`), consumption list, notification-action wiring |
| **M39** | Persistence | Durable per-day food log & workout completions; persisted overlay on planned workouts; controller persists mutations; notification handler records completions | ✅ Tested | `LocalBodyDetailRepository`, `DailyEntryRepository`, `food_logs`/`exercise_completions` tables, completion controller |
| **M40** | Structured Notifications | 9 PM check-in carries planned exercises (sets/reps/load); codec round-trip + malformed rejection; names-only fallback; handler persists structured completions | ✅ Tested | `exercise_check_in.dart` codec, structured payload in scheduler, navigation payload preservation |
| **M41** | Anatomy Gaps, Scaling, Toggle & Nutrition Action | Connect joints fluidly; restore tamagotchi scaling animation; toggleable "Confirm Workout"; matching Nutrition action button; verification | ✅ 5/5 tasks | `body_segment_geometry.dart` joint closing, scale mapper, `WorkoutCompletionController`, nutrition action button |
| **M42** | Persistence, Deletion-Only Nutrition, Reactivity & History FAB | Persist workout completions + tamagotchi mass across restarts; restrict nutrition popup to deletion; live segment rescaling; blueprint History FAB | ✅ 641 tests | `TamagotchiProgress.mass_json`, `ensureTamagotchiMassColumn`, `refreshWorkouts()`, `blueprint_fab.dart`; **DB v10** |
| **M43** | Quick Add Grams, Nutrition Semantics, Unified Avatar & FABs | Gram-scaling confirmation dialog; abdomen color semantics + aggregated summary; single `UnifiedBodyBlueprint`; standardized action rail on both tabs | ✅ 664 tests | `portion_scaler.dart`, `quick_add_grams_dialog.dart`, `unified_body_blueprint.dart`, `blueprint_action_rail.dart`, `routine_summary_sheet.dart` |
| **M44** | Avatar Restoration, Green Stomach, Grid & History Data | Organic curved torso + articulated joints shared by both tabs; healthy-protein surplus renders abdomen `#10B981`; technical grid background; weekly/calendar data fixes | ✅ 682 → 693 tests | `segment_status.healthy`, `body_segment_palette` `#10B981`, `isHealthySurplus`, `blueprint_grid_painter.dart`, `computeWeeklyStats` persisted burn, shared `DailyEntryRepository` |
| **i18n** | Full Localization (post-M44) | Persistent language controller; typed en/es dictionaries; reactive profile switcher; replace **all** hardcoded UI literals | ✅ 715 → 723 tests | `AppLanguage`, `AppStrings` (~120 members), `english_strings.dart`, `spanish_strings.dart`, `LanguageController`, `LocalizationScope`, `LanguageSwitcher`; **DB v11** (`app_settings`) |
| **M45** | Calendar Redesign & Nightly Notifications | Circular icon-button pattern with long-press tooltips; refactor calendar + symptom tracking views; nightly scheduled check-in notifications (rich icon actions); UI spacing/anti-saturation polish; tests | ⬜ Planned / Requested | Backlog requested: `docs/m45_calendar_redesign_backlog.md` (not yet created); builds on `BlueprintFab`/`NeumorphicFab`, `NotificationService` daily reminders |

> **Note on gaps:** milestones **M20** and **M30** are absent from the ledger —
> no plans, backlogs, feature files, or execution logs exist for those numbers.
> The numbering was intentionally skipped between the surrounding milestones.

---

## 3. Milestone Detail (narrative)

### 3.1 Foundations carried into M15 (pre-M15 context)

The app already had mock/local/HTTP flavors (`main_dev/local/qa/prod`), an
interactive vector body map, offline SQLite persistence, a 4-step routine
wizard, and the atomic-design UI scaffolding. M15 onward layered the projection
engine, AI assistant, gamified avatar, notifications, and the blueprint UI on
top of that base.

### 3.2 M15–M19 — Projection, coverage, AI, gamification

- **M15** introduced the first SQLite schema migration (v2) and a pure
  projection engine reused by both local and mock repositories.
- **M16** established the integration-test harness and a coverage discipline
  (94.81 %).
- **M17** replaced the orphaned "Ask AI" dashboard with a reusable circular
  `NeumorphicFab` + `AiChatSheet`, resolving two long-standing test blockers by
  construction (controller ownership; removal of the infinite glow animation).
- **M18** swapped the mock AI for a real HTTP round-trip with typed error
  mapping, keeping the M17 connectivity guard.
- **M19** introduced the `MuscleTamagotchiState` domain model (growth/decay,
  tier heatmap) that underpins every later avatar behavior.

### 3.3 M21–M29 — Notifications, nutrition, gamification, sharing

- **M21** added the daily 20:00 log reminder and a testable `NotificationScheduler`
  seam (needed because `FlutterLocalNotificationsPlugin` is a non-subclassable
  singleton).
- **M22–M24** made the avatar BMI-aware and nutrition-reactive, added profile
  quick-edit + autocomplete caching, and introduced primary/secondary exercise
  muscle coloring.
- **M25–M29** were autonomous sprints: split anatomy, calendar history/editor,
  interactive meal notifications with a background isolate, weekly stats,
  healthy/unhealthy food math, streaks and social sharing, and calendar sync.

### 3.4 M31–M36 — Rendering, state sync, calendar correctness

This block is dominated by **visual-rendering and state-reactivity repairs**:
stomach bloat scaling, split-limb rendering with enforced gaps, override-first
color painting, explicit rebuild triggers, and calendar date/deletion
correctness. It also delivered the **9 PM exercise check-in** (M32) and its
calorie/slimming response handler.

> ⚠️ **M31 is the only partially-completed milestone in the ledger.** Task 1
> (calendar visual repair) shipped; Tasks 2–5 (persistence/reactivity fix,
> daily item tierlist, nutrition accordions, tamagotchi color/growth) remain
> unchecked in `docs/m31_autonomous_backlog.md`.

### 3.5 M37–M40 — The Body Blueprint era

- **M37** replaced the informal body map with a **12-segment schematic
  blueprint** (head, neck, chest, abdomen, and split upper/lower limbs), with
  aspect-preserving geometry, gutter callouts that never overlap, 48×48
  accessible tap targets, and tappable food/exercise detail popups that include
  a local AI gap suggestion.
- **M38** added the post-workout completion summary (burn + recovery status)
  and the itemized consumption list with inline deletion and sticky totals.
- **M39** made body-detail data durable (per-day food logs and workout
  completions) and unified manual + notification-driven confirmation.
- **M40** structured the 9 PM payload so the notification carries planned
  exercises with sets/reps/load, with a names-only fallback and malformed-payload
  rejection.

### 3.6 M41–M44 — Avatar polish, persistence, unified blueprint

- **M41** closed the anatomical joints, re-linked tamagotchi scaling, made the
  workout confirmation a reversible toggle, and added the matching Nutrition
  action button.
- **M42** fixed workout/tamagotchi persistence (DB v10, guarded `ALTER TABLE`),
  restricted nutrition management to deletion-only, bound scaling to persisted
  state for instant rescaling, and added the blueprint History FAB.
- **M43** added the gram-scaling quick-add dialog, nutrition color semantics +
  aggregated summary, the single shared `UnifiedBodyBlueprint`, and the
  standardized `BlueprintActionRail` (History + summary action) on both tabs.
- **M44** restored the exact organic silhouette (slimmer limbs, cubic-Bézier
  torso, larger joint gap), introduced the **green healthy-protein stomach**
  (`SegmentStatus.healthy` → `#10B981`), painted the technical blueprint grid
  behind the figure on both tabs, and fixed the weekly-stats/calendar data
  providers (persisted `DailyEntry.burned`; shared repository).

### 3.7 i18n sprint (post-M44) — 100 % localization

Delivered in four tasks: `AppLanguage` → persistent `LanguageController`
(DB v11 `app_settings`) → typed `AppStrings` dictionaries + `LocalizationScope`
→ reactive Profile language switcher, followed by a full-coverage sweep that
removed every remaining hardcoded UI literal and added a probe test rendering
every dictionary getter.

### 3.8 M45 — Requested, not yet delivered

M45 is the **active/requested** milestone described in this session's brief:
a circular icon-button pattern (replacing elongated pills) with long-press
tooltips, a refactor of the calendar and symptom-tracking views to that pattern,
robust evening **nightly scheduled check-in notifications** (rich icon actions
for daily symptom/pain and activity logs), generous spacing/anti-saturation
polish, and dedicated tests. As of this report the M45 backlog file has not yet
been created and no M45 code exists on `main`.

---

## 4. Architecture & Tech-Debt Overview

### 4.1 Domain coverage gates (≥ 95 %)

| Layer | Lines hit / found | Coverage | Notes |
| --- | --- | --- | --- |
| `lib/core/domain/` | 839 / 878 | **95.56 %** | ✅ Meets the ≥ 95 % gate |
| `lib/core/state/` | 550 / 562 | **97.86 %** | ✅ Meets the ≥ 95 % gate |
| `lib/core/services/` | 297 / 344 | 86.34 % | 🟡 Platform-channel boundaries |
| `lib/core/models/` | 274 / 321 | 85.36 % | 🟡 JSON/serialization branches |
| `lib/core/data/` | 137 / 339 | 40.41 % | 🟡 SQLite repos rely on injected DB in host tests |
| `lib/ui/` | 2818 / 3385 | 83.25 % | 🟡 Large widget surface |
| **Overall** | **5543 / 6728** | **82.39 %** | Current `coverage/lcov.info` |

**Historical gate achievement:** M16 **94.81 %**, M17 **97.59 %**, M18 **97.5 %**
(new M18 code at 100 %). The ≥ 95 % gate is applied to the pure
domain/state logic, where it is met today. The overall figure is intentionally
diluted by the large UI surface added across M37–M44 and the i18n sweep.

> ℹ️ **CI note:** the workflow uploads `coverage/lcov.info` as an artifact but
> does **not** currently enforce a numeric coverage threshold. Adding an
> automated ≥ 95 % domain gate would make this contractual.

### 4.2 Test suite health

- **723 tests, 0 failures**, `fvm flutter test` on Flutter 3.29.0.
- `fvm flutter analyze` → **No issues found!** (121.6 s).
- Test organization: `test/{models,data,state,services,ui,features,i18n,theme,utils,constants,config}`.
- Gherkin contracts under `test/features/*.feature` (and `docs/specs/*.feature`).
- Golden test: `test/ui/goldens/body_blueprint_painter.png` (regenerated for the
  articulated + curved silhouette).

### 4.3 FVM / SDK configuration

| Config | Value |
| --- | --- |
| `.fvmrc` | `{ "flutter": "3.29.0" }` |
| `.fvm/fvm_config.json` | `{ "flutterSdkVersion": "3.29.0" }` |
| Resolved SDK | `Flutter 3.29.0 • Dart 3.7.0` (verified) |
| `mobile-ci.yml` (legacy) | Flutter **3.29.0** |
| `mobile_ci.yml` (active) | Flutter **3.38.3** ⚠️ mismatch |
| System PATH Flutter | **3.24.3** ⚠️ must not be used (breaks `Color.withValues`, `CardThemeData`) |

All milestone verification commands must run through `fvm flutter ...`. The
system PATH SDK re-resolves `pubspec.lock` to an incompatible state.

### 4.4 Database schema (v11)

`DatabaseHelper` (`nutri_exercise.db`, `_dbVersion = 11`) manages:

| Table | Introduced | Purpose |
| --- | --- | --- |
| `routines` | v1 | Weekly workout routines (exercises as JSON) |
| `diets` | v1 | Daily menus (meals as JSON) |
| `notification_prefs` | v1 | Notification preferences |
| `profile` | v1 | User profile |
| `daily_logs` | v3 (v4 `parsed_json`) | Free-text daily summaries + parsed cache |
| `projection_plan` / `projection_milestone` | v2 | Body projection plan & milestones |
| `daily_entries` | v5 (v7 `healthy_meals`, v8 `burned`) | Calendar day records |
| `tamagotchi_progress` | v6 (v10 `mass_json`) | Persisted tamagotchi mass/fullness |
| `meal_actions` | v6 | Background meal-action history |
| `food_logs` | v9 | Durable per-day food log |
| `exercise_completions` | v9 | Durable per-day workout completions |
| `app_settings` | v11 | Generic key/value (language, etc.) |

### 4.5 Technical-debt register

| # | Item | Severity | Notes |
| --- | --- | --- | --- |
| 1 | **M31 Tasks 2–5 unfinished** | Medium | Persistence/reactivity, daily tierlist, accordions, tamagotchi color/growth |
| 2 | **CI SDK mismatch** | Medium | `mobile_ci.yml` (3.38.3) vs FVM/`mobile-ci.yml` (3.29.0) |
| 3 | **No enforced coverage gate** | Low | Artifact only; consider a ≥ 95 % domain check |
| 4 | **`lib/core/data` host coverage 40 %** | Low | SQLite/`path_provider` channel boundaries; documented in M16/M17 |
| 5 | **Per-group decay timestamps** | Low | Deferred since M19 (uniform `applyDecay`) |
| 6 | **Fixed-offset timezone** | Low | Deferred IANA lookup (`flutter_timezone`) since M21 |
| 7 | **System PATH Flutter 3.24.3** | Low | Must use FVM; risk of accidental `pubspec.lock` downgrade |
| 8 | **M45 not yet started** | Info | Backlog + implementation pending |

---

## 5. Appendix

### 5.1 Execution logs (evidence)

`m6, m9, m10–m19, m21, m26–m29, m32–m33, m42–m44`, plus
`m44_exact_execution_changes.log`, `i18n_execution_changes.log`, and
`i18n_full_coverage_execution_changes.log` — all under `docs/`.

### 5.2 Gherkin feature contracts

Milestones with formal `.feature` files include: M1–M6, M9–M15, M17–M19, M21,
M25–M29, M31–M44, and i18n. Representative files:
`m37_body_diagram_blueprint.feature`, `m37_body_diagram_popups.feature`,
`m38_popup_summaries.feature`, `m39_persistence.feature`,
`m40_structured_notification.feature`, `m43_avatar_nutrition.feature`,
`m44_adjustments.feature`, `m44_exact_avatar.feature`,
`i18n_infrastructure.feature`.

### 5.3 Verification commands used for this report

```text
fvm flutter analyze        → No issues found!
fvm flutter test           → 723 passed, 0 failed
fvm flutter test --coverage → 723 passed; LF=6728 LH=5543 (82.39 %)
```

---

*End of report — compiled from all milestone logs, backlogs, plans, feature
files, and the test suite under `docs/` and `mobile_app/test/`.*
