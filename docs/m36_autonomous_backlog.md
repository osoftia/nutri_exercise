# M36 Autonomous Backlog
- [x] Task 1: Single Source of Truth for State - Audit `HomePage` and ensure it instantiates or watches a single global or inherited `MuscleTamagotchiState` instance, removing any dummy/mock states.
- [x] Task 2: Forced Split Limb Canvas Paths - In `InteractiveBodyMap`, explicitly separate the drawing commands for Upper Arms, Forearms, Thighs, and Calves with clear coordinate offsets so they are 100% visibly independent on screen.
- [ ] Task 3: Visual State Feedback - Ensure tapping Quick Add or Exercise buttons directly mutates this exact state instance and calls `notifyListeners()`, causing an immediate redraw with visible color changes or scale shifts.
