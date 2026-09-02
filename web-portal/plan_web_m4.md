# MILESTONE WEB-4 — Technical Blueprint
## Advanced Search & Filtering — RLHF Dashboard (Angular Web Portal)

**Acceptance criteria:** `test/features/m4_search_filtering.feature`

---

## 0. DESIGN TOKEN REFERENCE (from `design-system/design-tokens.json`)

| Role | Token | Hex |
|---|---|---|
| Canvas BG | `surface.900` | `#0F172A` |
| Card surface | `surface.800` | `#1E293B` |
| Border / divider | `surface.700` | `#334155` |
| Primary | `primary.500` | `#3B82F6` |
| Accent CTA | `accent` | `#F97316` |
| Text high / medium / low | `text.high/medium/low` | `#F8FAFC` / `#CBD5E1` / `#64748B` |
| Danger | `danger` | `#EF4444` |

Spacing `xs=4 … xxl=32`, radius `sm=8 / md=12 / lg=20`, motion `fast=150ms / normal=250ms`, curve `ease-out`. Typography **Inter**, 12/14/16/20/24/32.

---

## 1. CONTEXT & RECONCILIATION (verified against the repo)

- The RLHF surface lives on the **dashboard** (`DashboardHome` at route `/admin-dashboard`,
  `src/app/pages/admin-dashboard/dashboard-home/`). There is **no `/history` route** in the
  codebase; all interaction UI (list, rating, feedback) was wired there in M3. This and the
  following milestones therefore target the dashboard's "AI-Generated Routines" panel.
- Existing pieces reused this milestone:
  - `DashboardStore` (`src/app/core/stores/dashboard.store.ts`) — signal store.
  - `RoutineCard` (`src/app/features/dashboard/components/routine-card/`) — renders one interaction.
  - Material v22 is installed + themed; `@angular/animations` present.
  - `MatDatepickerModule` / `provideNativeDateAdapter` confirmed available in the installed
    Material build.
- Conventions: signal-native (`signal`/`computed`/`input`/`model`/`output`), `@Service()` +
  `inject()`, `@if/@for` control flow, Vitest specs colocated, SCSS budget 4 kB warn / 8 kB err.

### 1a. Filtering strategy — client-side over the loaded list

`InteractionService.getInteractions()` returns the full list (mock-first). Filtering is applied
**in memory** over the `interactions` signal via a pure util, so the UI stays instant and
testable. The store keeps the filter state so the same contract can later be forwarded to the
service as query params when the backend ships filter endpoints.

---

## 2. PURE FILTER UTIL — `src/app/core/utils/interaction-filter.util.ts`

Centralizes the filter rules so unit tests can hit a plain function.

```ts
export interface InteractionFilters {
  query: string;
  from: Date | null;
  to: Date | null;
}

export function filterInteractions(
  items: AiInteraction[],
  filters: InteractionFilters,
): AiInteraction[] {
  const query = filters.query.trim().toLowerCase();
  return items.filter((interaction) => {
    const matchesQuery =
      query === '' ||
      [interaction.userPrompt, interaction.generatedRoutine, interaction.model ?? '']
        .some((field) => field.toLowerCase().includes(query));
    const created = new Date(interaction.createdAt);
    const matchesFrom = filters.from === null || created >= startOfDay(filters.from);
    const matchesTo = filters.to === null || created <= endOfDay(filters.to);
    return matchesQuery && matchesFrom && matchesTo;
  });
}

function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function endOfDay(date: Date): Date {
  const d = new Date(date);
  d.setHours(23, 59, 59, 999);
  return d;
}
```

- `from`/`to` are compared as **inclusive** day boundaries (selecting the same day includes it).
- Query is case-insensitive and trims whitespace.
- `clearFilters()` must also reset the debounced search pipeline (§5) so a reset stays consistent.

---

## 3. STORE EXTENSIONS — `dashboard.store.ts`

New state + derived signals (all `readonly`), alongside the existing ones:

