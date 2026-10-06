# Milestone 51 — Friendly Error Alerts & Local Forensics Log

## Backlog

- [x] **Task 1: SQLite schema update.** Add `local_error_logs` with an auto-increment ID, precise UTC timestamp, string error code, technical message, and stack trace. The repository is currently schema v14, so the additive migration is v14 → v15 (the requested v12 → v13 wording predates existing migrations).
- [ ] **Task 2: Error logging repository and global reporter.** Implement `ErrorLogRepository`, classify network/timeout/HTTP/parse failures, persist the original technical exception and stack, then issue a short, non-blocking Spanish floating alert. Instrument app HTTP boundaries without changing their existing fallback behavior.
- [ ] **Task 3: Profile Pruebas error viewer.** Add an “Errores registrados” action in the Profile Testing accordion. Display newest-first local records with local date/time, exact error code, technical message, and expandable stack trace.
- [ ] **Task 4: Testing and verification.** Cover SQLite storage, error classification, floating alerts, and the error viewer. Run the full Flutter test suite and analyzer.

## Error presentation contract

- Network: “En este momento no hay conexión, intente más tarde.”
- Timeout: “La solicitud tardó demasiado. Inténtelo de nuevo más tarde.”
- Server failures: “El servicio no está disponible ahora. Inténtelo más tarde.”
- Other failures: “Ha ocurrido un error. Inténtelo de nuevo.”
- Technical messages and stack traces remain local in SQLite; they are not included in the user-facing banner.
- Error codes are stored as text to support numeric HTTP statuses (`404`, `500`) and symbolic categories (`network`, `timeout`, `parse`).

## Execution log

Verification results and logical commit IDs are added after completion.
