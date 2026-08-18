# MILESTONE WEB-6 — Technical Blueprint
## RLHF Analytics Summary (Angular Web Portal)

**Acceptance criteria:** `test/features/analytics_summary.feature`

---

## 0. DESIGN TOKEN REFERENCE (from `design-system/design-tokens.json`)

| Role | Token | Hex |
|---|---|---|
| Canvas BG | `surface.900` | `#0F172A` |
| Card surface | `surface.800` | `#1E293B` |
| Border / divider | `surface.700` | `#334155` |
| Primary | `primary.500` | `#3B82F6` |
| Text high / medium / low | `text.high/medium/low` | `#F8FAFC` / `#CBD5E1` / `#64748B` |
| Success | `success` | `#22C55E` |
| Danger | `danger` | `#EF4444` |
| Neutral muscle | `neutral.muscle` | `#94A3B8` |

Spacing `xs=4 … xxl=32`, radius `sm=8 / md=12 / lg=20`, motion `fast=150ms / normal=250ms`, curve `ease-out`. Typography **Inter**, 12/14/16/20/24/32.

---

## 1. CONTEXT & RECONCILIATION (verified against the repo)

- As in M4/M5, the RLHF surface is the dashboard's **AI-Generated Routines** panel
  (`DashboardHome`, `/admin-dashboard`). There is **no `/history` route**; "top of the /history
  route" maps to the **top of the AI-Generated Routines panel**.
- Metrics are derived **only** from the full `interactions` list in `DashboardStore`
  (`src/app/core/stores/dashboard.store.ts`) — **independent of filters** (filters are a
  browsing aid; analytics describe the whole dataset, consistent with the M5 export decision).
- Material v22 (Dark Anatomy theme) is active. `mat-card` is already used by `RoutineCard`.
- Conventions: signal-native (`signal`/`computed`/`input`), `@Service()` + `inject()`, pure
  logic in `core/utils/*`, colocated Vitest specs, SCSS budget 4 kB warn / 8 kB err.

---

## 2. PURE UTIL — `src/app/core/utils/analytics.util.ts`

Single source of truth for the metric math (unit-testable without the store).

```ts
export interface AnalyticsMetrics {
  totalRoutines: number;
  reviewedCount: number;
  positiveCount: number;
  negativeCount: number;
  positivePercent: number;
  negativePercent: number;
}

export function computeAnalytics(interactions: AiInteraction[]): AnalyticsMetrics {
  const totalRoutines = interactions.length;
  const reviewedCount = interactions.filter((i) => i.rating !== null).length;
  const positiveCount = interactions.filter((i) => i.rating === 'thumbs_up').length;
  const negativeCount = interactions.filter((i) => i.rating === 'thumbs_down').length;
  return {
    totalRoutines,
    reviewedCount,
    positiveCount,
    negativeCount,
    positivePercent: percentage(positiveCount, reviewedCount),
    negativePercent: percentage(negativeCount, reviewedCount),
  };
}

function percentage(part: number, total: number): number {
  return total === 0 ? 0 : Math.round((part / total) * 100);
}
```

### 2a. Math rules (map to the `.feature`)

- **Percentages are relative to `reviewedCount`**, never the full list — unrated routines must
  not dilute the ratio (feature: "relative to reviewed routines only").
