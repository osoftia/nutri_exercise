# M35 Task 2 — Strict Split Limbs Vector Rendering

## Goal
Upper Arms vs Forearms and Thighs vs Calves are separated by visible
gaps (independent bounding boxes) so they can never merge into a single
limb block.

## Findings
- Split ids/paths exist, but the segment edges share seams: upper-arm
  bottom (y≈0.36) touches forearm top (y≈0.36); thigh bottom (y=0.80)
  touches calf top (y=0.80). At render scale the fills + strokes bleed
  into one continuous block.
- Existing hit-test taps sit well inside each segment
  (upper y≈0.25, forearm y≈0.47, thigh y≈0.73, calf y≈0.87 normalized),
  so a ~0.02–0.035 gap at the seams keeps every tap resolving.

## Change
- `muscle_vectors.dart`: pull upper-arm bottom edge up to y≈0.335–0.345,
  push forearm top down to y≈0.365, pull thigh bottom up to y≈0.785, push
  calf top down to y≈0.815. X-ranges and labels unchanged; mirror logic
  reuses the same shapes for R side + back view.
- Update the `muscleAt` seam comment (gaps replace overlaps).
- New test `test/constants/split_limb_gap_test.dart`: asserts the
  normalized bounding boxes of upper_arms/forearms and thighs/calves are
  disjoint for every registered entry, and that the pinned tap points
  still resolve to their segments.

## Verify
- `fvm flutter test` split/gap/body-map suites; full suite in Task 3.
