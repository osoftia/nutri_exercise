# M42 Backlog

- [x] Task 1: Fix SQLite Persistence for Workouts & Tamagotchi State - Ensure `LocalBodyDetailRepository` and `DatabaseHelper` properly persist completion state changes, weight fluctuations, and segment scaling factors so they survive app restarts.
- [ ] Task 2: Restrict Nutrition Management to Deletion Only - Remove the "Add food" action from the nutrition popup sheet. Food items can only be removed (reducing calorie surplus/stomach bloat), while additions remain strictly bound to preset suggestions or the RAG AI advisor pipeline.
- [ ] Task 3: Live Weight & Mass Reactivity - Bind the blueprint figure's segment scaling directly to the persisted caloric and muscle balance state, ensuring the visual avatar updates its proportions instantly upon toggling workouts or deleting food items.
- [ ] Task 4: Floating History Action Button - Implement a blueprint-styled floating action button (matching the technical aesthetic of the reference poster) positioned right next to the animated human diagram in the Routines tab, opening the historical progress view.
- [ ] Task 5: Testing & Verification - Write tests covering the persistence round-trips and the restricted nutrition deletion flow, run `flutter test`, and verify clean analyzer output.
