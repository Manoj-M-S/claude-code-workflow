# Framework Architecture — Next.js 16 / React 19 / TypeScript

**Applies to:** Next.js 16 App Router + React 19 projects. If the project is
Svelte, Vue, Remix, or Pages Router, **skip this file entirely** — nothing here
transfers. Framework-agnostic rules live in `.claude/references/conventions.md`.

This file is the authoritative reference for framework-level decisions: what
renders where, what gets cached, where the client boundary sits, and what
the browser is allowed to execute. `conventions.md` owns styling and markup;
this file owns architecture.

**Detect before applying.** Read `package.json` and confirm `next` is 16.x and
`react` is 19.x. On Next.js ≤ 15 the caching defaults are inverted (implicit
`force-cache`) and most of §3 is wrong. Say so rather than guessing.

---

## 1 — Non-negotiables

These produce broken, insecure, or data-leaking output. Everything else in
this file is a default that can be argued with.

- **Await dynamic request APIs.** `cookies()`, `headers()`, `params`, and
  `searchParams` are Promises in Next.js 16. `params.id` throws; `(await params).id`
  works. Synchronous access fails at build.
- **Never cache per-user data in a shared cache.** A `'use cache'` scope cannot
  call `cookies()`, `headers()`, or read `searchParams` at all — Next.js throws
  `next-request-in-use-cache`, and the restriction follows the call stack into
  any helper the cached function calls. **The preferred fix is to read the
  runtime value *outside* the cached scope and pass it in as an argument**
  (arguments are part of the cache key, so entries stay correctly separated).
  `'use cache: private'` exists for the rare case — compliance rules, or code
  that genuinely cannot be refactored — not as the routine answer.
  Note this failure can pass `next build` and only surface under `next start`
  on a dynamically rendered route.
- **Secrets never reach the client bundle.** Only `NEXT_PUBLIC_`-prefixed env
  vars are inlined at build. A secret in a `NEXT_PUBLIC_` var ships to every
  visitor. Importing server-only code into a Client Component does the same.
- **Metadata comes from the Metadata API.** `next/head`, `_app.tsx`, and
  `_document.tsx` are Pages Router constructs the App Router does not execute —
  they emit nothing, silently.
- **TypeScript `strict` from the first commit.** Enabling it later surfaces
  hundreds of latent null/any errors at once.

---

## 2 — Rendering strategy

| Need | Strategy | Mechanism |
| :--- | :--- | :--- |
| Same for all users, changes rarely | Static | `'use cache'` on the segment; served from edge |
| Static shell + a few dynamic holes | PPR | Shell prerendered, holes stream at request |
| Per-request / per-user data | Dynamic | No `'use cache'` — the Next.js 16 default |
| Slow data, fast first paint | Streaming | `<Suspense>` flushes the shell, streams chunks |
| Rich client interactivity | Client Component | `'use client'` — ships JS, hydrates |

**Default when unsure:** a Server Component with no cache (dynamic), adding
`'use cache'` only where the data is provably shareable and stable. Next.js 16
is dynamic-by-default; over-caching (a leak or unexpected staleness) is the
expensive failure, under-caching is just slower.

**Keep `'use client'` at the leaves.** The directive marks a module *and
everything it imports* as client code. Placing it on a layout or page drags the
whole subtree to the browser. Push it down to the interactive leaf — a button,
a form, a chart — and the rest ships zero JS.

**Keep Server Actions in dedicated `'use server'` files** (e.g. `actions/user.ts`),
not inline in component bodies. It makes the network boundary visible and
prevents server-only imports from being pulled into client bundles.

---

## 3 — Caching

| Data | Directive | Revalidation |
| :--- | :--- | :--- |
| Public, stable (marketing, docs) | `'use cache'` + `cacheLife('days'/'max')` | Time, or `cacheTag` + `revalidateTag` |
| Public, frequently changing (prices, feed) | `'use cache'` + `cacheLife('minutes')` | On write via `revalidateTag` |
| Per-user, cacheable within a request | `'use cache: private'` (last resort — prefer passing the value as an argument) | Scoped to the user |
| Shared across serverless instances | `'use cache: remote'` | Platform cache handler; network roundtrip + platform fees |
| Per-request / auth / cookies | None — leave dynamic | n/a |

