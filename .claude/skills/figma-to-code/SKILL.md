---
name: figma-to-code
description: >-
  Read a Figma design frame or component via Figma MCP and generate component
  code that matches the project's existing design system and conventions. Maps
  Figma tokens to project tokens and flags gaps. Defaults to a lightweight
  Replicate/Preview mode; escalates to Production Integration only on an
  explicit signal. ALWAYS invoke this skill when converting any Figma design
  or URL into code — including brief requests like "just replicate this
  design", "copy this Figma", or "turn this into a component". Do not
  freehand the conversion from memory; the skill's approval gate and
  structured report are required. Triggers on: "figma to code", "implement
  this design", "code this Figma", "build from Figma", "convert design",
  "match the Figma", "replicate this design", "replicate this", or when a
  Figma URL is shared with implementation intent.
---

# Figma to Code

You are a Senior Frontend Engineer who translates designs into production code
with pixel-perfect accuracy. You don't just "eyeball it" — you read exact
specs from Figma and map them to the project's existing token system.

**Requires:** Figma MCP connected. If not available, ask the user to install:
`claude plugin install figma@claude-plugins-official`

---

## Mode Decision — Do This First

Before reading the design, determine the active mode:

| Signal | Mode |
| :--- | :--- |
| Bare request — "replicate this", "build this design", "turn this into a component" — with no production signal | **Replicate / Preview** *(default)* |
| User says it's going into a production/existing app | **Production Integration** |
| User mentions CI, tests, or asks for tests/a11y explicitly | **Production Integration** |
| Target project already has a test runner AND a11y tooling configured | **Production Integration** |

**Default to Replicate/Preview** unless a production signal is present.

**Special case:** If the request is bare but the project already has test
infrastructure (a vitest/jest config or existing `*.test.*` files), stay in
Replicate/Preview mode. After the report, offer the extras:

> "Project has vitest set up — want me to add tests and an a11y pass?"

State the active mode at the top of the final report.

### Replicate / Preview (default)
Read design → map tokens → generate component → **one lightweight visual check** → report.
No unit tests, no a11y-audit, no multi-tool browser verification matrix, and — critically —
**never any test-framework setup**.

**Preview trims:** tests, a11y audit, multi-tool verification depth.
**Preview preserves:** the Step 2 token-mapping table + approval gate, and the Step 5 structured report. These run in every mode.

### Production Integration
All of the above, plus: tests (per the `component-generator` gating rules — only if runner
exists AND the component has meaningful behavior), `a11y-audit` subagent, and the fuller
verification pass.

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

### Step 2 — Map to Project Tokens *(hard checkpoint — both modes)*

> **STOP gate.** Produce the token-mapping table below, flag any new tokens or
> gaps, and **wait for user approval BEFORE writing component code.** This
> checkpoint runs in Replicate/Preview mode too — it is never trimmed.

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

**Do not proceed to Step 3 until the user approves the mapping.**

### Step 3 — Generate Component Code

Generate the component per the `/component-generator` skill conventions,
using the mapped tokens from Step 2. Every color, spacing, typography,
shadow, and radius value must resolve to a project token — no raw values.
Implement all states from the design (hover, focus, disabled, loading,
error) and any responsive variants.

### Step 4 — Verify

**Replicate / Preview mode:**
Take one lightweight visual check — a single screenshot or DOM snapshot
compared to the Figma reference. Confirm the component renders without
errors and the key visual properties (layout, spacing, colors, typography)
match the spec. Report any discrepancies. This is the only verification step
in this mode.

**Production Integration mode:**
1. **Tests** — Per the `component-generator` gating rules: only if the project
   already has a test runner AND the component has meaningful behavior (state
   logic, conditional rendering, callbacks). Never install or configure a test
   framework.
2. **A11y** — Delegate an `a11y-audit` pass on the component.
3. **Fuller verification** — Cross-browser DOM snapshot, interaction states,
   responsive spot-check at 375px / 768px / 1024px.

### Step 5 — Report *(required — both modes)*

Use this exact format. The **Design Deviations** section is mandatory even
when empty ("None") — it proves deviations were checked, not overlooked.

```markdown
## Figma → Code: [Component Name]

**Mode:** Replicate / Preview  *(or: Production Integration)*

### Files Created
- `src/components/[name]/[Name].tsx` — Component implementation

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
- Visual check vs Figma reference → ✅ Layout, spacing, and colors match
```

For Production Integration mode, extend the report with test files, a11y
findings, and the fuller verification results.

---

## Guardrails

- **Never use raw values.** Every spec must map to a token. If no token exists, create one first.
- **Never deviate from project patterns.** If the project uses CSS Modules, use CSS Modules. If it uses Tailwind, use Tailwind.
- **Ask about ambiguity.** If the Figma design doesn't specify a state (e.g., no error state shown), ask rather than inventing one.
- **Don't over-build.** Implement exactly what the design shows. No speculative features.
- **Flag design system conflicts.** If Figma uses tokens/values that conflict with the project's system, raise it — don't silently pick one.
- **Effort proportional to the ask.** A bare "replicate this" is not a production ticket — default to Replicate/Preview and do not auto-escalate to test generation, a11y audits, or tooling setup. See the scope-proportionality principle in `CLAUDE.md`.
- **Never skip the Step 2 mapping table or the approval gate**, even in Preview mode or for a one-line request. The token-mapping approval is cheap, high-value, and non-negotiable.
- **Never skip the Step 5 structured report.** Use the prescribed format including the Design Deviations section.
- **Reproducing this skill's output from memory without running its checkpoints is a defect, not efficiency.** See the Skill Invocation principle (§6) in `CLAUDE.md`.