- **Division by zero**: `reviewedCount === 0` → both percentages `0` (feature: "zero percentages
  when nothing has been reviewed").
- **Rounding**: `Math.round` to a whole number (feature: "rounded to whole numbers"). Because
  `positivePercent` and `negativePercent` are complementary fractions of the same denominator,
  the pair always sums to `100` when `reviewedCount > 0`.

---

## 3. STORE DERIVATION — `dashboard.store.ts`

One reactive `computed` signal; the page and component read it and it updates automatically as
`interactions` changes (loads, `submitFeedback` patches, ratings):

```ts
readonly analytics = computed(() => computeAnalytics(this.interactions()));
```

- Add `import { computeAnalytics } from '../utils/analytics.util';`.
- `reset()` needs **no change** (fully derived from `interactions`).
- No new service calls or state.

---

## 4. COMPONENT — `src/app/features/dashboard/components/analytics-summary/`

Presentational (dumb): receives the metrics as a single input, renders four tiles.

### 4a. Component (`analytics-summary.ts`)

```ts
@Component({
  selector: 'app-analytics-summary',
  imports: [MatCardModule],
  templateUrl: './analytics-summary.html',
  styleUrl: './analytics-summary.scss',
})
export class AnalyticsSummary {
  readonly analytics = input.required<AnalyticsMetrics>();
}
```

### 4b. Template (`analytics-summary.html`)

```html
<section class="analytics-summary" aria-label="RLHF analytics summary">
  <mat-card class="analytics-summary__tile">
    <span class="analytics-summary__label">Total Routines Generated</span>
    <span class="analytics-summary__value">{{ analytics().totalRoutines }}</span>
  </mat-card>

  <mat-card class="analytics-summary__tile">
    <span class="analytics-summary__label">Total Reviewed</span>
    <span class="analytics-summary__value">{{ analytics().reviewedCount }}</span>
  </mat-card>

  <mat-card class="analytics-summary__tile analytics-summary__tile--positive">
    <span class="analytics-summary__label">Positive</span>
    <span class="analytics-summary__value">{{ analytics().positivePercent }}%</span>
  </mat-card>

  <mat-card class="analytics-summary__tile analytics-summary__tile--negative">
    <span class="analytics-summary__label">Negative</span>
    <span class="analytics-summary__value">{{ analytics().negativePercent }}%</span>
  </mat-card>
</section>
```

### 4c. Layout + styling (`analytics-summary.scss`, Dark Anatomy tokens, keep < 4 kB)

```scss
.analytics-summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 12px;
}

.analytics-summary__tile {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 16px;
  background-color: #1e293b;   // surface.800
  border: 1px solid #334155;   // surface.700
  border-radius: 12px;
}

.analytics-summary__label {
  font-size: 12px;
  color: #64748b;              // text.low
}

.analytics-summary__value {
  font-size: 24px;
  font-weight: 700;
  color: #f8fafc;              // text.high
}

.analytics-summary__tile--positive .analytics-summary__value { color: #22c55e; }
.analytics-summary__tile--negative .analytics-summary__value { color: #ef4444; }
```

---

## 5. PLACEMENT — `dashboard-home.*`

Render the summary at the **top of the AI-Generated Routines panel**, above the header and
search filter, once data is loaded:

```html
<section class="dashboard-home__panel">
  @if (store.total() > 0) {
    <app-analytics-summary [analytics]="store.analytics()" />
  }

  <div class="dashboard-home__panel-header">
    <h2 class="dashboard-home__heading">AI-Generated Routines</h2>
    …existing header actions…
  </div>
  …existing search filter + state branches…
</section>
```

- Import `AnalyticsSummary` in `dashboard-home.ts` and add to `imports`.
- Guarded by `store.total() > 0` — when the panel shows the empty/error state, the summary is
  omitted (the empty-state copy already explains the situation).

---

## 6. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `src/app/core/utils/analytics.util.ts` | `computeAnalytics` + `AnalyticsMetrics` (§2) |
| **CREATE** | `src/app/core/utils/analytics.util.spec.ts` | Math rules tests |
| **MODIFY** | `src/app/core/stores/dashboard.store.ts` | `analytics` computed (§3) |
| **MODIFY** | `src/app/core/stores/dashboard.store.spec.ts` | Reactivity tests |
| **CREATE** | `src/app/features/dashboard/components/analytics-summary/*` | Tile component + spec |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.{ts,html,scss}` | Render summary at panel top |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.spec.ts` | Summary rendering tests |

---

## 7. IMPLEMENTATION ORDER (Recommended for @Coder)

```
PHASE 1 — Pure logic
  ├─ Step 1.1: analytics.util.ts + spec (empty → zeros; mix → counts; percent relative to
  │            reviewed; rounding; sum-to-100; division-by-zero)
  └─ Step 1.2: store `analytics` computed + spec (reacts to load and to submitFeedback rating)

PHASE 2 — Component
  ├─ Step 2.1: analytics-summary.* (4 mat-card tiles)
  └─ Step 2.2: analytics-summary.spec.ts (renders totals + percentages)

PHASE 3 — Page
  ├─ Step 3.1: place <app-analytics-summary> at panel top in dashboard-home
  └─ Step 3.2: dashboard-home.spec additions (rendered after load; omitted while empty)

PHASE 4 — Verification
  ├─ Step 4.1: npm run build
  ├─ Step 4.2: npm test   (all specs green)
  └─ Step 4.3: ng serve → rate interactions → tiles update live
```

---

## 8. TESTING CHECKLIST (maps to `analytics_summary.feature`)

| # | Scenario | Expected test |
|---|---|---|
| 1 | Total generated | `totalRoutines` = list length |
| 2 | Total reviewed | `reviewedCount` = interactions with `rating !== null` |
| 3 | Positive/negative % | Percentages derived from counts |
| 4 | Relative to reviewed only | Unrated items don't change percentages |
| 5 | Sum to 100 | `positivePercent + negativePercent === 100` when reviewed > 0 |
| 6 | Zero when unreviewed | Both percentages 0 with `reviewedCount === 0` |
| 7 | Live update | Rating an interaction bumps `reviewedCount` + percent |
| 8 | Whole numbers | `Math.round` applied (e.g., 1/3 → 33, 2/3 → 67) |

---

## 9. RISKS & NOTES

- **Division by zero** is the only tricky case — handled in `percentage` (`total === 0 → 0`).
- **Don't compute percentages inline in the template** — keep the math in the util so it's unit
  tested; the component stays a dumb renderer.
- **Analytics ignore filters** — always `computeAnalytics(this.interactions())`, never
  `visibleInteractions()`.
- **Budget**: the summary adds 4 `mat-card`s + a grid — negligible SCSS; keep component style
  under 4 kB.
- **No new dependencies**: pure TS math + existing Material.

---

_Generated by @Architect. Hand off to @Coder with this file + `test/features/analytics_summary.feature` as acceptance criteria._