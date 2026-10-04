# M48 Vector Refinement Backlog

- [x] Task 1: Revert Static Image Trials - Clean up any unused PNG/PDF static asset logic introduced for Luna.
- [x] Task 2: Advanced Vector Shading & Gradients - Enhance `BodyBlueprintPainter` with radial gradients, inner glows, professional neon blueprint trace lines, and subtle drop-shadows on the limbs and torso to give it a rich 3D-depth feel while preserving real-time morphing.
- [x] Task 3: Fix Calendar Overflow Bug - Fix the 4.3 px vertical overflow in `CalendarHistoryDialog` (`test/features/m31_task1_calendar_repair_widget_test.dart`) to ensure 100% green test suite.
- [x] Task 4: Testing & Verification - Run `flutter test` and `flutter analyze` to ensure all tests pass successfully with zero visual regressions.

## Verification

- `fvm flutter analyze`: passed with no issues.
- `fvm flutter test`: all 807 tests passed, including the refreshed painter
  golden and the narrow-screen calendar regression test.
