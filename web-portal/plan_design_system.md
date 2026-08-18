# DESIGN SYSTEM — Technical Blueprint
## "Eco-Neumorphism Dark" UI Refactor + `/history` Route Fix (Angular Web Portal)

---

## 0. GOALS & PRINCIPLES

| Principle | Implementation |
|---|---|
| Sustainable & sober | Pure CSS (custom properties), no new UI library, OLED-friendly near-black backgrounds |
| Typography | **Montserrat** exclusively (replaces `Inter`), weights 400/500/600/700 |
| Neumorphism | Soft dark shadow bottom-right + subtle light reflection top-left on cards/buttons; extrusion matches the backdrop |
| Accessibility | Text contrast stays extremely high (`#F8FAFC` on `#0F172A`); `--color-text-low` only for tertiary labels |

Verified baseline: `src/styles.scss` currently uses the Material M3 dark theme with `Inter`;
`app.routes.ts` serves the RLHF dashboard at `/admin-dashboard`; the sidebar hard-codes
`routerLink="/admin-dashboard"` and ignores `item.link`.

---

## 1. DESIGN TOKENS — `src/styles/design-tokens.scss` (CREATE)

Pure CSS custom properties in `:root`, deliberately reusable across future projects.

```scss
:root {
  /* Color — Eco-Neumorphism Dark (OLED-friendly) */
  --color-bg: #0f172a;             /* surface.900 — page backdrop */
  --color-surface: #1e293b;        /* surface.800 — card/panel surface */
  --color-border: #334155;         /* surface.700 — dividers, hairline borders */
  --color-text-high: #f8fafc;      /* headings, values */
  --color-text-medium: #cbd5e1;    /* secondary text */
  --color-text-low: #64748b;       /* captions, tertiary labels */
  --color-primary: #3b82f6;
  --color-primary-light: #93c5fd;
  --color-accent: #f97316;
  --color-success: #22c55e;
  --color-warning: #eab308;
  --color-danger: #ef4444;
  --color-neutral: #94a3b8;

  /* Typography */
  --font-family: 'Montserrat', system-ui, -apple-system, sans-serif;
  --font-size-caption: 12px;
  --font-size-label: 14px;
  --font-size-body: 16px;
  --font-size-h3: 20px;
  --font-size-h2: 24px;
  --font-size-h1: 32px;

  /* Radius & Motion */
  --radius-sm: 8px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --motion-fast: 150ms;
  --motion-normal: 250ms;
  --ease-out: ease-out;

  /* Neumorphic shadows — soft 3D extrusion tuned for #0f172a */
  /* up: raised (cards/buttons idle); down: pressed (inset); flat: quiet resting */
  --shadow-neumorph-up:
    8px 8px 16px rgba(0, 0, 0, 0.45),
    -8px -8px 16px rgba(255, 255, 255, 0.04);
  --shadow-neumorph-down:
    inset 6px 6px 12px rgba(0, 0, 0, 0.45),
    inset -6px -6px 12px rgba(255, 255, 255, 0.04);
  --shadow-neumorph-flat:
    4px 4px 10px rgba(0, 0, 0, 0.35),
    -4px -4px 10px rgba(255, 255, 255, 0.03);
}
```

- Load it from `styles.scss` with `@use './styles/design-tokens';` (emits the `:root` block).
- Rule: **never hard-code a hex** in a component again — consume `var(--color-*)` /
  `var(--shadow-*)`.

---

## 2. MONTGESTRAT — FONT LOADING + MATERIAL TYPOGRAPHY

### 2a. `src/index.html` — Google Fonts (MODIFY)

Add inside `<head>` (before the app styles):

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link
  href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;600;700&display=swap"
  rel="stylesheet"
