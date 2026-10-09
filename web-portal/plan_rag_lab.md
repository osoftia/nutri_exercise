# RAG Prompt Lab — Technical & Design Plan

> **Milestone:** `rag-prompt-lab`
> **Branch:** `feature/rag-prompt-lab`
> **Status:** Architect blueprint — awaiting Coder implementation

---

## 1. File Inventory

| # | File Path | Purpose |
|---|-----------|---------|
| 1 | `src/app/core/models/prompt-lab.model.ts` | TypeScript interfaces for the prompt lab domain |
| 2 | `src/app/core/mocks/mock-prompt-lab.data.ts` | Deterministic mock data and factory function |
| 3 | `src/app/core/services/prompt-lab.service.ts` | Injectable service wrapping the mock (swappable for real API later) |
| 4 | `src/app/core/stores/prompt-lab.store.ts` | Angular Signals state container (`@Service()` decorator) |
| 5 | `src/app/components/organisms/prompt-lab/prompt-lab.ts` | Organism component class |
| 6 | `src/app/components/organisms/prompt-lab/prompt-lab.html` | Template (structural HTML, Angular control flow) |
| 7 | `src/app/components/organisms/prompt-lab/prompt-lab.scss` | Scoped styles using ONLY design tokens |
| 8 | `src/app/components/organisms/prompt-lab/prompt-lab.spec.ts` | Vitest component tests |
| 9 | `src/app/app.routes.ts` | **Modify** — add lazy route `{ path: 'rag-lab', loadComponent: ... }` |
| 10 | `test/features/rag_prompt_lab.feature` | Gherkin BDD contract (Deliverable 1) |

No other files are created or modified.

---

## 2. State Model — `PromptLabStore`

**File:** `src/app/core/stores/prompt-lab.store.ts`
**Pattern:** Identical to `vector-inspector.store.ts` — `@Service()` decorator, `signal()`, `computed()`, `inject()`, `finalize` from `rxjs`.

### Signals

| Signal | Type | Default | Description |
|--------|------|---------|-------------|
| `temperature` | `signal<number>` | `0.7` | LLM sampling temperature |
| `similarityThreshold` | `signal<number>` | `0.8` | Minimum cosine similarity for pgvector matches |
| `systemPrompt` | `signal<string>` | `''` | Bound reactively to the textarea (no button press) |
| `query` | `signal<string>` | `''` | The user's test query |
| `loading` | `signal<boolean>` | `false` | True while the mock service is "processing" |
| `result` | `signal<PromptLabResult \| null>` | `null` | The mock response payload |
| `error` | `signal<string \| null>` | `null` | Error message if the service call fails |

### Computed

| Computed | Derivation |
|----------|------------|
| `latencyMs` | `computed(() => this.result()?.latencyMs ?? null)` |
| `tokensPerSecond` | `computed(() => this.result()?.tokensPerSecond ?? null)` |
| `hasResult` | `computed(() => this.result() !== null)` |

### Methods

| Method | Behavior |
|--------|----------|
| `setTemperature(value: number)` | `this.temperature.set(value)` |
| `setSimilarityThreshold(value: number)` | `this.similarityThreshold.set(value)` |
| `setSystemPrompt(value: string)` | `this.systemPrompt.set(value)` — called on every `input` event |
| `setQuery(value: string)` | `this.query.set(value)` |
| `runQuery()` | Guards against empty query and active loading. Sets `loading(true)`, `error(null)`, calls `promptLabService.runQuery(...)` piped through `finalize(() => this.loading.set(false))`. On `next`: sets `result`. On `error`: sets `error`. |
| `reset()` | Resets all signals to their defaults. |

### `runQuery()` Pseudocode

```
runQuery():
  if query().trim() === '' or loading() → return
  loading.set(true)
  error.set(null)
  promptLabService.runQuery({
    query: query(),
    systemPrompt: systemPrompt(),
    temperature: temperature(),
    similarityThreshold: similarityThreshold()
  }).pipe(finalize(() => loading.set(false)))
    .subscribe({
      next: (result) => this.result.set(result),
      error: () => this.error.set('Could not execute the prompt query.')
    })
```

---

## 3. Domain Models

**File:** `src/app/core/models/prompt-lab.model.ts`

```typescript
export interface PromptLabRequest {
  query: string;
  systemPrompt: string;
  temperature: number;
  similarityThreshold: number;
}

export interface MatchedSource {
  id: string;
  title: string;
  score: number;
}

export interface PromptLabResult {
  answer: string;
  matchedSources: MatchedSource[];
  latencyMs: number;
  tokensPerSecond: number;
}
```

---

## 4. Mock Data & Service

### Mock Data — `src/app/core/mocks/mock-prompt-lab.data.ts`

