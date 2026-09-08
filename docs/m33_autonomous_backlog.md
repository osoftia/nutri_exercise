# M33 Autonomous Backlog

- [x] Task 1: Stomach Bloat Visual Scale - Update `InteractiveBodyMap` (and its custom painter) so that core fullness / stomach bloat dynamically scales and expands/contracts the central torso/stomach vector in real-time.
- [x] Task 2: Exercise Slimming & Eating Bloat UI Trigger - Ensure any food log (bloat) or completed exercise (slimming) immediately calls `notifyListeners()`, triggering smooth animations on the home page avatar.
- [x] Task 3: Muscle Color Overrides Rendering Fix - Fix the paint logic in `InteractiveBodyMap` to strictly enforce `regionColorOverrides` (red for primary, orange for secondary) over default tier colors whenever an exercise is selected or logged.
- [x] Task 4: Split Anatomy Vector Rendering - Inspect and rewrite the drawing paths in `InteractiveBodyMap` to explicitly render Upper Arms, Forearms, Thighs, and Calves as separate, distinct interactive/colored regions rather than unified limb blocks.
