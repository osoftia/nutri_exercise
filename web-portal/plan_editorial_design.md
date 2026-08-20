# EDITORIAL TECH DESIGN SYSTEM — Pivot Blueprint

**Branch:** `feature/advanced-analytics-rag`
**Directive:** "Editorial Tech / Bold Typography"
**Scope:** `design-tokens.scss` refactor · `AnalyticsSummaryComponent` redesign · pure-SVG `BarChart` typographic redesign

---

## 0. DESIGN PRINCIPLES (The "Editorial Tech" System)

1. **Extreme Typography** — Key metrics are read as editorial headlines. Massive type, not
   gauges or standard bars. Font sizes scale aggressively for the single most important number.
2. **High Contrast & Solid Blocks** — No soft neumorphic shadows. Hard edges, solid
   high-contrast background blocks, and distinct **asymmetric** grid layouts.
3. **Non-Generic Data Visualization** — No traditional bar/pie/line charts. Data is expressed
   through typographic scale, abstract pure-CSS geometric shapes (dynamic SVG progress blocks),
   and stark percentage readouts.

---

## 1. CONTEXT & CURRENT STATE (verified against the repo)

- `src/styles/design-tokens.scss` currently ships **neumorphic shadow tokens**
  (`--shadow-neumorph-up/-down/-flat`) and a modest type scale capped at `--font-size-h1: 32px`.
- `src/styles.scss` references those shadows on `.mat-mdc-card`, buttons, and text-field wrappers.
- `AnalyticsSummaryComponent`
  (`src/app/features/dashboard/components/analytics-summary/*`) renders four soft `mat-card`
  tiles with 24px values — exactly the generic Material look we are removing.
- `BarChart` (`src/app/features/analytics/components/charts/bar-chart/*`) is a pure-SVG
  `rect`-per-datum bar chart — we replace it with a typographic + abstract geometric block system.
- Tests are Vitest colocated specs. Pre-existing failures exist on the branch in
  `vector-inspector` (5) and `mobile-usage` (1); these are **out of scope** for this pivot.

---

## 2. TOKEN REFACTOR — `src/styles/design-tokens.scss`

### Remove
- `--shadow-neumorph-up`, `--shadow-neumorph-down`, `--shadow-neumorph-flat`.

### Add — Solid layout borders (hard edges)
```
--border-thin: 1px solid var(--color-border);
--border-strong: 2px solid var(--color-text-high);
--border-accent: 2px solid var(--color-accent);
--radius-none: 0px;          /* editorial hard corners */
--radius-sm: 4px;            /* tightened from 8px */
--radius-md: 8px;
--radius-lg: 12px;           /* tightened from 20px */
```

### Add — Extreme typography scale (display-first)
```
--font-size-display: 72px;   /* hero metric */
--font-size-display-lg: 96px;/* overline/hero */
--font-size-hero: 48px;
--font-size-metric: 36px;
--font-size-h1: 40px;        /* was 32px */
--font-size-h2: 30px;        /* was 24px */
--font-size-h3: 22px;
--font-size-body: 16px;
--font-size-label: 13px;
--font-size-caption: 11px;
--font-weight-display: 800;
--font-weight-bold: 700;
--font-weight-medium: 600;
--letter-spacing-tight: -0.03em;   /* editorial headline tracking */
--letter-spacing-overline: 0.14em; /* uppercase label tracking */
```

### Add — Editorial surfaces & layout
```
--color-ink: #0b0f1a;        /* near-black solid block */
--color-block-primary: var(--color-primary);
--color-block-accent: var(--color-accent);
--color-block-success: var(--color-success);
--color-block-danger: var(--color-danger);
--grid-gutter: 20px;
```

> All consumers that referenced removed shadow tokens (below) are updated so no dangling token
> references remain. No new raw hex values in components — everything derives from tokens.

---

## 3. GLOBAL SHADOW CLEANUP — `src/styles.scss`

Replace the neumorphic `box-shadow` rules on `.mat-mdc-card`, raised buttons, hover/active states,
and text-field wrapper with hard-border + radius treatments:
- Cards: `border: var(--border-thin); border-radius: var(--radius-none); box-shadow: none;`
- Buttons hover/active: remove soft extrusion; use a solid accent border or color shift.
- Text-field wrapper: `border: var(--border-thin); border-radius: var(--radius-none); box-shadow: none;`

