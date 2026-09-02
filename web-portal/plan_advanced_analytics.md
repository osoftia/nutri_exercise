# ADVANCED ANALYTICS & RAG INSPECTOR — Technical Blueprint
## Mobile Telemetry · AI Performance Analyzer · pgvector RAG Visualizer (Angular Web Portal)

**Acceptance criteria:** `test/features/advanced_analytics_rag.feature`

---

## 0. DESIGN TOKEN REFERENCE (from `design-system/design-tokens.json` + `styles/design-tokens.scss`)

| Role | Token | Hex |
|---|---|---|
| Canvas BG / Card surface / Border | `--color-bg` / `--color-surface` / `--color-border` | `#0F172A` / `#1E293B` / `#334155` |
| Text high / medium / low | `--color-text-high/medium/low` | `#F8FAFC` / `#CBD5E1` / `#64748B` |
| Primary / Accent | `--color-primary` / `--color-accent` | `#3B82F6` / `#F97316` |
| Success / Warning / Danger | `--color-success` / `--color-warning` / `--color-danger` | `#22C55E` / `#EAB308` / `#EF4444` |
| Neumorphic shadows | `--shadow-neumorph-up/-down/-flat` | soft 3D extrusion tokens |

Typography **Montserrat**; radius `--radius-sm/md/lg` (8/12/20); motion `--motion-fast/normal`; `--ease-out`.

---

## 1. CONTEXT & RECONCILIATION (verified against the repo)

- **Backend**: only `RoutineController` (functional) and `AiProxyController` (placeholder) exist.
  There are **no** telemetry, AI-metrics, or database-inspector endpoints. The frontend therefore
  follows the established **mock-first** pattern (`environment.useMocks`), defining the contracts
  below so a future backend milestone can wire real HTTP without UI changes.
- **Frontend**: Material v22 + Dark Anatomy/Eco-Neumorphism theme active; `DashboardStore` already
  exposes `analytics` (`computeAnalytics` → positive/negative counts + percentages) and
  `visibleInteractions`. Signal-native (`signal`/`computed`/`input`/`output`), `@Service()` +
  `inject()`, colocated Vitest specs, SCSS budget 4 kB warn / 8 kB err.
- **Routing**: `/history` is the RLHF dashboard. This milestone adds a **new lazy route
  `/analytics`** hosting the three panels; the sidebar gains an "Analytics" nav item.

### 1a. Backend contract proposal (mock-first; NOT implemented yet)

| Method | Path (proposed) | Purpose |
|---|---|---|
| GET | `/api/telemetry/snapshot` | Mobile usage snapshot (sessions, sync status, events) |
| GET | `/api/analytics/ai-performance` | Llama3 latency + token throughput samples |
| GET | `/api/db/tables` | List of tables + row counts + embedding columns |
| GET | `/api/db/tables/{name}/rows` | Rows of a table (vector columns previewed) |
| POST | `/api/db/vector/search` | Semantic search over pgvector embeddings → top-k matches |

---

## 2. DOMAIN MODEL — `src/app/core/models/analytics.model.ts`

```ts
export type TelemetryEventType = 'session_started' | 'session_completed' | 'sync_completed' | 'sync_failed';

export interface TelemetryEvent {
  id: string;
  type: TelemetryEventType;
  occurredAt: string;           // ISO-8601
}

export interface TelemetrySnapshot {
  activeWorkoutSessions: number;
  pendingSyncItems: number;
  lastSyncAt: string | null;    // ISO-8601 or null if never synced
  events: TelemetryEvent[];     // newest first
}

export interface AiMetricSample {
  id: string;
  generatedAt: string;          // ISO-8601
  latencyMs: number;
  tokensPerSecond: number;
}

export interface AiPerformance {
  averageLatencyMs: number;
  averageTokensPerSecond: number;
  totalGenerations: number;
  samples: AiMetricSample[];    // for the bar chart
}

export interface VectorColumnInfo {
  name: string;
  dimensions: number;
}

export interface DbTable {
  name: string;
  rowCount: number;
  columns: string[];
  vectorColumns: VectorColumnInfo[];
}

export interface DbTableRow {
  [column: string]: unknown;
}

export interface VectorMatch {
  id: string;
  score: number;                // similarity 0..1 (cosine)
  preview: string;              // truncated table-row preview
}
```

- Flat interfaces, no index-signature violations (`noPropertyAccessFromIndexSignature`).

---

## 3. MOCK DATA — `src/app/core/mocks/mock-analytics.data.ts`

Fixtures mirroring §1a/§2:

- `mockTelemetrySnapshot`: 3 active sessions, 2 pending sync items, last sync timestamp, 5–6
  events (mixed types, distinct timestamps for newest-first assertions).
