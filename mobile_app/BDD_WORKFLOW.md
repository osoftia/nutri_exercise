# BDD Workflow — NutriExercise Mobile App

This document defines the Behavior-Driven Development (BDD) standard for the
NutriExercise mobile app. It applies to **all future milestones** (starting with
M5: Backend Integration) and retroactively documents milestones M1–M4.

---

## 1. Mandate

Behavior is agreed **before** code. Every milestone ships with Gherkin
feature files that describe the expected behavior in plain language, and the
implementation must satisfy those features exactly.

> **Architect writes the `.feature` files FIRST.**
> **Coder uses them as strict acceptance criteria BEFORE writing code.**

---

## 2. Roles

| Role | Responsibility |
|---|---|
| **Architect** | Writes the Gherkin `.feature` files as part of the milestone blueprint, before any implementation. |
| **Coder** | Treats the `.feature` files as the contract. Implements only the behavior described and verifies each Scenario against the running app. |

---

## 3. Workflow Order (Mandatory for every milestone)

1. **Plan** — Architect writes the technical blueprint for the milestone.
2. **Specify** — Architect creates one `.feature` file per behavior area under
   `mobile_app/test/features/`. All Scenarios must be concrete, testable, and
   free of implementation detail.
3. **Review** — Architect and Coder agree on the feature files. The Coder does
   not begin implementation until the Scenarios are stable and accepted.
4. **Implement** — Coder implements the milestone, using the Scenarios as the
   acceptance checklist. A feature is "done" only when every Scenario is
   satisfiable.
5. **Verify** — Coder confirms each Scenario manually (or with a BDD runner such
   as `cucumber`/`gherkin` tooling when adopted) and records the result.
6. **Document** — Coder records the execution summary in the milestone log
   (e.g. `m4_execution_changes.log`) and references the feature files used as
   acceptance criteria.

---

## 4. Gherkin Conventions

- Files live in `mobile_app/test/features/` and are named
  `<m<number>_<area>.feature>` (e.g. `m5_backend_integration.feature`).
- Use only the standard keywords: `Feature`, `Background`, `Scenario`,
  `Given`, `When`, `Then`, `And`, `But`.
- Every Feature has a `@tag` list: milestone number, area, and domain tags
  (e.g. `@milestone_5 @backend @api`).
- Each Scenario describes a single, independently verifiable behavior.
- **Given** — the starting state. **When** — the user/system action.
  **Then** — the observable outcome. `And`/`But` chain steps of the same type.
- Avoid implementation detail (widget names, class names) in Scenario steps;
  describe behavior in user-observable terms. Implementation notes belong in
  the milestone blueprint, not the `.feature` files.

---

## 5. Acceptance Definition

A milestone is accepted when:

- The Architect-approved `.feature` files exist under `mobile_app/test/features/`
  and were written **before** implementation began.
- Every Scenario has been verified against the running app (manual or automated).
- `flutter analyze` passes with no new warnings.
- The execution log records which features/scenarios were satisfied and any
  deviations.

---

## 6. Existing Feature Files (M1–M4, retroactive)

| File | Covers |
|---|---|
| `test/features/m1_environment_mock.feature` | Environment toggle between Mock, Local, and API flavors |
| `test/features/m2_anatomy_ui.feature` | Bidirectional interaction between body map and exercise cards |
| `test/features/m3_routine_wizard.feature` | 4-step form flow, validation, and generation loading state |
| `test/features/m4_offline_persistence.feature` | SQLite persistence of generated routines across restarts |

---

## 7. Example Feature File Template

```gherkin
@milestone_<N> @<area> @<domain>
Feature: <Feature title>

  As a <role>
  I want <capability>
  So that <business value>

  Background:
    Given <shared precondition>

  Scenario: <Short behavior description>
    Given <state>
    When <action>
    Then <observable outcome>
```