```typescript
import { PromptLabResult } from '../models/prompt-lab.model';

export const MOCK_PROMPT_LAB_RESULT: PromptLabResult = {
  answer:
    '## Recovery Routine After Intense Dance Rehearsal\n\n' +
    '1. **Cool-down (5 min):** Low-intensity stretching focusing on calves, hamstrings, and hip flexors.\n' +
    '2. **Hydration:** 500 ml water with electrolytes within 30 minutes.\n' +
    '3. **Nutrition:** 20 g whey protein + fast-acting carbs (banana or rice cake) within 45 minutes.\n' +
    '4. **Active recovery (next day):** 20 min light yoga or swimming.\n' +
    '5. **Sleep:** Target 8 hours; magnesium supplement (200 mg) before bed.',
  matchedSources: [
    { id: 'src-001', title: 'Dance-specific recovery protocols', score: 0.94 },
    { id: 'src-002', title: 'Post-exercise nutrition for performers', score: 0.87 },
    { id: 'src-003', title: 'Sleep and muscle recovery in athletes', score: 0.79 },
  ],
  latencyMs: 1842,
  tokensPerSecond: 38,
};

export function mockPromptLabResponse(query: string): PromptLabResult {
  // Deterministic: always returns the same mock regardless of query.
  // The query string is embedded in the answer for traceability.
  return {
    ...MOCK_PROMPT_LAB_RESULT,
    answer: MOCK_PROMPT_LAB_RESULT.answer.replace(
      'Recovery Routine After Intense Dance Rehearsal',
      `Response to: "${query}"`,
    ),
  };
}
```

### Service — `src/app/core/services/prompt-lab.service.ts`

```typescript
import { Injectable } from '@angular/core';
import { Observable, delay, of } from 'rxjs';

import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import { mockPromptLabResponse } from '../mocks/mock-prompt-lab.data';

@Injectable({ providedIn: 'root' })
export class PromptLabService {
  private static readonly MOCK_DELAY_MS = 1200;

  runQuery(request: PromptLabRequest): Observable<PromptLabResult> {
    return of(mockPromptLabResponse(request.query)).pipe(
      delay(PromptLabService.MOCK_DELAY_MS),
    );
  }
}
```

---

## 5. Routing Addition

**File:** `src/app/app.routes.ts` — add one route entry:

```typescript
{
  path: 'rag-lab',
  loadComponent: () =>
    import('./components/organisms/prompt-lab/prompt-lab').then(
      (m) => m.PromptLab,
    ),
},
```

Insert before the `admin-dashboard` redirect. The final routes array:

```typescript
export const routes: Routes = [
  { path: 'history', component: DashboardHome },
  {
    path: 'analytics',
    loadComponent: () =>
      import('./pages/analytics/analytics.page').then((m) => m.AnalyticsPage),
  },
  {
    path: 'rag-lab',
    loadComponent: () =>
      import('./components/organisms/prompt-lab/prompt-lab').then(
        (m) => m.PromptLab,
      ),
  },
  { path: 'admin-dashboard', redirectTo: '/history', pathMatch: 'full' },
  { path: '', redirectTo: '/history', pathMatch: 'full' },
];
```

---

## 6. Component Architecture

### Class — `prompt-lab.ts`

- `@Component({ selector: 'app-prompt-lab', imports: [], templateUrl, styleUrl })`
- Injects `PromptLabStore` via `inject(PromptLabStore)`
- Local signal: none needed — all state lives in the store
- Event handlers:
  - `onTemperatureInput(event: Event)` → reads `input.valueAsNumber`, calls `store.setTemperature()`
  - `onThresholdInput(event: Event)` → reads `input.valueAsNumber`, calls `store.setSimilarityThreshold()`
  - `onSystemPromptInput(event: Event)` → reads `textarea.value`, calls `store.setSystemPrompt()` — **fires on every keystroke** (real-time binding)
  - `onQueryInput(event: Event)` → reads `input.value`, calls `store.setQuery()`
  - `onRunQuery()` → calls `store.runQuery()`
  - `onReset()` → calls `store.reset()`

### Template — `prompt-lab.html`

Structural outline (BEM class names, Angular 17+ control flow):