- **Always pair `'use cache'` with an explicit `cacheLife()` profile.** Omitting
  it silently applies the `default` profile — stale 5 min (client), revalidate
  15 min (server), never expires — which is rarely what you meant. Built-in
  profiles include `'hours'`, `'days'`, `'max'`, and `'default'`. Nesting a
  short-lived `use cache` inside one with no explicit `cacheLife` fails the
  build during prerendering.
- `fetch` is **not** implicitly cached in Next.js 16. Caching is opt-in and
  visible in code.
- Verify with `next build` — it labels each route static or dynamic. Test under
  `next start`, not `next dev`; dev caching behaves differently.

> **Verified against Next.js 16.3.4 docs (2026-09-03):** `'use cache: private'`,
> `'use cache: remote'`, the `default` profile timings, and the
> `next-request-in-use-cache` error are all current. Still re-check against the
> installed version — Cache Components shipped in 16.0 and the surface moves.

---

## 4 — React 19

- **`useActionState` / `useFormStatus` for mutations.** They track pending state,
  errors, and optimistic updates inside React's reconciler. Hand-rolled
  `useState` loading flags produce race conditions on rapid resubmits.
- **Validate on the server regardless of client validation.** Client validation
  is UX; the network is the trust boundary. A `<form action={serverAction}>` also
  degrades gracefully — it submits natively before hydration completes.
- **`useTransition` / `useDeferredValue`, not `setTimeout` debouncing, for
  render-driving state.** Debounce adds a fixed delay even on an idle CPU;
  transitions render at low priority and interrupt on newer input. Debounce and
  throttle remain correct for *side effects* (network calls, analytics).
- **`use(Promise)` for client-side async reads**, integrated with Suspense.
  In Server Components use plain `async`/`await` — `use` is unnecessary there.
- **Components must be pure.** No side effects or external mutation during
  render. React 19 pauses, retries, and speculatively re-renders; impurity shows
  up as hydration mismatches and state desync.

### React Compiler — check before advising

React Compiler 1.0 is **opt-in**, not on by default. It is active only when
`reactCompiler: true` is set in `next.config.ts`.

- **Compiler enabled:** stop hand-writing `useMemo`/`useCallback`/`memo` for
  render performance — it memoizes more granularly than hand code. Keep them as
  escape hatches only where a *reference identity* is consumed outside React
  (chart/canvas libraries, effect dependency arrays).
- **Compiler not enabled:** manual memoization is still the mechanism. Do not
  strip it out.

Read the config before recommending either. "The compiler handles it" is wrong
advice on a project that never turned it on.

---

## 5 — TypeScript

- `strict: true` — non-negotiable, from commit one.
- `noUncheckedIndexedAccess: true` — array and index-signature reads return
  `T | undefined`, forcing the check that prevents "cannot read properties of
  undefined" at runtime.
- `exactOptionalPropertyTypes: true` — distinguishes an absent property from one
  explicitly set to `undefined`.
- Exception: an incremental migration of a legacy untyped codebase, where these
  are enabled file-by-file rather than repo-wide.

---

## 6 — Bundling

- **Avoid barrel files (`index.ts` re-exports) on hot paths.** Bundlers do not
  tree-shake in dev, so one icon imported through a barrel loads the whole
  library's module graph. Import from the module entrypoint instead.
- **Register third-party barrels in `optimizePackageImports`** in
  `next.config.ts`. Next.js already optimizes some packages (`lucide-react`,
  `date-fns`, `@headlessui/react`) by default — check before adding.
- A small internal barrel of a few modules with `"sideEffects": false` is fine;
  this rule targets large library barrels and hot paths.

---

## 7 — Security

- **Strict CSP with a per-request nonce, set up before launch.** Middleware
  generates a cryptographically random nonce per request and sets
  `script-src 'nonce-{RANDOM}' 'strict-dynamic'`. `'strict-dynamic'` makes the
  browser ignore domain allowlists and trust only nonced scripts plus what they
  load. Never `'unsafe-inline'` on `script-src` — it defeats the entire policy.
- **A nonce-based CSP requires dynamic rendering** (there is no request at build
  time). This constrains rendering choices, which is exactly why it has to be
  decided early rather than retrofitted. A fully static site uses hash-based CSP
  instead.
- **Also set:** `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`,
  `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`,
  and `frame-ancestors`.
