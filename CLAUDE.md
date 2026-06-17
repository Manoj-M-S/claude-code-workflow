# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

# Project conventions

These are enforced by hooks in `.claude/hooks/`, but stating them here means
Claude follows them while writing code in the first place — so the hooks rarely
have to fire. (Hooks are the backstop; this file is the front door.)

> **Authoritative detail:** `.claude/references/conventions.md` is the single
> source of truth for these rules. The summary below is for quick reference.

## Units & Sizing

- **Font sizes in `rem`** — respects the user's browser font-size setting (accessibility). Never `px` for type.
- **Padding, margin, borders in `px`** (or design tokens that resolve to `px`) — fixed spacing shouldn't balloon when a user scales their root font size; `1px` hairline borders stay crisp.
- **Line-height unitless** (e.g. `1.5`, not `24px`) — scales proportionally with font size.
- **Media queries in `rem`/`em`** — breakpoints should respond to user font scaling.
- **Widths/heights: prefer `%`, `max-width`, `min-height`, `aspect-ratio`** over fixed dimensions — fixed `width`/`height` breaks responsiveness; use `max-width` + `aspect-ratio` for images.
- **No magic numbers** — every spacing/size value should come from the design scale (4px/8px grid) or a token.
- **Tailwind arbitrary values**:
  - For spacing: prefer `px` (e.g. `p-[16px]`, `m-[24px]`, `w-[320px]`).
  - For typography: prefer `rem` (e.g. `text-[1rem]`, `text-[1.25rem]`).

## Design Tokens & Theming

- **No raw hex colors** — all colors via CSS custom properties (`var(--color-primary)`), never `#3B82F6` inline.
- **No hardcoded spacing/typography values** — reference tokens (`var(--spacing-4)`, `var(--text-sm)`); if a value has no token, raise it as a design decision rather than inventing one.
- **Single source of truth** — tokens defined once (e.g. `globals.css` / Tailwind config), never duplicated per component.
- **Support dark mode via tokens**, not per-component overrides.

## CSS Architecture

- **Mobile-first** — base styles for small screens, `min-width` media queries layer up (`md:`, `lg:` in Tailwind).
- **Don't repeat utility class clusters** — if the same 6+ Tailwind utilities appear twice, extract a component or an `@layer components` class.
- **Keep specificity flat** — avoid `!important`, deep descendant selectors, and ID selectors; one class per component root (BEM or scoped styles).
- **Component styles are scoped** — a component's CSS never leaks out and never styles another component's internals.
- **Prefer modern layout** — Flexbox/Grid over floats, absolute positioning only when overlap is genuinely required (and document the stacking context/z-index).
- **Use a z-index scale** (tokens like `--z-modal: 50`) — never arbitrary `z-index: 9999`.

## Accessibility

- **Semantic HTML first** — `<button>` not `<div onClick>`, `<nav>`, `<main>`, proper heading hierarchy (one `<h1>`, no skipped levels).
- **Every image has `alt`** — descriptive for meaningful images, `alt=""` + `aria-hidden="true"` for decorative ones.
- **Keyboard operable** — all interactive elements focusable, visible focus styles (never `outline: none` without a replacement), logical tab order.
- **Color contrast** — 4.5:1 minimum for body text, 3:1 for large text/UI; never convey meaning by color alone.
- **Form inputs have labels** — real `<label>` elements, not just placeholders.
- **Respect `prefers-reduced-motion`** for animations.
- **Touch targets ≥ 44×44px.**

## Components & Code Structure

- **Single responsibility** — one component does one thing; split anything over ~200 lines or with multiple concerns.
- **Props over duplication** — variants via props/modifiers, never copy-pasted components.
- **No business logic in presentational components** — separate data fetching/state from rendering.
- **Colocate** — component, styles, tests, and stories live together.
- **No duplicate function names/logic across files** — define once, import everywhere.
- **TypeScript strict** — no `any`, no unexplained `as` assertions; props fully typed.

## Performance

- **Lazy-load below-the-fold images** (`loading="lazy"`) and set explicit `width`/`height` or `aspect-ratio` to prevent layout shift (CLS).
- **Modern image formats** — WebP/AVIF with `srcset` for responsive sizes.
- **Code-split routes and heavy components** (dynamic imports).
- **Avoid layout thrash** — animate only `transform` and `opacity`, never `top`/`left`/`width`.
- **Debounce/throttle** scroll, resize, and input handlers.
- **Memoize expensive computations**, but don't memoize prematurely.

## Quality Gates

- Code must pass Prettier, ESLint, and `tsc --noEmit` before a task is done.
- Inline SVGs for icons that need color control (via `currentColor`); PNG fallbacks get a TODO.
- Test at real breakpoints — verify rendering at minimum 375px (mobile) and 768px (tablet), not just desktop.
- No `console.log`s or dead code in committed files.

# Agent Skills & Workflows

## Orchestrator Agents (in `.claude/agents/`)

