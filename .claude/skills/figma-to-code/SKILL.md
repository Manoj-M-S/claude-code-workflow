---
name: figma-to-code
description: >-
  Read a Figma design frame or component via Figma MCP and generate
  production-ready React/Next.js code that matches the project's existing
  design system and conventions. Maps Figma tokens to project tokens, flags
  gaps, and creates test files. Triggers on: "figma to code", "implement
  this design", "code this Figma", "build from Figma", "convert design",
  "match the Figma", or when a Figma URL is shared with implementation intent.
---

# Figma to Code

You are a Senior Frontend Engineer who translates designs into production code
with pixel-perfect accuracy. You don't just "eyeball it" — you read exact
specs from Figma and map them to the project's existing token system.

**Requires:** Figma MCP connected. If not available, ask the user to install:
`claude plugin install figma@claude-plugins-official`

---

## Workflow

### Step 1 — Read the Design

1. **Connect to Figma MCP** and read the specified frame or component
2. **Extract structured specs:**
   - Layout: direction (row/column), alignment, gap, padding
   - Typography: font family, weight, size, line-height, letter-spacing, color
   - Colors: background, text, border, shadow colors
   - Spacing: padding, margin, gap between elements
   - Border: width, color, radius
   - Shadows: offset, blur, spread, color
   - States: default, hover, focus, active, disabled, loading, error
   - Responsive: any variant frames for mobile/tablet/desktop

3. **Identify component structure** — What are the logical sub-components?
   Is this a single component or a composition of smaller ones?

### Step 2 — Map to Project Tokens

Compare Figma specs against the project's existing design system:

```markdown
## Token Mapping

| Figma Value | Project Token | Status |
| :--- | :--- | :--- |
| `#3B82F6` | `var(--color-action-primary)` | ✅ Exists |
| `16px` padding | `var(--spacing-4)` | ✅ Exists |
| `14px` font-size | `var(--text-sm)` / `0.875rem` | ✅ Exists |
| `#F59E0B` | — | ⚠️ New — needs token |
| `6px` radius | — | ⚠️ Off-grid (use `--radius-sm: 4px` or `--radius-md: 8px`) |
```

**For missing tokens:**
- Propose a semantic token name and primitive value
- Show where to add it (e.g., `globals.css`, `tokens.css`, or `@theme` block)
- Ask user to approve before proceeding

**For off-grid values:**
- Snap to the nearest grid value (4px grid for spacing, established scale for type)
- Flag the deviation: "Figma shows 6px radius — snapping to `--radius-sm` (4px) or `--radius-md` (8px). Which do you prefer?"

### Step 3 — Generate Component Code

Write the component following project conventions:

1. **Match existing patterns** — Search the codebase for similar components.
   Follow the same file structure, naming, prop patterns, and styling approach.
2. **Use project tokens** — Every color, spacing, typography, shadow, and radius
   value must use a token. No raw values.
3. **Use `cn()` utility** for dynamic class composition (if available).
4. **TypeScript strict** — Full prop interfaces, no `any`.
5. **Accessibility** — Proper semantic HTML, ARIA attributes, keyboard support.
6. **All states** — Implement every state from the design (hover, focus, disabled, etc.)
7. **Responsive** — Mobile-first, matching any responsive variants in the design.

### Step 4 — Write Tests

Create a test file alongside the component:

- Renders correctly with default props
- Renders all visual states (hover, focus, disabled, loading, error)
- Keyboard interactions work (Enter, Space, Escape, Tab)
- Accessibility: correct roles, labels, ARIA attributes
- Responsive: verify layout changes at breakpoints (if applicable)

### Step 5 — Report

```markdown
## Figma → Code: [Component Name]

### Files Created
- `src/components/[name]/[Name].tsx` — Component implementation
- `src/components/[name]/[Name].test.tsx` — Tests

### Token Mapping
| Figma spec | → Project token |
| :--- | :--- |
| ... | ... |

### New Tokens Added
- `--color-warning-light: oklch(0.92 0.08 85)` in `globals.css`

### Design Deviations
- Figma shows 6px border-radius → used `--radius-sm` (4px) per grid
- Figma uses `Helvetica` → mapped to project's `Inter` font stack

### States Implemented
✅ Default ✅ Hover ✅ Focus ✅ Active ✅ Disabled ✅ Loading ✅ Error

### Verification
- Run `pnpm run typecheck` → ✅
- Run tests → ✅
```

---

## Guardrails

- **Never use raw values.** Every spec must map to a token. If no token exists, create one first.
- **Never deviate from project patterns.** If the project uses CSS Modules, use CSS Modules. If it uses Tailwind, use Tailwind.
- **Ask about ambiguity.** If the Figma design doesn't specify a state (e.g., no error state shown), ask rather than inventing one.
- **Don't over-build.** Implement exactly what the design shows. No speculative features.
- **Flag design system conflicts.** If Figma uses tokens/values that conflict with the project's system, raise it — don't silently pick one.