- **Verify:** `curl -I <url>` shows the header with a nonce; the console reports
  no violations; an injected `<script>` is blocked.

---

## 8 — Metadata & SEO

- Root `metadata` export for defaults, `generateMetadata` for per-route values —
  both server-resolved, so crawlers see them without executing JS.
- Every route needs a **unique** title and description plus a canonical URL via
  `alternates.canonical`.
- Authenticated or internal routes set `robots: { index: false }`.
- OpenGraph images at **1200×630** (1.91:1); off-ratio images get cropped or
  dropped by scrapers.

---

## 9 — Observability

- **`error.tsx` / `global-error.tsx`** boundaries per segment; until they exist,
  production failures are invisible.
- **Field data (RUM) is the ground truth for Core Web Vitals, not Lighthouse.**
  A Lighthouse run loads the page without interacting, so it produces **no INP**
  at all — it substitutes Total Blocking Time, a load-time proxy. A page can
  score 100 in the lab and still fail INP in the field.
- **Gate CI on** bundle-size deltas and lab regressions. **Monitor, don't gate
  on,** field LCP/INP/CLS — CI cannot measure interaction it never performs.
- Current thresholds (75th percentile, field): **LCP ≤ 2.5s · INP ≤ 200ms · CLS ≤ 0.1.**
  INP replaced FID in March 2024; FID is dead.

---

## 10 — Greenfield setup order

Ordered by dependency — each step constrains the next. The right-hand column is
the argument for the ordering: what it costs to defer.

| # | Decision | Cost of doing it later |
| :--- | :--- | :--- |
| 1 | TS strictness + lint/format baseline | **Extremely high** — enabling `strict` on an existing codebase surfaces hundreds of errors at once |
| 2 | Design token architecture (primitive → semantic → component) | **High** — find-and-replace primitive values across every component |
| 3 | Figma → token extraction format (DTCG JSON) | **Moderate** — isolated if CSS variable names stay stable |
| 4 | Tailwind v4 `@theme` namespace mapping | **High** — renaming tokens to fit namespaces is a codebase-wide class rename |
| 5 | Dark mode / multi-theme at the token layer | **Highest in this list** — every hardcoded color must be found and replaced |
| 6 | Font loading + metric-override CLS strategy | **Low-moderate** — but re-verifying zero-shift needs visual regression |
| 7 | Layout primitives + container-query strategy | **High** — converting `@media` components to `@container` means re-testing every usage |
| 8 | Data fetching, caching, and Suspense boundaries | **High** — retrofitting means re-architecting trees around Suspense and re-auditing every fetch for leak risk |
| 9 | CSP + security headers | **Extremely high** — you must discover every inline script and third-party origin already shipped, and teams routinely cave to `'unsafe-inline'` under launch pressure |
| 10 | A11y baseline (lint, focus convention, axe in CI) | **High** — focus and labeling retrofits touch every interactive component |
| 11 | SEO / metadata architecture | **Low-moderate** — but a missing-canonical indexing window is slow to recover |
| 12 | Performance budgets + CI gates | **High** — without an early gate, "fix performance" becomes open-ended |
| 13 | Error boundaries, logging, monitoring | **Moderate** — cheapest to add, but production failures are invisible until it exists |

`/project-setup` currently covers steps 2–6 (the styling foundation). Steps 1
and 7–13 are not automated by any skill in this workflow — raise them as
decisions rather than silently skipping them on a greenfield project.

---

## Automate, don't memorize

Rules a tool enforces do not belong in a prompt. Each entry names what fails
without it.

| Tool | Enforces | Without it |
| :--- | :--- | :--- |
| `eslint-plugin-jsx-a11y` | alt text, label association, role misuse | The common automated a11y failures ship |
| `eslint-plugin-react-hooks` (recommended) | Rules of Hooks + Compiler diagnostics | Components the compiler silently skips |
| `tsc --noEmit` in CI | Type safety | Type errors reach production |
| `prettier-plugin-tailwindcss` | Class ordering | Unmergeable class-order churn |
| `optimizePackageImports` | Barrel import rewriting | Bloated dev chunks, slow cold starts |
| axe (jest-axe / Playwright) | Machine-detectable a11y regressions | Regressions on the detectable subset |
| Lighthouse CI / size-limit | Bundle + lab budgets | Unnoticed size and perf regressions |
