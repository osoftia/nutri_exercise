# M34 Task 2 — Split Limbs Painter Enforce

## Goal
`InteractiveBodyMap` must render Upper Arms, Forearms, Thighs and Calves
as distinct paths with distinct colors instead of single-block limbs.

## Findings
- `muscle_vectors.dart` already registers 4 split ids with distinct
  normalized paths (mirrored L/R, front/back) — covered by
  `muscle_vectors_split_test.dart` and reverse-order hit-testing.
- Gap 1: no single source of truth naming the split set; enforcement is
  implicit.
- Gap 2: `_BodyMapPainter` strokes every non-selected, non-active region
  with the same neutral gray, so two adjacent same-tier segments
  (upper arm + forearm, thigh + calf) visually merge into one block.

## Change
- `muscle_vectors.dart`: add `splitLimbRegionIds` const set and
  `isSplitLimbRegion(id)` helper.
- `_BodyMapPainter.paint`: split-limb regions that are neither selected
  nor active are stroked with their own resolved `_regionColor` (tier or
  override) instead of neutral gray, giving each segment its own crisp
  outline and color identity. Active → accent and selected → highlight
  passes are unchanged.
- New test `test/constants/split_limb_regions_test.dart` pins the split
  set and helper.

## Verify
- `dart analyze lib` (FVM 3.29 toolchain; system flutter is 3.24)
- `fvm flutter test` subset + full suite in Task 4