- `mockAiPerformance`: avg latency ~1 842 ms, avg throughput ~38 tok/s, 8 latency samples
  (distinct values → bar heights differ).
- `mockDbTables`: `routines`, `diets`, `users`, `interactions`, and **`routine_embeddings`**
  (a `vector(1536)` column → `dimensions: 1536`).
- `mockRowsByTable`: rows per table; the embeddings table rows carry a `embedding` array of 1536
  floats plus a human-readable `preview`.
- `mockSemanticSearch(query)`: returns 3 matches sorted by `score` desc; `preview` echoes a
  snippet of the query.

---

## 4. SERVICES — mock-first HTTP layer

All three follow the `Routine`/`Diet`/`InteractionService` pattern (`environment.useMocks`).

| File | Method | Mock path | HTTP path |
|---|---|---|---|
| `core/services/telemetry.service.ts` | `getSnapshot()` | `of(mockTelemetrySnapshot).pipe(delay(500))` | `GET /telemetry/snapshot` |
| `core/services/ai-metrics.service.ts` | `getPerformance()` | `of(mockAiPerformance).pipe(delay(500))` | `GET /analytics/ai-performance` |
| `core/services/database.service.ts` | `getTables()` | `of(mockDbTables).pipe(delay(400))` | `GET /db/tables` |
| `core/services/database.service.ts` | `getTableRows(name)` | `of(mockRowsByTable[name])...` | `GET /db/tables/{name}/rows` |
| `core/services/database.service.ts` | `searchVectors(query, k)` | `of(mockSemanticSearch(query))...` | `POST /db/vector/search` |

- `ApiConstants` style: build URLs from `environment.apiUrl`; keep paths centralized.
- Delay helpers keep the loading states observable in dev.

---

## 5. STORES — Angular Signals

### 5a. `AnalyticsStore` — `src/app/core/stores/analytics.store.ts`

Injects `DashboardStore` (for RLHF feedback distribution) + `TelemetryService` + `AiMetricsService`.

```ts
readonly telemetry = signal<TelemetrySnapshot | null>(null);
readonly aiPerformance = signal<AiPerformance | null>(null);
readonly loading = signal(false);
readonly error = signal<string | null>(null);

// RLHF feedback distribution (derived from the shared RLHF store)
readonly feedbackDistribution = computed(() => {
  const a = this.dashboard.analytics();
  return { positive: a.positiveCount, negative: a.negativeCount, reviewed: a.reviewedCount };
});

load(): void;      // fetch telemetry + aiPerformance in parallel (forkJoin)
retry(): void;     // re-run load()
reset(): void;
```

### 5b. `VectorInspectorStore` — `src/app/core/stores/vector-inspector.store.ts`

Injects `DatabaseService`.

```ts
readonly tables = signal<DbTable[]>([]);
readonly selectedTable = signal<DbTable | null>(null);
readonly rows = signal<DbTableRow[]>([]);
readonly vectorColumns = computed(() => this.selectedTable()?.vectorColumns ?? []);
readonly searchResults = signal<VectorMatch[]>([]);
readonly loading = signal(false);
readonly error = signal<string | null>(null);

loadTables(): void;
selectTable(name: string): void;      // sets selectedTable + fetches rows
search(query: string, k = 5): void;
retry(): void;
```

- Every action guards against concurrent `loading()`; `error` drives the retry state.
- `reset()` clears all signals.

---

## 6. COMPONENTS — `src/app/features/analytics/`

### 6a. Route page — `pages/analytics/analytics.page.{ts,html,scss,spec.ts}`

- Injects `AnalyticsStore` + `VectorInspectorStore`; calls `load()`/`loadTables()` in `ngOnInit`.
- Layout (top → bottom, `gap: 32px` per the spacing system):
  1. `<app-mobile-usage [snapshot]="analytics.telemetry()" [loading]="analytics.loading()" />`
  2. `<app-ai-performance [performance]="analytics.aiPerformance()" [distribution]="analytics.feedbackDistribution()" />`
  3. `<app-vector-inspector [store]="vectorStore" />` *(or `@Input()` projection — see 6d)*
- Loading/error handling per section (each section renders its own spinner/retry).

### 6b. `MobileUsage` — `components/mobile-usage/`

- `@Input()` `snapshot: TelemetrySnapshot | null`, `loading: boolean`; emits `(retry)`.
- Stat tiles (neumorphic `mat-card`): **Active Workout Sessions**,
  **Pending Offline Sync Items**, **Last Sync** (formatted `Intl.DateTimeFormat`).
