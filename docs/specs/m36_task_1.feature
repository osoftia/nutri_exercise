# M36 Task 1 — Calendar Date Offset Fix

## Goal
Selecting day X in the calendar/stats UI must query and display exactly day
X — no timezone or off-by-one shifts.

## Findings (audit)
- DB layer is exact: `getDailyEntry`/`deleteDailyEntry` use `date = ?`,
  `getAllDailyEntries` is `orderBy: date`; all `dateKey` helpers use local
  wall-clock fields; the history grid builds keys via
  `dateKey(DateTime(y, m, day))` and matches with `==` / `startsWith`. No
  `DateTime.parse` (UTC-midnight trap) anywhere.
- BUG 1 (weekday/label offset): `WeeklyStatsSheet` zips a STATIC
  Monday-first label list `['M','T','W','T','F','S','S']` over the rolling
  7-day window ending TODAY, so bars are mislabeled every day except
  Sunday — entries appear under the wrong weekday.
- BUG 2 (DST/timezone shift): `computeWeeklyStats` and
  `DatabaseHelper.currentStreak` step days with
  `subtract(Duration(days: 1))` (fixed 24 h), which shifts the wall date
  across DST transitions. Calendar arithmetic `DateTime(y, m, d - n)` is
  immune.
- Hardening: day→entry lookup is inlined in the dialog
  (`entries.where(...).firstOrNull`); centralize as
  `DailyEntryController.entryForDate` so grid, editor and tests share one
  exact-match path.

## Change
- `lib/core/utils/weekly_stats.dart`: calendar-arithmetic window + new
  `weekdayLabel(DateTime)` (Mon-first single letters).
- `lib/ui/organisms/weekly_stats_sheet.dart`: bar labels derived from each
  `stat.date` via `weekdayLabel` (drop static list).
- `lib/core/database/database_helper.dart`: `currentStreak` cursor steps by
  calendar day.
- `lib/core/state/daily_entry_controller.dart`: new `entryForDate(date)`
  exact lookup; `calendar_history_dialog._openEditor` uses it.

## Verify
- `fvm flutter analyze` touched files.
- New `test/utils/m36_task1_date_alignment_test.dart` (weekday labels for
  known dates, month-boundary window, entryForDate exactness incl.
  lookalike keys) + `test/features/m36_task1_calendar_date_widget_test.dart`
  (tap day X → editor shows exactly X; weekly labels match real weekdays).
- Full `fvm flutter test` green.