Also check `admin-sidebar.scss` and `search-filter.scss` which reference `--shadow-neumorph-flat`
/`--shadow-neumorph-down` — swap to the new border tokens so the build stays green.

---

## 4. REDESIGN — `AnalyticsSummaryComponent` (typographic headline readout)

Directory: `src/app/features/dashboard/components/analytics-summary/`

### Markup (`analytics-summary.html`)
- Drop the four equal `mat-card` tiles. Introduce an **asymmetric editorial grid**:
  - A dominant **hero tile** for `Total Routines Generated` rendered at
    `--font-size-display-lg` on a solid `--color-ink` block (the single most important number).
  - A two-column secondary band for `Total Reviewed`.
  - A stark **Positive / Negative split**: two solid high-contrast blocks side-by-side, each
    reading its `%` at `--font-size-hero`, with the count as a smaller overline.
- Keep semantic labels + `aria-label` on the `<section>`.

### Styling (`analytics-summary.scss`)
- Asymmetric grid: hero tile spans a full row / wider column; secondary band uses
  `grid-template-columns` that are intentionally **not** equal (e.g. `2fr 1fr` or offset rows).
- Hard edges (`border-radius: 0`), solid backgrounds (`--color-ink`, `--color-block-success`,
  `--color-block-danger`), uppercase overline labels with `--letter-spacing-overline`.
- Extreme type on the hero value; percentage readouts at hero size.

### Spec (`analytics-summary.spec.ts`)
- Existing assertions check for the four labels (`Total Routines Generated`, `Total Reviewed`,
  `Positive`, `Negative`) and the numeric values (`5`, `3`, `67%`, `33%`), plus reactive updates.
- **Constraint:** keep the four label strings and the numeric text present in the DOM so the
  existing spec remains valid while the visual system changes.
- Update the `querySelectorAll('mat-card')` assertion: if we no longer use `mat-card`, adjust the
  assertion to count the new editorial blocks (e.g. `.analytics-summary__block`) — do not leave a
  dangling `mat-card` count expectation.

---

## 5. REDESIGN — pure-SVG `BarChart` (typographic progress blocks)

Directory: `src/app/features/analytics/components/charts/bar-chart/`

Replacing the "one `rect` per datum" bar chart with an **abstract geometric progress-block
visualization** while keeping the pure-SVG, zero-dependency constraint:

### Component (`bar-chart.ts`)
- Keep `@Input() data: { label: string; value: number }[]`.
- Compute a **normalized scale** (value / max, 0..1) per datum.
- Render each datum as an **SVG progress block**: a track outline plus a solid block whose
  height/offset encodes the value, arranged in an asymmetric staggered row.
- Expose a `percentage` per datum so the template can stamp a stark numeric readout next to
  each block (typographic scale, not bar height, carries the signal).

### Markup (`bar-chart.html`)
- One `<g>` (group) per datum: `<rect>` track + `<rect>` solid block + `<text>` value readout.
- `role="img"` + `aria-label` retained (accessibility contract preserved).

### Styling (`bar-chart.scss`)
- Solid high-contrast blocks (`--color-block-primary`), hard corners, thin `--color-border`
  tracks, Montserrat `<text>` with `--letter-spacing-tight`.

### Spec (`bar-chart.spec.ts`)
- Existing tests assert: one `rect` per data point, empty-state renders zero, heights normalize
  relative to max, and `role="img"` + non-empty `aria-label`.
- Keep `role="img"`/`aria-label` intact.
- Adjust the "renders one `rect` per data point" assertion to reflect the new structure
  (a datum now produces a **track** + a **block** `rect`, i.e. `rect` count = data.length × 2, or
  target the block class selector). Keep an empty-state test and a normalization test using the
  block rect heights.

---

## 6. TESTING & VERIFICATION

- `npm test` — all **in-scope** suites green (`analytics-summary.spec.ts`, `bar-chart.spec.ts`,
  `design-tokens` consumers). Pre-existing failures in `vector-inspector` / `mobile-usage` are
  unrelated to this pivot and are documented as known branch baseline.
- `npm run build` — 0 errors, SCSS budgets respected (4 kB warn / 8 kB err per component).

---

## 7. COMMIT

- One focused commit on `feature/advanced-analytics-rag` in the repo's
  `style(web): ...` / `feat(web): ...` conventional-commit style, e.g.
  `style(web): pivot design system to editorial tech typography`.

---

_Generated by @Architect. Hand off to @Coder to execute the CSS refactor, update the data
visualization components, keep tests green, and commit to the current branch._
