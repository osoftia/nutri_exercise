# Milestone 17 — Neumorphic AI Assistant & Tech Debt Cleanup

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m17-ai-assistant-cleanup`
> **Contract:** `mobile_app/test/features/m17_ai_assistant.feature`

## 1. Scope

Two goals: (1) remove the orphaned legacy "Ask AI" flow that carries two known
M16 bugs, and (2) ship a proper neumorphic AI assistant reachable from every
tab of the app shell.

1. **Tech-debt cleanup** — delete the orphaned `HomePage` dashboard (and its
   now-unused children) that held the legacy "Ask AI" dialog. This eliminates:
   - the `TextEditingController` leak (`_promptForPreferences` disposes the
     controller in `.whenComplete` while the dialog is still animating out),
   - the `InteractiveBodyMap` infinite glow animation
     (`AnimationController.repeat()`), which made `pumpAndSettle` impossible.
2. **Neumorphic AI assistant** — a `NeumorphicFab` floating action button on
   `MainShellPage` that opens a `AiChatSheet` bottom sheet. The chat reuses the
   existing `AiService.ensureOnline()` guard and
   `RoutineRepository.generateRoutine()`.

## 2. Deleted legacy code

| File | Why |
|------|-----|
| `lib/ui/pages/home_page.dart` | orphaned dashboard; legacy "Ask AI" flow |
| `lib/ui/organisms/interactive_body_map.dart` | infinite glow `repeat()` |
| `lib/ui/organisms/routine_list.dart` | only used by `home_page` |
| `lib/ui/molecules/stat_card.dart` | only used by `home_page` |
| `lib/ui/molecules/generated_routine_dialog.dart` | superseded by inline chat |
| `lib/core/constants/muscle_vectors.dart` | only used by the body map |
| `test/features/home_page_test.dart`, `test/interactive_body_map_test.dart`, `test/ui/generated_routine_dialog_test.dart` | tests for deleted code |

`DietRepository`/`MockDietRepository` are **kept**: `mockDailyMenus` still seeds
`LocalDietRepository`, and the diet models are exercised by other tests.

## 3. New components

- `lib/ui/atoms/neumorphic_fab.dart` — `NeumorphicFab` (StatelessWidget). A
  circular button built on `NeumorphicContainer` (raised neumorphic shadows),
  with configurable `size`, `icon`, `color`, and a `Semantics`/`Tooltip` label.
  Keyed by its `tooltip` (default `Ask AI`).
- `lib/ui/molecules/ai_chat_sheet.dart` — `AiChatSheet` (StatefulWidget) plus a
  `showAiChatSheet(context, repository)` helper that opens it in a
  `showModalBottomSheet` (`isScrollControlled: true`).

### Chat sheet state & lifecycle

- `AiChatSheet` **owns** its `TextEditingController` and disposes it in
  `dispose()` — fixing the M16 controller-leak bug by construction.
- A `List<AiChatMessage>` holds user/AI bubbles; `_loading` drives a progress
  indicator. No infinite/repeating `AnimationController` is used.
- `_send()`: trims input, ignores empty text, appends the user bubble, clears
  the field, calls `_aiService.ensureOnline()` (offline → `showOfflineAiDialog`),
  then `repository.generateRoutine(text)` and appends the assistant bubble.

## 4. Wiring

- `MainShellPage` gains a `routineRepository` parameter and a
  `floatingActionButton: NeumorphicFab(onPressed: () => showAiChatSheet(...))`.
- `app.dart` (`NutriApp`) instantiates `MockRoutineRepository` (matching the
  mock-seeded schedule/nutrition pattern) and passes it down.

## 5. Testability

- `AiChatSheet` uses the existing `AiService()` + `ConnectivityPlatform.instance`
  fake pattern (as in the deleted `home_page_test.dart`): online is faked with a
  wifi result, offline with a none result.
- Keys: chat input `ai_chat_input`; send button uses the `NeumorphicFab` `Send`
  tooltip; the FAB is found via `find.byTooltip('Ask AI')`.
- Widget tests assert: FAB presence on the shell, sheet opening, online
  user+assistant messages, empty-send no-op, offline dialog, and clean dismissal
  (no disposed-controller error).