```
<section class="prompt-lab" aria-label="RAG Prompt Laboratory">

  <!-- LEFT COLUMN: Controls (grid-column: 1 / 6) -->
  <div class="prompt-lab__controls">
    <h2 class="prompt-lab__heading">Prompt Lab</h2>

    <!-- System Prompt -->
    <label class="prompt-lab__field">
      <span class="prompt-lab__overline">System Prompt</span>
      <textarea class="prompt-lab__textarea"
        rows="6"
        placeholder="You are a sports nutrition expert…"
        [value]="store.systemPrompt()"
        (input)="onSystemPromptInput($event)"></textarea>
    </label>

    <!-- Temperature -->
    <label class="prompt-lab__field">
      <span class="prompt-lab__overline">Temperature</span>
      <input class="prompt-lab__range" type="range"
        min="0" max="2" step="0.1"
        [value]="store.temperature()"
        (input)="onTemperatureInput($event)" />
      <span class="prompt-lab__value">{{ store.temperature() }}</span>
    </label>

    <!-- Similarity Threshold -->
    <label class="prompt-lab__field">
      <span class="prompt-lab__overline">Similarity Threshold</span>
      <input class="prompt-lab__range" type="range"
        min="0" max="1" step="0.05"
        [value]="store.similarityThreshold()"
        (input)="onThresholdInput($event)" />
      <span class="prompt-lab__value">{{ store.similarityThreshold() }}</span>
    </label>

    <!-- Query -->
    <label class="prompt-lab__field">
      <span class="prompt-lab__overline">Test Query</span>
      <input class="prompt-lab__input" type="text"
        placeholder="Recovery routine after intense dance rehearsal"
        [value]="store.query()"
        (input)="onQueryInput($event)" />
    </label>

    <div class="prompt-lab__actions">
      <button class="prompt-lab__button prompt-lab__button--run"
        [disabled]="store.loading()"
        (click)="onRunQuery()">Run Query</button>
      <button class="prompt-lab__button prompt-lab__button--reset"
        (click)="onReset()">Reset</button>
    </div>
  </div>

  <!-- RIGHT COLUMN: Results (grid-column: 7 / 13) -->
  <div class="prompt-lab__results">

    @if (store.loading()) {
      <div class="prompt-lab__loading">
        <span class="prompt-lab__overline">Processing…</span>
      </div>
    }

    @if (store.error(); as message) {
      <div class="prompt-lab__error">
        <p>{{ message }}</p>
      </div>
    }

    @if (store.hasResult() && !store.loading()) {
      <!-- Latency hero metric — spans full width of right column -->
      <div class="prompt-lab__latency-hero">
        <span class="prompt-lab__overline">Latency</span>
        <span class="prompt-lab__latency-number">{{ store.latencyMs() }}<small>ms</small></span>
        <span class="prompt-lab__tps">{{ store.tokensPerSecond() }} tok/s</span>
      </div>

      <!-- Answer -->
      <div class="prompt-lab__answer">
        <h3 class="prompt-lab__subheading">Generated Answer</h3>
        <div class="prompt-lab__answer-text">{{ store.result()?.answer }}</div>
      </div>

      <!-- Matched Sources -->
      <div class="prompt-lab__sources">
        <h3 class="prompt-lab__subheading">Matched Sources</h3>
        <table class="prompt-lab__table">
          <thead>
            <tr><th>Title</th><th>Score</th></tr>
          </thead>
          <tbody>
            @for (source of store.result()?.matchedSources ?? []; track source.id) {
              <tr>
                <td>{{ source.title }}</td>
                <td>{{ (source.score * 100).toFixed(1) }}%</td>
              </tr>
            }
          </tbody>
        </table>
      </div>
    }
  </div>

</section>
```

---

## 7. Design Constraints — "Editorial Tech" Aesthetic

### 7.1 Asymmetric CSS Grid Layout

The root `.prompt-lab` element uses a **12-column CSS grid** with deliberate asymmetry:

```scss
.prompt-lab {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: var(--grid-gutter);
  padding: 40px;
  min-height: 100vh;
  background-color: var(--color-bg);          /* solid #0F172A */
}

.prompt-lab__controls {
  grid-column: 1 / 6;                        /* 5 columns, offset left */
}

.prompt-lab__results {
  grid-column: 7 / 13;                       /* 6 columns, offset right — 1-col gutter gap */
}
```

The **latency hero** inside the results panel spans the full 6-column width and uses the oversized display typography:

```scss
.prompt-lab__latency-hero {
  grid-column: 1 / -1;                       /* full width of its parent */
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  padding: 32px;
  background-color: var(--color-surface);
  border: var(--border-strong);
  border-radius: var(--radius-none);
}

.prompt-lab__latency-number {
  font-family: var(--font-family);
  font-size: var(--font-size-display-lg);    /* 96px */
  font-weight: var(--font-weight-display);   /* 800 */
  letter-spacing: var(--letter-spacing-tight); /* -0.03em */
  line-height: 0.9;
  color: var(--color-text-high);
}

.prompt-lab__latency-number small {
  font-size: var(--font-size-h2);            /* 30px */
  font-weight: var(--font-weight-bold);
  color: var(--color-text-low);
  margin-left: 4px;
}
```

### 7.2 Typography Rules