- `mat-table` of `events` (Type + timestamp), newest first, `@empty` state text.

### 6c. `AiPerformance` — `components/ai-performance/`

- `@Input()` `performance: AiPerformance | null`, `distribution: { positive, negative, reviewed }`.
- Stat tiles: **Avg Generation Latency (ms)**, **Token Throughput (tok/s)**, **Total Generations**.
- `<app-bar-chart [data]="latencySamples" />` — one bar per `AiMetricSample`.
- Feedback split: a horizontal two-segment bar (positive green / negative red) + counts.
  Percentages reuse `computeAnalytics` semantics (relative to reviewed, zero-guard).

### 6d. `VectorInspector` — `components/vector-inspector/`

- Injects `VectorInspectorStore` (this section owns its data flow).
- **Table selector** (`mat-select`) listing `tables` with row counts.
- **Rows panel**: `mat-table` of the selected table's rows; vector columns rendered as a
  truncated preview (`Float64Array` first 3 values + `… (1536 dims)`).
- **Embedding metadata**: badge/chip per `vectorColumn` showing `dimensions`.
- **Semantic search**: `mat-form-field` query + "Search" `mat-button` → `store.search(query)`;
  results in a `mat-table` (id, similarity %, preview), sorted by score desc.
- Error state + `Retry` re-runs the last action.

### 6e. `BarChart` — `components/charts/bar-chart/` (pure SVG, zero dependencies)

```html
<svg class="bar-chart" [attr.viewBox]="viewBox()" role="img" aria-label="Latency per generation">
  @for (bar of bars(); track bar.label) {
    <rect [attr.x]="bar.x" [attr.y]="bar.y" [attr.width]="bar.width"
          [attr.height]="bar.height" rx="4" class="bar-chart__bar" />
  }
</svg>
```

- `@Input()` `data: { label: string; value: number }[]`; `computed` maps to normalized `bars`
  (max-value scaling), fixed `viewBox="0 0 320 160"`.
- Colors: `--color-primary` bars; axis labels as `<text>` (Montserrat, `--color-text-low`).
- Hand-rolled on purpose: **no charting library** (Eco-Neumorphism "pure CSS/sober" principle).

---

## 7. ROUTING & NAVIGATION

### 7a. `src/app/app.routes.ts` — add lazy route

```ts
export const routes: Routes = [
  { path: 'history', component: DashboardHome },
  { path: 'analytics', loadComponent: () =>
      import('./features/analytics/pages/analytics/analytics.page').then((m) => m.AnalyticsPage) },
  { path: 'admin-dashboard', redirectTo: '/history', pathMatch: 'full' },
  { path: '', redirectTo: '/history', pathMatch: 'full' },
];
```

### 7b. Sidebar — `admin-sidebar.ts` / `.html`

- Add nav item `{ label: 'Analytics', icon: 'analytics', link: '/analytics' }` **before** the
  placeholder items; keep `[routerLink]="item.link"` + `routerLinkActive` binding.

### 7c. Icon — `components/atoms/icon/icon.{ts,html}`

- Add `'analytics'` to the `IconName` union and a stroke-based SVG case (three ascending bars,
  matching the existing 24×24 set).

---

## 8. TDD EXECUTION ORDER (Strict Red → Green → Refactor)

> Every unit below: write the spec, run `npm test` to see it **fail (Red)**, then implement the
> minimal code, run again to **pass (Green)**, then refactor if needed. No implementation before
> its failing spec.

```
PHASE 1 — Models & Mocks (no tests needed beyond compile)
  ├─ Step 1.1: analytics.model.ts
  └─ Step 1.2: mock-analytics.data.ts

PHASE 2 — Services (Red → Green)
  ├─ Step 2.1: telemetry.service.spec.ts  → telemetry.service.ts
  ├─ Step 2.2: ai-metrics.service.spec.ts → ai-metrics.service.ts
  └─ Step 2.3: database.service.spec.ts   → database.service.ts

PHASE 3 — Stores (Red → Green)
  ├─ Step 3.1: analytics.store.spec.ts    → analytics.store.ts
  │   (load success/failure, retry, feedbackDistribution derived from DashboardStore)
  └─ Step 3.2: vector-inspector.store.spec.ts → vector-inspector.store.ts
      (loadTables, selectTable fetches rows, search returns sorted results, error/retry, reset)

PHASE 4 — Components (Red → Green)
  ├─ Step 4.1: bar-chart.spec.ts → bar-chart.ts (normalized bars, empty state)
  ├─ Step 4.2: mobile-usage.spec.ts → mobile-usage.* (tiles + table + empty state)
  ├─ Step 4.3: ai-performance.spec.ts → ai-performance.* (stats + chart + distribution split)
  └─ Step 4.4: vector-inspector.spec.ts → vector-inspector.* (selector, rows, vector preview,
      search results, error+retry)

PHASE 5 — Page + Routing
  ├─ Step 5.1: analytics.page.spec.ts → analytics.page.* (sections render, store loads on init)
  ├─ Step 5.2: app.routes.spec.ts → add /analytics lazy-route assertion
  ├─ Step 5.3: admin-sidebar + icon (analytics nav + icon)
  └─ Step 5.4: dashboard-home.spec.ts — confirm no regression

PHASE 6 — Verification
  ├─ npm run build   (0 errors, budgets respected)
  ├─ npm test        (all suites green)
  └─ ng serve → /analytics → three panels render with mocks; sidebar link active
```

