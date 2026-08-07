# PHASE 1 — GitHub Management (SDD Lifecycle)

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Scope:** Repository structure, branching strategy (GitFlow), branch naming conventions, CI/CD pipeline concepts, and PR templates that drive the Spec-Driven Development (SDD) lifecycle.

---

## 1. Objective

Define the version-control contract that governs how the **NutriExercise** platform evolves. The strategy is **spec-first**: every feature is born as an SDD markdown spec, merged into `main`/`develop` *before* any implementation code is written. Git history and PR reviews become the enforcement layer of the SDD methodology.

---

## 2. Repository Structure (Monorepo)

A single GitHub monorepo keeps specs, backend, frontends, and mobile in one discoverable place while preserving strict module boundaries.

```text
nutri_exercise/
├── docs/                              # SDD lifecycle (source of truth)
│   ├── sdd/
│   │   ├── 01-vision.md
│   │   ├── 02-glossary.md
│   │   └── contracts/                 # API + DB contracts (OpenAPI / MD)
│   ├── phase-1/                       # PHASE 1 specs
│   ├── phase-2/                       # PHASE 2 specs (C# backend)
│   ├── phase-3/                       # PHASE 3 specs (Angular web)
│   └── phase-4/                       # PHASE 4 specs (Flutter mobile)
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── feature_spec.md            # SDD Feature/Spec issue
│   │   └── bug_report.md
│   ├── PULL_REQUEST_TEMPLATE/
│   │   ├── spec_pr.md                 # PR for approving a SPEC
│   │   └── code_pr.md                 # PR for approving CODE
│   └── workflows/                     # GitHub Actions CI/CD
│       ├── ci-backend.yml
│       ├── ci-web.yml
│       ├── ci-mobile.yml
│       └── docs-lint.yml
├── backend/                           # C# .NET solution
│   ├── src/
│   │   ├── NutriExercise.Api/         # RESTful API host
│   │   ├── NutriExercise.Core/        # Domain models + business logic
│   │   ├── NutriExercise.Application/ # Use cases / services
│   │   └── NutriExercise.Infrastructure/ # EF Core, SQL DB, repositories
│   └── tests/
│       ├── NutriExercise.Core.Tests/  # xUnit unit tests
│       └── NutriExercise.Api.Tests/   # xUnit integration/contract tests
├── web/                               # Angular application
│   ├── src/app/
│   │   ├── atoms/                     # Atomic Design
│   │   ├── molecules/
│   │   ├── organisms/
│   │   ├── templates/
│   │   └── pages/
│   └── projects/nutri-design-system/  # shared component library
├── mobile/                            # Flutter application
│   ├── lib/
│   │   ├── atoms/
│   │   ├── molecules/
│   │   ├── organisms/
│   │   ├── templates/
│   │   └── pages/
│   └── test/                          # widget + unit tests
├── .editorconfig
├── .gitignore
├── README.md
└── AGENTS.md                          # dev-agent instructions & commands
```

### 2.1 Ownership Rules (CODEOWNERS)

| Path               | Owners       |
| ------------------ | ------------ |
| `docs/**`          | `@design-lead` `@dev-lead` |
| `backend/**`       | `@dev-lead` (Qwen) |
| `web/**`           | `@design-lead` (Gemma) + `@dev-lead` |
| `mobile/**`        | `@design-lead` (Gemma) + `@dev-lead` |
| `.github/workflows/**` | `@dev-lead` (Qwen) |

---

## 3. Branching Strategy — GitFlow

| Branch                | Purpose                                                      | Lifetime   | Protected |
| --------------------- | ------------------------------------------------------------ | ---------- | --------- |
| `main`                | Production-ready; only spec-approved releases.               | Permanent  | Yes       |
| `develop`             | Integration branch; latest approved specs + code.            | Permanent  | Yes       |
| `feature/<id>-<name>` | New feature: spec draft → implementation.                    | Short-lived| No        |
| `docs/<id>-<name>`    | Documentation/spec-only changes.                             | Short-lived| No        |
| `release/<version>`   | Release hardening + version bumps.                           | Short-lived| Yes       |
| `hotfix/<id>-<name>`  | Emergency fixes from `main`.                                 | Short-lived| Yes       |

### 3.1 GitFlow Workflow

```text
main  o------------------------------o (release x.y)
       \                            / (merge --no-ff)
develop o------o------------------o--o
       /      /                  /
      /      /  release/v1.0.0   /
     /      /      /            /
feature/NE-12-workout-gen  ---'
       |
       +--- spec approved first, then code
```

1. `feature/NE-12-workout-gen` branches from `develop`.
2. Agent writes/updates the SDD spec in `docs/`.
3. **Spec PR** opened against `develop` → reviewers approve *design/contract*.
4. Implementation added on the same branch.
5. **Code PR** opened → CI gates pass → merged with `--no-ff` into `develop`.
6. Releasing: `release/vX.Y.Z` → `main` + tag `vX.Y.Z`.

---

## 4. Branch Naming Conventions

