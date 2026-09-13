# M36 Task 2 — Forced Split Limb Canvas Paths

## Goal
`InteractiveBodyMap` must paint Upper Arms, Forearms, Thighs and Calves with
explicitly separate drawing commands plus coordinate offsets, so the four
segments are 100% visibly independent even at maximum growth scale.

## Findings
- M35 cut vector gaps (upper bottom y≈0.345 vs fore top y≈0.365; thigh
  bottom y≈0.785 vs calf top y≈0.815) and strokes split regions in their own
  color, but `_BodyMapPainter.paint` still draws every region in ONE shared
  loop — a single command stream, and heavy growth scaling can visually
  re-close the gaps.
- Hit-testing (`muscleAt`) uses un-offset screen paths; paint offsets must
  stay small so pinned taps keep resolving.

## Change
- `lib/ui/organisms/interactive_body_map.dart`:
  - New `splitLimbDrawOffsets` const: per-segment normalized offsets that
    push joint neighbours apart (`upper_arms` up, `forearms` down, `thighs`
    up, `calves` down).
  - `paint()` restructured: torso/non-split regions in one loop, then FOUR
    explicit segment passes (`upper_arms` / `forearms` / `thighs` /
    `calves`), each shifting its paths by its offset and stroking in its
    own region color.
  - New `_paintSplitSeparators`: short page-background joint strips
    (arm y≈0.355, leg y≈0.80, front+back boxes) painted last so the split
    survives any growth overshoot.
  - Joint y constants exported (`splitArmJointY`, `splitLegJointY`) for tests.
- New test `test/ui/m36_task2_split_render_test.dart`: offsets present with
  opposing signs, offset-shifted bounds stay disjoint with a wider gap than
  raw vectors, pinned taps still resolve, widget smoke-renders.

## Verify
- `fvm flutter analyze` touched files; `fvm flutter test` new test + full
  suite green.