/>
```

### 2b. `src/styles.scss` — Material typography config (MODIFY)

Change the Material theme typography from `Inter` to `Montserrat`:

```scss
$theme: mat.define-theme(
  (
    color: (
      theme-type: dark,
      primary: mat.$blue-palette,
      tertiary: mat.$orange-palette,
    ),
    typography: (
      plain-family: 'Montserrat',
      brand-family: 'Montserrat',
    ),
  )
);
```

And set the document font:

```scss
body {
  margin: 0;
  font-family: var(--font-family);
  background-color: var(--color-bg);
  color: var(--color-text-high);
}
```

---

## 3. NEUMORPHIC OVERRIDES — `src/styles.scss`

Apply **after** `mat.all-component-themes($theme)` so the overrides win.

### 3a. Cards — replace Material elevation with extrusion

```scss
.mat-mdc-card {
  background-color: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-neumorph-up) !important; /* Material sets its own shadow */
}
```

### 3b. Buttons — flat resting, raised on hover, pressed on click

```scss
.mat-mdc-button-base,
.mdc-button {
  border-radius: var(--radius-md);
  font-weight: 600;
}

.mat-mdc-raised-button:not(:disabled),
.mat-mdc-unelevated-button:not(:disabled) {
  box-shadow: var(--shadow-neumorph-flat) !important;
}

.mat-mdc-button-base:not(:disabled):hover {
  box-shadow: var(--shadow-neumorph-up) !important;
}

