# Milestone 50 — AI Clinical Nutrition Report & Local Menu Persistence

## Backlog

- [x] **Task 1: Local SQLite schema update.** Extend the current database schema (v13 → v14; earlier v11 → v12 wording is superseded by migrations already present) with `ai_diagnoses` and `ai_suggested_menus`. Store structured report/menu JSON, timestamps, and condition identifiers; add local repository operations for saving and reading the newest report and its associated menus.
- [x] **Task 2: AI diagnosis repository and API client.** Build a typed diagnosis request/response model and `AiDiagnosisRepository`. Serialize the active conditions with severity and saved food preferences, POST to the backend clinical-diagnosis endpoint, validate malformed responses, and keep prior local reports available if the backend is unavailable.
- [x] **Task 3: Profile UI integration.** Add an editable food preference/taste field and an “Obtener diagnóstico” action alongside condition controls. Show loading and success/error feedback, and present the report and menus in a readable modal sheet. Include clear educational/non-clinical advice wording.
- [x] **Task 4: Offline data binding and view.** Load saved reports and suggested menus from SQLite and show the most recent result in Profile, with no network dependency for viewing previously generated content.
- [ ] **Task 5: Testing and verification.** Add migration/persistence, request serialization/response parsing/offline fallback, and button-flow widget tests. Run `flutter test` and `flutter analyze`.

## Contract notes

- Request endpoint: `POST /api/clinical/diagnosis` (relative to the configured API base URL).
- Request body: `{ "conditions": [{ "id": "diabetes", "severity": "moderate" }], "foodPreferences": "...", "language": "en|es" }`.
- Response: structured report (`title`, `summary`, `considerations`, `menus`); each menu has a name, day/date, and meals. The parser accepts the documented shape and rejects malformed required fields before persistence.
- The existing repository is schema v13, so the additive diagnosis/menu migration is v14 and retains compatibility with all prior migrations.
- This educational nutrition feature must not present AI output as a confirmed medical diagnosis or substitute for professional care.

## Execution log

Implementation and verification results are recorded after the sprint.
