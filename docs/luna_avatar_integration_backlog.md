# Luna Avatar Integration Backlog

- [x] Task 1: Luna Prompt Engineering & Asset Generation Script - Write a Python/Dart script or automated prompt instruction leveraging Luna to generate high-resolution, photorealistic 3D athletic body models (male and female variants) with technical blueprint neon background lighting, detailed muscle definition, and cinematic 8k aesthetic.
- [ ] Task 2: Asset Integration in Flutter Assets - Save generated assets into `assets/images/luna_avatars/` and update `pubspec.yaml` to include them.
- [x] Task 3: UI Component Replacement / Toggle - Implement a clean switcher component in the Profile or Routines view allowing the user to toggle between the minimalist vector blueprint diagram and the new photorealistic Luna-generated human render.
- [ ] Task 4: Testing & Verification - Run `flutter test` and `flutter analyze` to ensure zero compilation or asset-loading errors.

## Execution status

- `fvm flutter analyze`: passed with no issues.
- `fvm flutter test`: 807 passed; one unrelated failure remains in
  `test/features/m31_task1_calendar_repair_widget_test.dart` due to a 4.3 px
  vertical overflow in `lib/ui/organisms/calendar_history_dialog.dart`.
- `test/ui/luna_avatar_switcher_test.dart`: passed (1 test). The complete test
  suite also exercised the missing-asset fallback without an asset-loading
  failure.
- The Luna image-generation capability was not exposed in this session, so the
  generated male/female PNGs are still pending in
  `mobile_app/assets/images/luna_avatars/`.
