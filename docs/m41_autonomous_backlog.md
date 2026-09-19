# M41 Autonomous Backlog

- [x] Task 1: Close Anatomy Gaps - Modify `body_segment_geometry.dart` so that the neck, shoulders, upper arms, forearms, thighs, and calves connect fluidly at their joints (shoulders to chest, elbows to forearms, knees to thighs/calves) without detached floating gaps, preserving the clean blueprint vector look.
- [x] Task 2: Restore Tamagotchi Scaling Animation - Re-link the active `MuscleTamagotchiState` and calorie/muscle metrics so that segment thicknesses (muscle hypertrophy and stomach bloat) dynamically scale and animate on the blueprint figure just like before.
- [x] Task 3: Toggleable "Confirm Workout" Button - Make the workout confirmation button a toggle. Checking it records the workout and triggers avatar growth/animation; unchecking it deletes the workout completion record from SQLite/state and reverses the avatar animation instantly.
- [x] Task 4: Nutrition Action Button - Add a matching action button inside the "Nutrition" tab (mirroring the workout confirmation button) that opens the daily nutrition summary sheet and dynamically updates the abdomen/stomach segment.
- [x] Task 5: Verification & Tests - Write unit/widget tests for the toggle behavior and updated geometry, run `flutter test`, and ensure clean analyzer output.
