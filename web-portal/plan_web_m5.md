# MILESTONE WEB-5 — Technical Blueprint
## DPO Dataset Export Module (Angular Web Portal)

**Acceptance criteria:** `test/features/dpo_export.feature`

---

## 0. DESIGN TOKEN REFERENCE (from `design-system/design-tokens.json`)

| Role | Token | Hex |
|---|---|---|
| Card surface | `surface.800` | `#1E293B` |
| Border / divider | `surface.700` | `#334155` |
| Primary | `primary.500` | `#3B82F6` |
| Text high / medium / low | `text.high/medium/low` | `#F8FAFC` / `#CBD5E1` / `#64748B` |
| Success | `success` | `#22C55E` |
| Neutral muscle | `neutral.muscle` | `#94A3B8` |

Spacing `xs=4 … xxl=32`, radius `sm=8 / md=12 / lg=20`, motion `fast=150ms / normal=250ms`, curve `ease-out`. Typography **Inter**, 12/14/16/20/24/32.

---

## 1. CONTEXT & RECONCILIATION (verified against the repo)

- The RLHF surface is the dashboard's **AI-Generated Routines** panel (`DashboardHome`,
  `/admin-dashboard`). Export lives there — **no new route**.
- Consumed inputs:
  - `AiInteraction` (`src/app/core/models/interaction.model.ts`): `id`, `userPrompt`,
    `generatedRoutine`, `rating` (`'thumbs_up' | 'thumbs_down' | null`), `feedbackText`
    (`string | null`), `createdAt`, `model?`, `status?`.
  - `DashboardStore` (`src/app/core/stores/dashboard.store.ts`): holds the full
    `interactions` signal; `submitFeedback` patches it live, so the eligible set updates as
    feedback is added.
  - `DashboardHome` header row: `<div class="dashboard-home__panel-header">` currently holds
    the heading + summary span.
- Conventions: signal-native, `@Service()` + `inject()`, colocated Vitest specs, SCSS budget
  (4 kB warn / 8 kB err), `@angular/material` v22 (theme active).

### 1a. Export scope decision

The export uses the **full eligible dataset** (`store.interactions()`), **not** the filtered
`visibleInteractions()`. Filters are a browsing aid; the exported training set must include
every reviewed interaction regardless of the current filter state.

---

## 2. DPO DOMAIN CONTRACT

### 2a. Eligibility

An interaction is exported **only if**:

```ts
interaction.rating !== null && interaction.feedbackText !== null && interaction.feedbackText.trim() !== ''
```

Rating without feedback (or vice versa) → excluded. This is the M5 filter rule.

### 2b. JSONL row (one JSON object per line, escaped with `JSON.stringify`)

```json
{
  "prompt": "Age: 28, Goal: build_muscle, Level: intermediate, Days: 4",
  "chosen": "Weekly routine\n\nDay 1 - Push: Bench press 4x8, ...",
  "rejected": "Great volume but reduce rest to 60s.",
  "model": "llama3.2",
  "interaction_id": "f3c2...-guid",
  "created_at": "2026-08-17T09:30:00Z"
}
```

### 2c. `chosen` / `rejected` mapping (based on the rating)