---

## 9. TESTING CHECKLIST (maps to `advanced_analytics_rag.feature`)

| # | Scenario | Spec |
|---|---|---|
| 1 | Active workout sessions | `AnalyticsStore`/`MobileUsage` renders `activeWorkoutSessions` |
| 2 | Sync status | Pending items + last-sync timestamp rendered |
| 3 | Telemetry event list | `mat-table` rows newest-first; type + timestamp |
| 4 | Empty telemetry | Empty-state copy; no rows |
| 5 | Avg latency | `AiPerformance.averageLatencyMs` rendered |
| 6 | Token throughput | `averageTokensPerSecond` rendered |
| 7 | Latency chart | `BarChart` renders one rect per sample |
| 8 | Feedback distribution | positive/negative counts + split segment widths |
| 9 | Table list | `VectorInspectorStore.tables` with rowCount |
| 10 | Table rows | `mat-table` rows incl. vector-column preview |
| 11 | Embedding metadata | `dimensions` chip per vector column |
| 12 | Semantic search | results ordered by `score` desc with similarity shown |
| 13 | DB error + retry | Error state → Retry re-runs the query |

---

## 10. FILE MANIFEST — New & Modified

| Action | Path |
|---|---|
| **CREATE** | `test/features/advanced_analytics_rag.feature` |
| **CREATE** | `plan_advanced_analytics.md` |
| **CREATE** | `src/app/core/models/analytics.model.ts` |
| **CREATE** | `src/app/core/mocks/mock-analytics.data.ts` |
| **CREATE** | `src/app/core/services/telemetry.service.ts` (+ spec) |
| **CREATE** | `src/app/core/services/ai-metrics.service.ts` (+ spec) |
| **CREATE** | `src/app/core/services/database.service.ts` (+ spec) |
| **CREATE** | `src/app/core/stores/analytics.store.ts` (+ spec) |
| **CREATE** | `src/app/core/stores/vector-inspector.store.ts` (+ spec) |
| **CREATE** | `src/app/features/analytics/pages/analytics/analytics.page.{ts,html,scss,spec.ts}` |
| **CREATE** | `src/app/features/analytics/components/mobile-usage/*` |
| **CREATE** | `src/app/features/analytics/components/ai-performance/*` |
| **CREATE** | `src/app/features/analytics/components/vector-inspector/*` |
| **CREATE** | `src/app/features/analytics/components/charts/bar-chart/*` |
| **MODIFY** | `src/app/app.routes.ts` | lazy `/analytics` route |
| **MODIFY** | `src/app/app.routes.spec.ts` | `/analytics` resolves to lazy component |
| **MODIFY** | `src/app/components/organisms/admin-sidebar/*` | "Analytics" nav item |
| **MODIFY** | `src/app/components/atoms/icon/{ts,html}` | `analytics` icon |

---

## 11. RISKS & NOTES

- **Backend absence**: all three sections are mock-first; contracts are proposals. Wire real
  HTTP by flipping `environment.useMocks` when the endpoints land — UI unchanged.
- **Strict TDD**: do not write implementation before the failing spec for each unit; the Red run
  is the proof of validity.
- **Charting**: no chart library — the pure-SVG `BarChart` keeps the bundle lean and the
  "sober/pure CSS" design principle intact.
- **Branch discipline**: all work happens on `feature/advanced-analytics-rag` (created from
  `main`); no direct `main` commits.
- **Budgets**: bundle is ~814 kB (warn 500 kB). Material `mat-table`/`mat-select` add weight;
  keep within the 1 MB error budget — consider lazy-loading the analytics route (already planned).
- **SCSS**: each component stays under the 4 kB/8 kB budget; reuse tokens, no new hex values.

---

_Generated by @Architect. Hand off to @Coder with this file + `test/features/advanced_analytics_rag.feature` as acceptance criteria._