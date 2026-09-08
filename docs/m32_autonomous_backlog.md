# M32 Autonomous Backlog

- [x] Task 1: "EXERCISE NOT" UI Test Button - Add a dedicated button labeled "EXERCISE NOT" in the main settings/nutrition section of the UI that immediately triggers a test exercise notification payload.
- [x] Task 2: 9 PM Daily Exercise Notification Schedule - Update `NotificationService` to schedule a daily repeating notification precisely at 9:00 PM (21:00) asking if the user completed their workout routines today.
- [x] Task 3: Interactive Response Handler & Calorie Calculation - Implement the background or foreground notification action handler for the 9 PM alert. If confirmed (Yes), calculate the total calories burned from today's completed routines, apply the workout reduction/slimming math to `MuscleTamagotchiState`, and update the SQLite daily log.
- [x] Task 4: Verification & Tests - Write unit/widget tests for the 9 PM scheduling logic and the exercise response calculator. Run `flutter analyze` and `flutter test`.