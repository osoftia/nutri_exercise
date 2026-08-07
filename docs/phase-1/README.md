# NutriExercise — SDD Spec Suite (Multi-Agent: Gemma + Qwen)

> **Status:** COMPLETE — Phases 1–4 approved 2026-08-07
> **Orchestrator:** Multi-Agent SDD (Gemma = Design, Qwen = Dev/QA)

## Deliverables

| # | Spec | Author | Path |
| --- | --- | --- | --- |
| 1 | GitHub Management (repo, GitFlow, CI/CD, PR templates) | [Qwen] | `docs/phase-1/01-github-management.md` |
| 2 | SDD Contracts (API, offline-sync, DB schemas) | [Qwen] | `docs/phase-1/02-sdd-contracts.md` |
| 3 | UI & Atomic Design (SPG body map, design tokens, atomic hierarchy) | [Gemma] | `docs/phase-1/03-atomic-design-ui.md` |

## Cross-Spec Consistency

- Body map vector contract (`02` §3.3, `03` §3.2) uses the same `id`/`svgPathId`/color tokens.
- Sync strategy (`02` §4) drives the offline organisms (`03` §4.3: `SyncStatusBanner`, `AIAssistantPanel`).
- GitFlow/PR gates (`01`) enforce spec-merge-before-code across all phases.
- Branch naming: features follow `feature/NE-{n}-{name}` for all later phases.

## Roadmap

- [x] **PHASE 1** GitHub setup, SDD contracts, Atomic Design specs → *approved 2026-08-07*
- [x] **PHASE 2** C# backend core + xUnit tests → `docs/phase-2/`
- [x] **PHASE 3** Angular web app + Jasmine/Karma tests → `docs/phase-3/`
- [x] **PHASE 4** Flutter mobile app + offline logic + widget tests → `docs/phase-4/`

## Approval Gate

**Approved 2026-08-07:**
- Phase 1: Monorepo · PostgreSQL (Npgsql) · LWW + conflict UI · Body map FRONT/BACK toggle.
- Phase 2: NodaTime timestamps · Testcontainers Postgres for sync tests.
- Phase 3: NgRx `signalStore` · Explore prefetch.
- Phase 4: drift SQLite · Golden tests committed to CI.

Non-blocking open items tracked per spec §"Open Decisions" (auth key strategy, theme, vector asset source, offline FAQ scope).
