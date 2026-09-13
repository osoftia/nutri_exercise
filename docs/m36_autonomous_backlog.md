# M36 Autonomous Backlog
- [x] Task 1: Calendar Date Offset Fix - Audit the date parsing and indexing logic in the calendar view / `DailyLogRepository`. Ensure selecting day `X` queries and displays exactly day `X` without timezone or off-by-one index shifts.
- [ ] Task 2: Entry Deletion Control - Add a prominent "Delete Record" (or trash icon) button to the daily entry details view/modal in the calendar. When tapped, it must delete the entry from SQLite, update the Tamagotchi/stats state, and instantly refresh the calendar UI.
- [ ] Task 3: Verification & Tests - Write unit/widget tests verifying correct date matching and successful deletion. Run `flutter analyze` and `flutter test`.