.mat-mdc-button-base:not(:disabled):active {
  box-shadow: var(--shadow-neumorph-down) !important;
}
```

- Primary CTAs keep their primary-tinted fill; neumorphic shadows still read over it.
- `!important` is required because Material declares `box-shadow` on the same selector —
  keep it confined to `styles.scss` only.

### 3c. Form fields (inset, optional but cohesive)

```scss
.mat-mdc-text-field-wrapper {
  background-color: var(--color-bg);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-neumorph-down);
}
```

---

## 4. COMPONENT SCSS CLEANUP (hex → tokens)

The global overrides lose to component-level fills (e.g. `.analytics-summary__tile {
background-color: #1e293b; border: 1px solid #334155; }`). Replace hard-coded colors with
tokens and **remove flat fills/borders that break the extrusion illusion**:

| File | Change |
|---|---|
| `analytics-summary.scss` | tile: `background-color: var(--color-surface)`, drop the border, keep radius; value colors → `--color-success` / `--color-danger` |
| `search-filter.scss` | container: `background-color: var(--color-bg)`, `box-shadow: var(--shadow-neumorph-down)` (inset field look), drop border |
| `routine-card.scss` | feedback text → `var(--color-success)`; remove any flat backgrounds |
| `dashboard-home.scss` | `--loading/error/empty` states + header/summary colors → tokens |
| `admin-sidebar.scss` | background → `var(--color-bg)`; hover/active fills → `var(--color-surface)` / primary tints |

Keep each component SCSS under the 4 kB budget.

---

## 5. ROUTE FIX — RLHF DASHBOARD AT `/history`

### 5a. `src/app/app.routes.ts` (MODIFY)

The main RLHF dashboard **must** be reachable at `/history`; keep the old path as a redirect
for compatibility:

```ts
export const routes: Routes = [
  { path: 'history', component: DashboardHome },
  { path: 'admin-dashboard', redirectTo: '/history', pathMatch: 'full' },
  { path: '', redirectTo: '/history', pathMatch: 'full' },
];
```

### 5b. Sidebar unification — `admin-sidebar.*` (MODIFY)

- Bind the real link: `[routerLink]="item.link"` instead of the hard-coded
  `routerLink="/admin-dashboard"`; brand link → `routerLink="/history"`.
- Retarget nav items to the unified route:

```ts
readonly navItems: NavItem[] = [
  { label: 'History', icon: 'history', link: '/history' },
  { label: 'Routines', icon: 'workout', link: '/history' },
  { label: 'Nutrition', icon: 'nutrition', link: '/history' },
  { label: 'Schedule', icon: 'schedule', link: '/history' },
  { label: 'Profile', icon: 'profile', link: '/history' },
];
```

- Keep `routerLinkActive="admin-sidebar__link--active"`; fix `aria-current` to depend on the
  active state (`[attr.aria-current]="isActive() ? 'page' : null"` via a class-based check or
  `routerLinkActive` binding) so it is no longer hard-coded to "Dashboard".

### 5c. `history` icon — `icon.ts` + `icon.html` (MODIFY)

- Add `'history'` to the `IconName` union.
- Add a `@case ('history')` block (stroke-based, matches the existing 24×24 set):

```html
@case ('history') {
  <path d="M3 12a9 9 0 1 0 3-6.7L3 8"></path>
  <path d="M3 3v5h5"></path>
  <path d="M12 8v4l2.5 2.5"></path>
}
```

---

## 6. VERIFICATION — ROUTE & TESTS

- **Existing specs are unaffected** (`app.spec.ts` renders with `provideRouter([])`;
  `dashboard-home.spec.ts` creates the page directly).
- Add `src/app/app.routes.spec.ts`: assert `/history` resolves to `DashboardHome` and that
  `/` redirects to `/history` (router test via `provideRouter(routes)` + `Router` navigation).
- Add/keep a sidebar check if a spec exists (none today — optional).
- Run `npm run build` + `npm test` (all suites must stay green), then `ng serve`:
  - `/` → `/history` → dashboard renders with neumorphic cards/buttons, Montserrat.
  - `/admin-dashboard` → redirects to `/history`.
  - Sidebar "History" link is active on `/history`.

---

## 7. FILE MANIFEST

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `src/styles/design-tokens.scss` | Reusable tokens (§1) |
| **CREATE** | `src/app/app.routes.spec.ts` | Route-resolution tests |
| **MODIFY** | `src/index.html` | Montserrat Google Fonts (§2a) |
| **MODIFY** | `src/styles.scss` | `@use` tokens, Material typography, body font, neumorphic overrides (§2b, §3) |
| **MODIFY** | `src/app/app.routes.ts` | `/history` primary route + redirects (§5a) |
| **MODIFY** | `src/app/components/organisms/admin-sidebar/{ts,html,scss}` | Unified links, `history` nav, tokens (§5b) |
| **MODIFY** | `src/app/components/atoms/icon/{ts,html}` | `history` icon (§5c) |
| **MODIFY** | `src/app/features/dashboard/components/{analytics-summary,search-filter,routine-card}/*.scss` | Token swap + neumorphic cleanup (§4) |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.scss` | Token swap (§4) |

---

## 8. IMPLEMENTATION ORDER (Recommended for @Coder)

```
PHASE 1 — Tokens + Fonts
  ├─ Step 1.1: design-tokens.scss + @use in styles.scss
  ├─ Step 1.2: Montserrat <link> in index.html
  └─ Step 1.3: Material typography plain/brand-family → Montserrat; body font-family

PHASE 2 — Neumorphic overrides
  ├─ Step 2.1: mat-card + button overrides in styles.scss (§3a, §3b)
  ├─ Step 2.2: form-field inset override (§3c)
  └─ Step 2.3: component SCSS cleanup (§4)

PHASE 3 — Routing
  ├─ Step 3.1: app.routes.ts → /history + redirects
  ├─ Step 3.2: sidebar item.link binding + nav items + brand link
  └─ Step 3.3: 'history' icon (union + svg case)

PHASE 4 — Verification
  ├─ Step 4.1: app.routes.spec.ts
  ├─ Step 4.2: npm run build   (0 errors, budgets respected)
  ├─ Step 4.3: npm test        (all suites green)
  └─ Step 4.4: ng serve → check /history default, /admin-dashboard redirect, neumorphic UI
```

---

## 9. RISKS & NOTES

- **`!important` is intentional** for Material `box-shadow` overrides and confined to
  `styles.scss` — do not scatter it into components.
- **Neumorphism requires matching backdrops**: cards/buttons must sit on a surface that
  matches the shadow's light/dark tones; keep `--color-surface` for cards and `--color-bg`
  for page backdrop. Colored primary buttons remain readable.
- **Contrast**: keep `--color-text-low` only for tertiary labels (per WCAG 2.2 audit
  principles); body/card text uses `--color-text-high`/`--color-text-medium`.
- **Budget**: fonts are the main bundle add (~20–30 kB woff2); the 1 MB error budget is not
  threatened. Component SCSS stays under 4 kB.
- **Route change is backward compatible** via the `/admin-dashboard` redirect.

---

_Generated by @Architect. Hand off to @Coder with this file as the design-system contract._