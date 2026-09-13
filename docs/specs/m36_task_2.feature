# M36 Task 2 — Entry Deletion Control

## Goal
The daily entry editor must expose a prominent Delete control that removes
the entry from SQLite, updates dependent Tamagotchi/stats state, and
refreshes the calendar UI instantly.

## Findings (audit)
- Delete plumbing already exists end-to-end: `_EntryEditorSheet._delete` →
  `DailyEntryController.delete(date)` → `DELETE WHERE date = ?` + `loadAll`
  → `ListenableBuilder` re-renders the grid. Covered by
  `calendar_history_dialog_test` ("an entry can be deleted").
- GAP 1 (prominence): the control is a ghost-variant `CustomButton` labeled
  "Delete" — subtle, no icon, no danger affordance.
- GAP 2 (dependent state): nothing notifies the host after a delete/save.
  `HomePage` caches `_streak` (read from the same `daily_entries` table via
  `currentStreak`) once in `initState`, so deleting a streak day leaves the
  share card stale. Weekly stats read fresh on open (no change needed);
  the in-memory Tamagotchi avatar is not derived from history rows.

## Change
- `lib/ui/organisms/calendar_history_dialog.dart`:
  - Replace the ghost "Delete" with a prominent danger-outlined
    `OutlinedButton.icon` (trash icon + "Delete Record" label, same
    `history_delete_button` key).
  - Editor sheet pops with `true` on successful save/delete; `_openEditor`
    forwards that as `widget.onChanged`.
  - New optional `onChanged` on `showCalendarHistoryDialog` /
    `CalendarHistoryDialog`, fired after any successful mutation.
- `lib/ui/pages/home_page.dart`: extract `_loadStreak()`; history opener
  passes `onChanged: _loadStreak` so the share-card streak (Tamagotchi
  stats state) refreshes the moment a calendar entry is deleted/saved.

## Verify
- `fvm flutter analyze` touched files.
- Existing delete/edit calendar tests still green; new Task 3 tests pin:
  delete removes the row, clears the grid dot instantly, and fires
  `onChanged` (streak reload path).