```ts
readonly searchQuery = signal('');
readonly dateFrom = signal<Date | null>(null);
readonly dateTo = signal<Date | null>(null);

readonly visibleInteractions = computed(() =>
  filterInteractions(this.interactions(), {
    query: this.searchQuery(),
    from: this.dateFrom(),
    to: this.dateTo(),
  }),
);
readonly visibleTotal = computed(() => this.visibleInteractions().length);
readonly filtersActive = computed(
  () =>
    this.searchQuery().trim() !== '' ||
    this.dateFrom() !== null ||
    this.dateTo() !== null,
);

setSearchQuery(query: string): void { this.searchQuery.set(query); }
setDateRange(from: Date | null, to: Date | null): void {
  this.dateFrom.set(from);
  this.dateTo.set(to);
}
clearFilters(): void {
  this.setSearchQuery('');
  this.setDateRange(null, null);
}
```

- `interactions` stays the **authoritative full list**; `total`/`hasFeedback` keep their current
  meaning. The page renders `store.visibleInteractions()`.
- `reset()` additionally clears the three filter signals.
- `submitFeedback` keeps patching `interactions` (full list) so filtered views update live.

---

## 4. FILTER COMPONENT — `src/app/features/dashboard/components/search-filter/`

A self-contained filter bar: text input (debounced) + start/end `mat-datepicker` + "Clear filters".

### 4a. Component (`search-filter.ts`)

```ts
@Component({
  selector: 'app-search-filter',
  imports: [ReactiveFormsModule, MatFormFieldModule, MatInputModule,
            MatDatepickerModule, MatButtonModule, MatIconModule],
  templateUrl: './search-filter.html',
  styleUrl: './search-filter.scss',
  providers: [provideNativeDateAdapter()],
})
export class SearchFilter {
  readonly query = signal('');
  readonly from = signal<Date | null>(null);
  readonly to = signal<Date | null>(null);

  readonly queryChange = output<string>();
  readonly dateRangeChange = output<{ from: Date | null; to: Date | null }>();
  readonly clear = output<void>();

  private readonly queryInput = new Subject<string>();
  private readonly debounced = this.queryInput
    .pipe(debounceTime(300), distinctUntilChanged())
    .subscribe((value) => this.queryChange.emit(value));

  onQueryInput(value: string): void {
    this.query.set(value);
    this.queryInput.next(value);
  }

  onFromChange(date: Date | null): void {
    this.from.set(date);
    this.emitDateRange();
  }

  onToChange(date: Date | null): void {
    this.to.set(date);
    this.emitDateRange();
  }

  clearFilters(): void {
    this.query.set('');
    this.from.set(null);
    this.to.set(null);
    this.clear.emit();
  }

  private emitDateRange(): void {
    this.dateRangeChange.emit({ from: this.from(), to: this.to() });
  }
}
```

- `debounceTime(300)` + `distinctUntilChanged()` gives the single-update-on-pause behavior.
- The subscription must be torn down on destroy with `takeUntilDestroyed()` from
  `@angular/core/rxjs-interop` (field initializer runs in injection context).

### 4b. Template sketch (`search-filter.html`)

```html
<div class="search-filter">
  <mat-form-field appearance="outline">
    <mat-label>Search routines</mat-label>
    <input matInput [value]="query()"
           (input)="onQueryInput($any($event.target).value)"
           placeholder="Search prompt, text, or model..." />
  </mat-form-field>

  <mat-form-field appearance="outline">
    <mat-label>From</mat-label>
    <input matInput [matDatepicker]="fromPicker" [value]="from() ?? undefined"
           (dateChange)="onFromChange($event.value)" />
    <mat-datepicker-toggle matIconSuffix [for]="fromPicker" />
    <mat-datepicker #fromPicker />
  </mat-form-field>

  <mat-form-field appearance="outline">
    <mat-label>To</mat-label>
    <input matInput [matDatepicker]="toPicker" [value]="to() ?? undefined"
           (dateChange)="onToChange($event.value)" />
    <mat-datepicker-toggle matIconSuffix [for]="toPicker" />
    <mat-datepicker #toPicker />
  </mat-form-field>

  @if (filtersActive()) {
    <button mat-stroked-button (click)="clearFilters()">Clear filters</button>
  }
</div>
```

- `filtersActive` is a small `computed` on the component
  (`query() !== '' || from() !== null || to() !== null`).
- Keep SCSS lean (grid/flex row that wraps on small widths).

---

## 5. PAGE WIRING — `dashboard-home.*`

`DashboardHome` composes the filter above the cards:

