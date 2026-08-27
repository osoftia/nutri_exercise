# FRONTEND STANDARDS — The Project "Skill"

**Scope:** `web-portal` (Angular SPA) and any future frontend work in this repository.
**Enforcement:** CI + `npm run lint` + `npm run test -- --coverage`. Any PR that violates
these standards is rejected automatically by the quality gates.

---

## 1. Atomic Design Hierarchy (MANDATORY)

All UI code must live under `web-portal/src/app/components/` organised into the five
strict layers below. Components may **never** bypass their layer.

```
web-portal/src/app/
  components/
    atoms/        Single-purpose, non-composable primitives.
    molecules/    Combinations of atoms with a single responsibility.
    organisms/    Distinct sections composed of molecules and atoms.
    templates/    Page-level layout grids that place organisms (no business logic).
    pages/        Route targets; compose templates + organisms, own data stores.
  core/           Models, services, stores, mocks, utils, interceptors (no UI).
```

### Layer Rules

| Layer      | Allowed to import                               | Forbidden                                        |
| ---------- | ----------------------------------------------- | ------------------------------------------------ |
| `atoms`    | `@angular/*`, design tokens, `core` utils        | Other UI components (no `molecules`/`organisms`)  |
| `molecules`| `atoms`, `core`, `@angular/*`                    | `organisms`, `templates`, `pages`                |
| `organisms`| `atoms`, `molecules`, `core`, `@angular/*`       | `templates`, `pages`                             |
| `templates`| `organisms`, `atoms`, `molecules`, `core`        | `pages`                                          |
| `pages`    | everything above                                | anything below may **not** import a `page`       |

- **No `components/*/templates/*` bypassing organisms.** Composing raw atoms directly into a
  page without an intermediate organism is a violation.
- **Feature folders are forbidden.** Do not reintroduce `features/.../components/`. Everything
  is a component in the shared hierarchy.
- Every component folder is one self-contained directory: `name/name.ts`, `name/name.html`,
  `name/name.scss`, `name/name.spec.ts`.
- Naming: `kebab-case` folders, `PascalCase` classes.

---

## 2. Design System — "Editorial Tech"

All styling **must** derive from the design tokens in `web-portal/src/styles/design-tokens.scss`.
No raw hex values, no arbitrary font sizes, no inline shadows in component SCSS.

### Mandatory rules

- **No shadows.** `box-shadow` is banned in component styles (except the global token file).
  Use hard borders (`--border-thin`, `--border-strong`, `--border-accent`) and solid blocks.
- **Solid, high-contrast blocks.** Use `--color-ink`, `--color-block-*` surfaces. No soft
  neumorphic surfaces.
- **Hard edges.** `border-radius: var(--radius-none)` is the default for editorial blocks;
  `--radius-sm/md/lg` only for controls, never `0 0` mixed floating cards.
- **Extreme typography.** Key metrics are headlines, not gauges or charts:
  - Hero metric → `--font-size-display-lg` / `--font-size-display`, weight `--font-weight-display`,
    tracking `--letter-spacing-tight`.
  - Overline labels → `--font-size-caption`, `--letter-spacing-overline`, `text-transform: uppercase`.
- **Font.** Montserrat (`--font-family`). Never introduce a second display font.
- **Non-generic data viz.** No out-of-the-box bar/pie/line chart components. Prefer
  typographic scale, abstract pure-CSS/SVG geometric blocks, stark percentage readouts.

---

## 3. Quality Gates (CI-ENFORCED)

### 3.1 Test Coverage — minimum **80%** per metric

`vitest.config.ts` (v8 provider) enforces:
`lines >= 80`, `functions >= 80`, `branches >= 80`, `statements >= 80`.

- Every `*.ts` component, store, service, util ships a colocated `*.spec.ts`.
- Angular component specs must render the real template (`TestBed.createComponent`), not
  host-testing stubs.
- Red/green TDD: failing tests are written first, implementation follows, loop until green.

### 3.2 Cyclomatic Complexity — maximum **10**

`eslint.config.js` enforces `complexity: ['error', 10]`.

- Functions over 10 branches must be decomposed into smaller, single-purpose helpers.
- Prefer `computed()`/signals over imperative branching in components.

### 3.3 Lint & Build

- `npm run lint` must pass with zero errors.
- `npm run build` must pass with zero errors and respect SCSS budgets.

---

## 4. Workflow

1. Branch from `feature/*` with a descriptive name (`feature/atomic-quality-refactor`).
2. Red phase: write/adjust specs first. Green phase: implement. Loop.
3. Run `npm run lint` and `npm run test -- --coverage` until 100% clean and ≥ 80% covered.
4. Commit in conventional style (`feat(web):`, `style(web):`, `fix(web):`, `refactor(web):`).