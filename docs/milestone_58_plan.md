# Milestone 58 — Success Response Logging, Raw AI Text Viewer & Overwrite Confirmation

> **Branch:** `feature/m58-success-logging-diagnosis-confirmation`
> **Scope:** `mobile_app` (Flutter)
> **TDD loop:** failing tests → implementation → `fvm flutter analyze` + `fvm flutter test`

## Objective

Harden the clinical AI diagnosis workflow with forensic visibility for
_successful_ exchanges and a safety gate before a valid saved diagnosis is
replaced.

## Tasks

1. **Success forensic logging (SQLite).** Add `SuccessLogEntry`,
   `SuccessLogRepository`, a `LocalSuccessLogRepository`, a mock, and the
   `local_success_logs` table (schema v20) storing the raw request/response
   bodies, request URL and UTC timestamp. Record every parseable clinical
   diagnosis response from `AiDiagnosisRepository`.
2. **Raw "Respuestas exitosas" viewer.** Surface the persisted successes from
   the Profile **Pruebas** accordion, alongside the existing error viewer, with
   time, status, label, URL and expandable raw request/response bodies.
3. **Exact backend response mapping.** Bind the diagnosis parser directly to the
   backend `diagnosticReport` and `mealSuggestions` keys and remove all generic
   educational placeholder fallbacks (report title, menu name, meal name).
4. **Overwrite confirmation dialog.** Before regenerating when a valid local
   diagnosis already exists, prompt
   `¿Está seguro de que desea volver a generar el diagnóstico?` and only proceed
   on explicit confirmation.
5. **Testing & verification.** Cover persistence, migration, viewer, mapping and
   dialog behaviour. Run the full suite and the analyzer with zero regressions.

## Contract notes

- Table `local_success_logs` (v20): `timestamp`, `status_code`, `label`,
  `request_url`, `request_body`, `response_body`.
- Success capture is best-effort and must never discard a successfully parsed
  report.
- Response parsing source of truth: `diagnosticReport` (string or object) and
  `mealSuggestions` (list); legacy `title`/`summary`/`menus` keys remain readable
  but no placeholder copy is injected when fields are absent.
- The confirmation dialog keys are `ai_diagnosis_overwrite_dialog`,
  `ai_diagnosis_overwrite_confirm`, `ai_diagnosis_overwrite_cancel`.