| Element | Token | Value |
|---------|-------|-------|
| Page heading "Prompt Lab" | `--font-size-hero` | 48px |
| Heading weight | `--font-weight-display` | 800 |
| Heading tracking | `--letter-spacing-tight` | -0.03em |
| Overline labels | `--font-size-caption` + `--letter-spacing-overline` + `uppercase` | 11px, 0.14em |
| Latency number | `--font-size-display-lg` | **96px** |
| Latency weight | `--font-weight-display` | 800 |
| Tokens/sec | `--font-size-metric` | 36px |
| Body / answer text | `--font-size-body` | 16px |
| Table cells | `--font-size-label` | 13px |
| All fonts | `--font-family` | Montserrat |

### 7.3 Hard Borders & Zero Radius

Every panel, input, button, and table uses:
- `border: var(--border-strong)` (2px solid `--color-text-high`) or `var(--border-thin)` (1px solid `--color-border`)
- `border-radius: var(--radius-none)` (0px) — **no rounded corners anywhere**
- Accent button: `background-color: var(--color-block-accent)` (orange `#f97316`), `color: var(--color-ink)`

### 7.4 Color Palette (tokens only)

| Role | Token | Hex |
|------|-------|-----|
| Page background | `--color-bg` | `#0f172a` |
| Panel surface | `--color-surface` | `#1e293b` |
| High-emphasis text | `--color-text-high` | `#f8fafc` |
| Medium text | `--color-text-medium` | `#cbd5e1` |
| Low / overline text | `--color-text-low` | `#64748b` |
| Accent (buttons, chips) | `--color-block-accent` | `#f97316` |
| Primary (links, focus) | `--color-primary` | `#3b82f6` |
| Ink (dark text on accent) | `--color-ink` | `#0b0f1a` |

### 7.5 Forbidden

- **NO `mat-card`**, `mat-button`, or any Angular Material component
- **NO `border-radius` values other than `var(--radius-none)`** for structural elements
- **NO hardcoded hex colors** — every color must reference a CSS custom property from `design-tokens.scss`
- **NO `box-shadow`** — the aesthetic relies entirely on hard borders and flat color

---

## 8. Vitest Spec — `prompt-lab.spec.ts`

**Pattern:** Mirrors `vector-inspector.spec.ts` — `describe/it/expect/beforeEach/vi`, `ComponentFixture`, mock service via `TestBed.configureTestingModule`.

### Test Cases

| # | Test | Assertion |
|---|------|-----------|
| 1 | Default temperature is 0.7 | `store.temperature()` equals `0.7` on init |
| 2 | Default similarity threshold is 0.8 | `store.similarityThreshold()` equals `0.8` on init |
| 3 | System prompt binds reactively | Dispatch `input` event on textarea → `store.systemPrompt()` equals typed text |
| 4 | Run query sets loading to true | Click "Run Query" → `store.loading()` is `true` before observable emits |
| 5 | Run query renders result after delay | Flush the mock observable → `store.hasResult()` is `true`, DOM contains answer text |
| 6 | Latency metrics are displayed | After result, DOM contains `"1842"` and `"ms"` |
| 7 | Matched sources are rendered | After result, DOM contains `"Dance-specific recovery protocols"` and `"94.0%"` |
| 8 | Reset clears all state | After configuring values and running query, click "Reset" → all signals return to defaults |
| 9 | Error state is displayed | Force service error → DOM contains error message |

---

## 9. Implementation Order (for Coder)

1. `src/app/core/models/prompt-lab.model.ts` — interfaces first, zero dependencies
2. `src/app/core/mocks/mock-prompt-lab.data.ts` — mock data, depends only on models
3. `src/app/core/services/prompt-lab.service.ts` — service wrapping mock
4. `src/app/core/stores/prompt-lab.store.ts` — state container, depends on service + models
5. `src/app/components/organisms/prompt-lab/prompt-lab.ts` — component class
6. `src/app/components/organisms/prompt-lab/prompt-lab.html` — template
7. `src/app/components/organisms/prompt-lab/prompt-lab.scss` — styles (tokens only)
8. `src/app/components/organisms/prompt-lab/prompt-lab.spec.ts` — Vitest tests
9. `src/app/app.routes.ts` — add the `rag-lab` lazy route
10. `test/features/rag_prompt_lab.feature` — Gherkin contract (already written above)

---

## 10. Acceptance Criteria

- [ ] Navigating to `/rag-lab` renders the Prompt Lab with temperature at 0.7 and threshold at 0.8
- [ ] Typing in the system prompt textarea updates `store.systemPrompt()` on every keystroke (no button)
- [ ] Clicking "Run Query" shows a loading state, then renders the mock answer, matched sources, and latency metrics
- [ ] The latency number is rendered at 96px (`--font-size-display-lg`) with weight 800 (`--font-weight-display`)
- [ ] All styles use CSS custom properties from `design-tokens.scss` — zero hardcoded values
- [ ] All 9 Vitest tests pass
- [ ] The Gherkin scenarios are directly mappable to the Vitest assertions