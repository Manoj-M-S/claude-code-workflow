---
name: component-generator
description: >-
  Generate accessible, responsive, and highly polished React (Next.js) or Svelte
  components following the project's styling guidelines. Automatically creates
  corresponding unit test files using Vitest and Testing Library. Trigger this skill
  whenever the user asks to "create a component", "build a UI component", "add a button/modal/card",
  "write a component", or "create a svelte/react component".
---

# Component Generator

Create frontend components that are beautiful, responsive, fully accessible, and tested. Match the patterns already used in this project.

## Principles

1. **A11y First** — Correct ARIA roles and states, focus management, keyboard accessibility (Enter/Space to trigger, Escape to close), and explicit labels.
2. **Styling Conventions** — Padding, margin, and layout spacing must be in pixels (`px`). Font sizes must be in `rem`. Respect this bidirectional styling convention.
3. **No Duplicate Logic** — Search the codebase for existing components and utilities before creating new ones.
4. **State Coherence** — Keep state local unless shared state is required. Clean up subscriptions and event listeners.

## Workflow

### Step 1 — Analyze and Plan

Before writing code:
- Identify the framework (React/Next.js or Svelte) and language (TypeScript or JavaScript) from the project.
- Determine if it's presentational or stateful.
- Identify a11y requirements (focus traps, keyboard interactions, ARIA states).
- Search for existing components to reuse or extend.

### Step 2 — Implement

Write the component matching the project's existing conventions — file structure, naming, styling approach, prop patterns. Use `forwardRef` in React when the component wraps a native element. Use TypeScript with strict prop interfaces.

### Step 3 — Write Tests

Create a test file alongside the component (e.g., `Button.test.tsx`). Use Vitest + Testing Library. Cover:
- Renders correctly with default and custom props
- User interactions (click, keyboard) trigger expected behavior
- Disabled/loading states work correctly
- Accessibility: correct roles, labels, and ARIA attributes

### Step 4 — Verify

Run the project's quality gates:
1. Formatter check
2. Linter
3. Type-checker (`tsc --noEmit` or `svelte-check`)
4. Test suite (confirm the new test passes)