| Rating | `chosen` | `rejected` |
|---|---|---|
| `thumbs_up` | `generatedRoutine` (the liked response) | `feedbackText` (the suggested improvement) |
| `thumbs_down` | `feedbackText` (the administrator's correction) | `generatedRoutine` (the disliked response) |

Rationale: the feedback text always participates, making every exported row a genuine
preference pair for DPO training, with the polarity determined by the rating.

### 2d. Output file

- Filename: `dpo-dataset-YYYY-MM-DD.jsonl` (local date).
- MIME type: `application/x-ndjson`.
- Content: eligible rows joined by `\n` with a trailing newline.

---

## 3. PURE UTIL — `src/app/core/utils/dpo-export.util.ts`

Keeps the mapping and formatting free of DOM/DI so it is trivially unit-testable.

```ts
export interface DpoDatasetRow {
  prompt: string;
  chosen: string;
  rejected: string;
  model: string;
  interaction_id: string;
  created_at: string;
}

export function isDpoEligible(interaction: AiInteraction): boolean {
  return (
    interaction.rating !== null &&
    interaction.feedbackText !== null &&
    interaction.feedbackText.trim() !== ''
  );
}

export function toDpoRow(interaction: AiInteraction): DpoDatasetRow {
  const thumbsUp = interaction.rating === 'thumbs_up';
  return {
    prompt: interaction.userPrompt,
    chosen: thumbsUp ? interaction.generatedRoutine : interaction.feedbackText ?? '',
    rejected: thumbsUp ? interaction.feedbackText ?? '' : interaction.generatedRoutine,
    model: interaction.model ?? '',
    interaction_id: interaction.id,
    created_at: interaction.createdAt,
  };
}

export function buildDpoJsonl(interactions: AiInteraction[]): string {
  const lines = interactions
    .filter(isDpoEligible)
    .map((interaction) => JSON.stringify(toDpoRow(interaction)));
  return lines.length > 0 ? `${lines.join('\n')}\n` : '';
}

export function buildDpoFileName(date: Date = new Date()): string {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `dpo-dataset-${yyyy}-${mm}-${dd}.jsonl`;
}
```

---

## 4. EXPORT SERVICE — `src/app/core/services/export.service.ts`

Owns Blob creation + DOM manipulation. `@Service()`, no HTTP.

```ts
@Service()
export class ExportService {
  downloadDpoDataset(interactions: AiInteraction[]): void {
    const content = buildDpoJsonl(interactions);
    if (content === '') {
      return;
    }
    const blob = new Blob([content], { type: 'application/x-ndjson' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = buildDpoFileName();
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
  }
}
```

- Uses the platform `Blob` / `URL` / `document` — **no extra library**.
- Guards empty content (defensive double-check with the store/button disabled state).
- `revokeObjectURL` runs immediately after `click()` (standard practice for a same-tick
  download; if a Firefox delay issue arises, wrap in `setTimeout(…, 0)` — note in §10).

---

## 5. STORE EXTENSIONS — `dashboard.store.ts`

Derived signals only — no new state or service calls.

```ts
readonly exportableInteractions = computed(() =>
  this.interactions().filter(isDpoEligible),
);
readonly exportableCount = computed(() => this.exportableInteractions().length);
```

`submitFeedback` already patches `interactions`, so `exportableCount` grows the moment an
interaction gains a rating + feedback (and shrinks when rating is `null`). `reset()` needs no
change (all derived).

---

## 6. COMPONENT + PLACEMENT

### 6a. `src/app/features/dashboard/components/dpo-export/dpo-export.ts`

```ts
@Component({
  selector: 'app-dpo-export',
  imports: [MatButtonModule, MatIconModule],
  templateUrl: './dpo-export.html',
  styleUrl: './dpo-export.scss',
})
export class DpoExport {
  readonly interactions = input<AiInteraction[]>([]);
  private readonly exportService = inject(ExportService);

  readonly ready = computed(() => this.interactions().filter(isDpoEligible).length);

  export(): void {
    this.exportService.downloadDpoDataset(this.interactions());
  }
}
```

Template:

```html
<button
  mat-raised-button
  type="button"
  color="primary"
  [disabled]="ready() === 0"
  (click)="export()"
>
  <mat-icon>download</mat-icon>
  Export DPO Dataset ({{ ready() }})
</button>
```

### 6b. Placement in `DashboardHome`

Add to the **panel header row** (always visible once data is loaded, independent of filters):

```html
<div class="dashboard-home__panel-header">
  <h2 class="dashboard-home__heading">AI-Generated Routines</h2>
  <div class="dashboard-home__header-actions">
    @if (store.total() > 0) {
      <span class="dashboard-home__summary">…existing summary…</span>
    }
    @if (store.total() > 0) {
      <app-dpo-export [interactions]="store.interactions()" />
    }
  </div>
</div>
```

- Import `DpoExport` in `dashboard-home.ts` and add to `imports`.
- `.dashboard-home__header-actions` = flex row, `gap: 12px`, `align-items: center`, wraps on
  narrow widths. Keep SCSS under budget.
- **Pass `store.interactions()` (full list), never `visibleInteractions()`** (§1a).

---

## 7. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `src/app/core/utils/dpo-export.util.ts` | Eligibility + JSONL mapping + filename (§3) |
| **CREATE** | `src/app/core/utils/dpo-export.util.spec.ts` | Mapping/eligibility/JSONL tests |
| **CREATE** | `src/app/core/services/export.service.ts` | Blob + DOM download (§4) |
| **CREATE** | `src/app/core/services/export.service.spec.ts` | Download trigger tests (spy on `URL`/anchor) |
| **CREATE** | `src/app/features/dashboard/components/dpo-export/*` | Button + count + download trigger |
| **MODIFY** | `src/app/core/stores/dashboard.store.ts` | `exportableInteractions` / `exportableCount` |
| **MODIFY** | `src/app/core/stores/dashboard.store.spec.ts` | Derived-count tests |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.{ts,html,scss}` | Header actions + `<app-dpo-export>` |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.spec.ts` | Render + disable-state tests |

---

## 8. IMPLEMENTATION ORDER (Recommended for @Coder)

```
PHASE 1 — Pure logic
  ├─ Step 1.1: dpo-export.util.ts + spec (eligibility, thumbs-up/down mapping, JSONL escaping,
  │            filename, empty input → '')
  └─ Step 1.2: store exportableInteractions + exportableCount + spec

PHASE 2 — Download
  ├─ Step 2.1: export.service.ts (Blob/URL/anchor)
  └─ Step 2.2: export.service.spec.ts (stub URL.createObjectURL/revokeObjectURL + anchor.click;
            assert blob content + filename; empty → no call)

PHASE 3 — UI
  ├─ Step 3.1: dpo-export component + spec (count, disabled when 0, triggers service)
  ├─ Step 3.2: dashboard-home header-actions layout + <app-dpo-export>
  └─ Step 3.3: dashboard-home.spec additions (button rendered with count; disabled state)

PHASE 4 — Verification
  ├─ Step 4.1: npm run build
  ├─ Step 4.2: npm test   (all specs green)
  └─ Step 4.3: ng serve → rate + comment an interaction → Export → downloads .jsonl
```

---

## 9. TESTING CHECKLIST (maps to `dpo_export.feature`)

| # | Scenario | Expected test |
|---|---|---|
| 1 | Export action + eligible count | `DpoExport.ready` = eligible count; text shows it |
| 2 | Disabled when nothing eligible | `ready() === 0` → button `disabled`; clicking calls nothing |
| 3 | Only rated + feedback included | `buildDpoJsonl` excludes unrated / no-feedback |
| 4 | Download triggered | Service spy: `click` called; `download` filename matches `dpo-dataset-<date>.jsonl` |
| 5 | Valid JSONL | Every line parses; has `prompt`/`chosen`/`rejected`; prompt = `userPrompt` |
| 6 | Thumbs-up mapping | `chosen` = routine, `rejected` = feedback |
| 7 | Thumbs-down mapping | `chosen` = feedback, `rejected` = routine |

---

## 10. RISKS & NOTES

- **jsdom limitations**: `URL.createObjectURL`/`revokeObjectURL` are not implemented in jsdom —
  stub them in the service spec (`vi.stubGlobal` / direct assignment) and restore after.
- **`revokeObjectURL` timing**: revoking synchronously after `click()` is standard; if download
  breaks in a specific browser, defer revocation with `setTimeout(…, 0)`.
- **Eligibility drives everything**: keep the predicate in the util so component, service, and
  store share one source of truth.
- **Do not export filtered view**: export must read `store.interactions()`, not
  `visibleInteractions()` (§1a).
- **Budgets**: bundle already ~794 kB (warn 500 kB). `mat-icon` + button add little; keep as a
  warning, do not raise the error budget.

---

_Generated by @Architect. Hand off to @Coder with this file + `test/features/dpo_export.feature` as acceptance criteria._