```html
@if (store.total() > 0) {
  <app-search-filter
    (queryChange)="store.setSearchQuery($event)"
    (dateRangeChange)="store.setDateRange($event.from, $event.to)"
    (clear)="store.clearFilters()"
  />
}

@if (store.loading()) {
  <mat-spinner />
} @else if (store.error(); as message) {
  error panel + Retry
} @else if (store.visibleTotal() === 0 && !store.filtersActive()) {
  empty state ("No AI-generated routines yet.")
} @else if (store.visibleTotal() === 0) {
  filtered-empty state ("No routines match your filters.")
} @else {
  @for (interaction of store.visibleInteractions(); track interaction.id) {
    <app-routine-card ... />
  }
}
```

- Header summary switches to `{{ store.visibleTotal() }} of {{ store.total() }} routines`
  when `store.filtersActive()`, else the existing counts.
- The 4-tier state branch now distinguishes **no data** vs **no match**.

---

## 6. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `src/app/core/utils/interaction-filter.util.ts` | Pure filter logic (§2) |
| **CREATE** | `src/app/core/utils/interaction-filter.util.spec.ts` | Unit tests for query/date/combined |
| **CREATE** | `src/app/features/dashboard/components/search-filter/*` | Filter bar (debounce + datepickers) |
| **MODIFY** | `src/app/core/stores/dashboard.store.ts` | Filter signals + `visibleInteractions` + setters + `reset` |
| **MODIFY** | `src/app/core/stores/dashboard.store.spec.ts` | Filter-state tests |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.{ts,html,scss}` | Compose filter, render `visibleInteractions`, 4-tier states |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.spec.ts` | Filtering through the page |

---

## 7. IMPLEMENTATION ORDER (Recommended for @Coder)

```
PHASE 1 — Util + Store
  ├─ Step 1.1: interaction-filter.util.ts + spec (query, from, to, combined, day-boundary)
  ├─ Step 1.2: store filter signals + visibleInteractions + setters + clearFilters + reset
  └─ Step 1.3: store.spec additions (set filters → visible list changes; reset clears)

PHASE 2 — Component
  ├─ Step 2.1: search-filter.* (debounce pipeline, datepickers, clear button)
  └─ Step 2.2: search-filter.spec.ts (debounce with vitest fake timers, date emit, clear emit)

PHASE 3 — Page
  ├─ Step 3.1: wire <app-search-filter> + visibleInteractions + filtered-empty state in dashboard-home
  └─ Step 3.2: dashboard-home.spec.ts additions

PHASE 4 — Verification
  ├─ Step 4.1: npm run build
  ├─ Step 4.2: npm test   (all specs green)
  └─ Step 4.3: ng serve → type in search, pick dates, clear → list responds
```

---

## 8. TESTING CHECKLIST (maps to `m4_search_filtering.feature`)

| # | Scenario | Expected test |
|---|---|---|
| 1 | Search by text | Typing then pausing filters `visibleInteractions`; header shows count |
| 2 | Search across prompt/text/model | Util matches any of the three fields |
| 3 | Debounce single update | Component: 3 rapid inputs → 1 emitted query after 300 ms (fake timers) |
| 4 | Clear search | `query=''` → full list restored |
| 5 | Date range | `from`+`to` filters by `createdAt` (inclusive) |
| 6 | Start only | `from` filters `createdAt >= start-of-day` |
| 7 | End only | `to` filters `createdAt <= end-of-day` |
| 8 | Combined | Query + range both applied |
| 9 | No match | Filtered-empty message; no cards |
| 10 | Clear all | All filter signals reset; full list shown |

---

## 9. RISKS & NOTES

- **`mat-datepicker` adapter**: `provideNativeDateAdapter()` must be provided (component-level is
  fine) or the pickers throw `DateAdapter` errors in specs too.
- **Debounce + tests**: the zoneless Vitest env has no zone.js `fakeAsync`; use **Vitest fake
  timers** (`vi.useFakeTimers()` + `advanceTimersByTimeAsync`) and restore in `afterEach`.
- **Store reset**: `reset()` must clear filter signals or stale filters leak after reload.
- **Server-side filtering is deferred**: backend has no filter endpoints; the util/contract keeps
  the door open.
- **Budgets**: initial bundle is already at ~634 kB (warn limit 500 kB). Adding datepicker grows
  it; keep it a warning — do **not** bump the error budget.

---

_Generated by @Architect. Hand off to @Coder with this file + `test/features/m4_search_filtering.feature` as acceptance criteria._