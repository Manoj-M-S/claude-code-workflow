---
name: component-generator
description: >-
  Generate accessible, responsive, and highly polished React (Next.js) or Svelte
  components following the project's styling guidelines. Writes tests alongside
  the component when the project already has a test runner AND the component has
  meaningful behavior. Trigger this skill whenever the user asks to "create a
  component", "build a UI component", "add a button/modal/card", "write a
  component", or "create a svelte/react component".
---

# Component Generator

Create frontend components that are beautiful, responsive, fully accessible, and tested. Match the patterns already used in this project.

## Principles

1. **A11y First** — Correct ARIA roles and states, focus management, keyboard accessibility (Enter/Space to trigger, Escape to close), and explicit labels.
2. **Styling Conventions** — Padding, margin, and layout spacing must be in pixels (`px`). Font sizes must be in `rem`. Respect this bidirectional styling convention.
3. **Named Utilities Only** — Style via named Tailwind utilities backed by `@theme` tokens (`text-lg`, `bg-surface`, `gap-4`, `rounded-md`). Never use arbitrary values that reference CSS variables (`text-[var(--x)]`, `bg-[var(--x)]`, `text-[--x]`) — they break under Tailwind v4 + Turbopack.
4. **No Duplicate Logic** — Search the codebase for existing components and utilities before creating new ones.
5. **State Coherence** — Keep state local unless shared state is required. Clean up subscriptions and event listeners.

## Workflow

### Step 1 — Analyze and Plan

Before writing code:
- Identify the framework (React/Next.js or Svelte) and language (TypeScript or JavaScript) from the project.
- Determine if it's presentational or stateful.
- Identify a11y requirements (focus traps, keyboard interactions, ARIA states).
- Search for existing components to reuse or extend.
- **Assess test warrant:** does this component have meaningful behavior — state logic, conditional rendering, callbacks with conditions, data transformation? Record the answer; it gates Step 3.

### Step 2 — Implement

Write the component matching the project's existing conventions — file structure, naming, styling approach, prop patterns. Use `forwardRef` in React when the component wraps a native element. Use TypeScript with strict prop interfaces.

### Step 3 — Write Tests (conditional)

**Only write tests when BOTH conditions are true:**

1. **Runner exists** — the project has a configured test runner. Detect via:
   - `package.json` scripts (a `test` or `vitest`/`jest` script)
   - A `vitest.config.*` or `jest.config.*` file
   - Existing `*.test.*` or `*.spec.*` files in the codebase

2. **Meaningful behavior** — the component has state logic, conditional rendering,
   user-triggered callbacks with conditions, or data transformation. Pure display
   components (no state, no events, just prop → markup) do not need tests.

**If both conditions are met:** Create a test file alongside the component
(e.g., `Button.test.tsx`). Use Vitest + Testing Library. Cover:
- Renders correctly with default and custom props
- User interactions (click, keyboard) trigger expected behavior
- Disabled/loading states work correctly
- Accessibility: correct roles, labels, and ARIA attributes

**If the runner is missing but tests are warranted:** Do NOT install, pin,
or downgrade a test framework. Surface a one-line choice instead:

> "No test setup detected — add vitest + React Testing Library, or skip tests for now?"

Wait for the user's answer before proceeding. Do not begin a
dependency-resolution cascade.

**If the component is purely presentational:** Skip tests entirely. Mention
this in Step 4's output.

### Step 4 — Verify

Run the project's quality gates:
1. Formatter check
2. Linter
3. Type-checker (`tsc --noEmit` or `svelte-check`)
4. Test suite — only if tests were written in Step 3

---

## Guardrails

- **Never install or configure a test framework.** If no runner exists and tests are warranted, ask first — don't start a dependency-resolution cascade.
- **Purely presentational components don't need tests.** No state, no events, no behavior → no test file.
- **Effort proportional to the ask.** Don't add tests, audits, or tooling the request did not call for and the project does not already have. See the scope-proportionality principle in `CLAUDE.md`.