```text
feature/{issue-id}-{kebab-case-name}    e.g. feature/NE-12-workout-generator
docs/{issue-id}-{kebab-case-name}      e.g. docs/NE-03-sdd-contracts
release/{semver}                       e.g. release/v1.0.0
hotfix/{issue-id}-{kebab-case-name}    e.g. hotfix/NE-27-sync-crash
```

- Issue IDs: `NE-<number>` (from GitHub issues / project board).
- Names are `kebab-case`, short, action-oriented.
- Never branch directly from `main` except for `hotfix/*`.

---

## 5. Commit Convention (Conventional Commits)

| Type      | Usage                                            |
| --------- | ------------------------------------------------ |
| `spec:`   | Adds/updates an SDD markdown specification       |
| `feat:`   | New feature implementation (contract exists)     |
| `fix:`    | Bug fix                                          |
| `test:`   | Adding/updating unit or widget tests             |
| `docs:`   | Non-spec documentation (README, AGENTS)          |
| `refactor:`| Behavior-preserving change                       |
| `ci:`     | CI/CD pipeline changes                           |
| `chore:`  | Tooling, deps, config                            |

Examples:

```text
spec(contracts): define workout generation API contract
feat(backend): implement POST /api/v1/workouts/generate
test(backend): cover generator happy path + validation
```

**SDD Rule:** a `feat:` commit MUST reference a previously merged `spec:` commit for the same feature.

---

## 6. PR Templates

### 6.1 Spec PR (`spec_pr.md`)

```markdown
## SDD Spec Proposal
**Feature / Issue:** NE-12 — Daily Workout Generation

### Specification Checklist
- [ ] Vision & user story defined
- [ ] API contract defined (endpoints, request/response schemas)
- [ ] Database schema updated
- [ ] Offline-sync strategy addressed
- [ ] Atomic Design impact mapped (Atoms/Molecules/Organisms)
- [ ] Acceptance criteria defined
- [ ] Test strategy defined (backend/web/mobile)

### Reviewers
- [ ] Gemma (Design/UX) — UI & atomic structure reviewed
- [ ] Qwen (Dev/QA) — contract & schema reviewed

### Notes
<!-- Trade-offs, open questions, risk -->
```

### 6.2 Code PR (`code_pr.md`)

```markdown
## Implementation
**Issue:** NE-12 | **Spec:** docs/sdd/contracts/workout-generation.md

### Changes
- <!-- list of changes -->

### Spec Conformance
- [ ] Implements approved contract (no breaking deviations)
- [ ] Unit tests added/updated (xUnit / Jasmine / Flutter test)
- [ ] `dotnet test` / `ng test` / `flutter test` pass

### Checklist
- [ ] SOLID principles followed
- [ ] No secrets committed
- [ ] Follows branch naming + conventional commits
- [ ] Self-reviewed

### Screenshots / Evidence (UI changes only)
<!-- attach -->
```

---

## 7. CI/CD Pipeline Concepts (GitHub Actions)

### 7.1 Pipeline Stages

| Stage | Trigger               | Workflow            |
| ----- | --------------------- | ------------------- |
| Spec Lint | PR touching `docs/**` | `docs-lint.yml` — markdown lint, links, naming convention |
| Backend CI | PR touching `backend/**` | `ci-backend.yml` — `dotnet restore`, `dotnet build`, `dotnet test`, `dotnet format --verify-no-changes` |
| Web CI | PR touching `web/**` | `ci-web.yml` — `npm ci`, `ng lint`, `ng build`, `ng test` (Jasmine/Karma headless) |
| Mobile CI | PR touching `mobile/**` | `ci-mobile.yml` — `flutter analyze`, `flutter test`, `flutter build apk --debug` |
| CD (Backend) | push to `main` | deploy API to staging → production environment (Azure/AWS placeholder) |

### 7.2 Branch Protection Rules (GitHub)

Applied to `main` and `develop`:

- Require a pull request before merging (≥1 reviewer; CODEOWNERS enforced).
- Require status checks: `ci-backend`, `ci-web`, `ci-mobile`, `docs-lint` (as applicable).
- Require conversation resolution.
- **SDD gate:** a PR with source-file changes (backend/web/mobile) must include a link to a merged `spec:` commit — verified by a status check script.
- Do not allow bypassing the above settings.
- `--no-ff` merges only; linear history via `rebase` disabled for protected branches.

### 7.3 Secret Management

- Secrets via GitHub Environments (e.g., `PROD_DB_CONNECTION_STRING`, `MAIL_API_KEY`).
- `.env` files are git-ignored globally (`.gitignore`); no secrets in specs or code.

---

## 8. SDD Lifecycle Map (Git ↔ Process)

```text
[Spec Issue] -> [feature branch] -> [Spec PR merged] -> [Code PR merged] -> [Release]
     |                                    |                   |                  |
 docs/*.md (SPEC)                      contract frozen     impl conformance   version tag
```

Acceptance of a phase = merge of its spec docs into `develop` + explicit user approval.

---

## 9. Open Decisions

1. Repo layout: monorepo approved? (alternative: polyrepo `nutri-backend`, `nutri-web`, `nutri-mobile`)
2. Deploy target placeholder (Azure App Service / AWS ECS / Docker).
3. Story tracking: GitHub Issues + Projects, or external Jira sync.