These agents **chain multiple skills** together in sequence. They are the
recommended way to run multi-step workflows.

- **Task Pipeline (`task-pipeline`)**: The full build-it workflow. Classifies the
  ticket (bug/feature/refactor/chore), then chains: plan → implement → quality gate.
  Invoke with "build this ticket", "task pipeline", "implement this", or "start work on".
- **PR Pipeline (`pr-pipeline`)**: The full ship-it workflow. Chains:
  requirement check → CSS/convention audit → quality-fixer-frontend → PR raise.
  Invoke with "ship it", "PR pipeline", or "full PR".
- **SEO Audit (`seo-audit`)**: Delegates meta tags, OpenGraph, structured data,
  heading hierarchy, sitemaps, and Next.js/Svelte metadata audits.
  *Subagent — invoked via delegation, not a `/` slash command.*
- **A11y Audit (`a11y-audit`)**: WCAG 2.1 AA specialist. Audits components/pages
  for semantic HTML, focus management, ARIA, contrast, and keyboard accessibility.
  *Subagent — invoked via delegation, not a `/` slash command.*

## Skills by Workflow Stage (in `.claude/skills/`)

### Planning & Design
- **Task Planner (`/task-planner`)**: JIRA ticket → structured implementation plan. Extracts requirements, analyzes codebase impact, creates task breakdown, test plan, risk assessment, and git strategy. Uses Atlassian MCP for ticket data, Figma MCP for design specs.
- **Grill Me (`/grill-me`)**: Pressure-tests feature specs before writing code. One question at a time, walks the design decision tree.
- **Domain Model (`/domain-model`)**: Establishes shared vocabulary via `GLOSSARY.md`. Scans codebase to align naming.
- **Frontend Design & UX (`/frontend-design`)**: Aesthetic direction, typography, layout, interactive polish, responsive execution, and UX quality checklists.

### Setup & Scaffolding
- **Project Setup (`/project-setup`)**: Bootstraps styling foundation — design tokens, Tailwind config, dark mode, fonts, cn() utility, base styles. Run once at project start.

### Implementation
- **Figma to Code (`/figma-to-code`)**: Reads Figma design via MCP → generates production-ready component code. Maps Figma specs to project tokens, flags gaps, creates tests.
- **Component Generator (`/component-generator`)**: Generates accessible, responsive, tested React/Svelte components matching project conventions.
- **CSS Design System (`/css-design-system`)**: Token architecture (primitive → semantic → component), Tailwind config, dark mode, audit checklist.
- **TDD Workflow (`/tdd`)**: Enforces Red-Green-Refactor. No code without a failing test first.

### Quality & Review
- **Quality Fixer Frontend (`/quality-fixer-frontend`)**: Runs lint, format, typecheck, tests, build. Auto-fixes what it can. Reports stub/blocked/approved.
- **QA Validate (`/qa-validate`)**: Acceptance testing via Playwright or Chrome MCP. Navigates the running app, tests each criterion, checks a11y, produces QA report. Optionally posts results to JIRA.
- **Improve Codebase Architecture (`/improve-codebase-architecture`)**: Identifies shallow modules and proposes deep-module refactors.

### PR & Release
- **PR Raise (`/pr-raise`)**: Gated pipeline — format, lint, typecheck, build must pass before creating PR.
- **PR Review (`/pr-review`)**: Reads beyond the diff. Classifies findings as Blocking/Should-fix/Nit/Question.

### Utilities
- **Prompt Optimizer (`/prompt-optimizer`)**: Transforms vague prompts into structured, high-performance prompts.

## MCP Servers (in `.claude/settings.json`)

The following MCP servers are configured for enhanced capabilities:

| Server | Purpose | Status |
| :--- | :--- | :--- |
| **Playwright** | Browser automation for QA testing (`/qa-validate`) | ✅ Configured |
| **Chrome DevTools** | Runtime debugging, console errors, performance profiling | ✅ Configured |
| **Context7** | Live, up-to-date library documentation (React, Next.js, Tailwind) | ✅ Configured |
| **Atlassian/JIRA** | Ticket management for `/task-planner` and `/qa-validate` | ⚙️ Setup: `claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse` |
| **Figma** | Design-to-code for `/figma-to-code` and `/project-setup` | ⚙️ Setup: `claude plugin install figma@claude-plugins-official` |

## Model Routing Strategy

Use `/model opusplan` for automatic routing, or switch manually:

| Task Type | Model | Examples |
| :--- | :--- | :--- |
| **Planning & Reasoning** | Opus | `/task-planner`, `/grill-me`, `/pr-review`, `/improve-codebase-architecture` |
| **Implementation & Execution** | Sonnet | `/figma-to-code`, `/component-generator`, `/tdd`, `/pr-raise`, `/qa-validate` |
| **Auditing** | Opus | `/css-design-system` audit, `a11y-audit`, `/domain-model` |
| **Lightweight / Bulk** | Haiku | Commit-message drafting, simple grep-and-replace, low-stakes summarisation |
