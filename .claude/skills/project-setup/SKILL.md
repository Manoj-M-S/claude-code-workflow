---
name: project-setup
description: >-
  One-time project bootstrap for the styling foundation — design tokens,
  Tailwind config, dark mode, fonts, cn() utility, and base styles. Run once
  at the start of a new project. Triggers on: "setup project", "bootstrap
  styles", "initialize design tokens", "project setup", "scaffold the
  foundation", or "first-time setup". For auditing or refactoring an
  existing token system use `/css-design-system`; for visual/aesthetic
  decisions use `/frontend-design`.
---

# Project Setup

You are a Design Systems Engineer bootstrapping a new project's styling
foundation. Your goal is to set up a complete, production-ready design token
system so the team never has to think about raw values again.

Run this **once at project start**. It saves hours and ensures consistency.

---

## Workflow

### Step 1 — Detect the Stack

Read `package.json`, config files, and project structure to determine:

| Question | How to Detect |
| :--- | :--- |
| Framework | `next` in deps → Next.js; `react` → React; `svelte` → SvelteKit |
| Tailwind version | `tailwindcss` version in deps; v4 if `@theme` in CSS files |
| CSS approach | Check for CSS Modules, styled-components, vanilla CSS, or Tailwind-only |
| Package manager | `pnpm-lock.yaml` → pnpm; `yarn.lock` → yarn; `bun.lock` → bun; else npm |
| TypeScript | `tsconfig.json` present |
| Existing tokens | Search for `:root`, `@theme`, `globals.css`, `tokens.css` |

Report findings before proceeding:

```markdown
## Stack Detected
- **Framework:** Next.js 15 (App Router)
- **Tailwind:** v4 (CSS-first with @theme)
- **Package Manager:** pnpm
- **TypeScript:** Yes
- **Existing tokens:** None — clean setup
```

### Step 2 — Scaffold Design Tokens

Follow the `/css-design-system` skill's three-tier token architecture
(primitive → semantic → component). Adapt the token file to the detected
stack:

- **Tailwind v4** — `@theme` block in `globals.css` (or a dedicated `tokens.css` imported by it). Theme-able tokens use `@theme inline` referencing custom properties on `:root`/`.dark`.
- **Tailwind v3** — `tailwind.config.ts` extending theme with CSS variable references + a `:root` token file
- **Vanilla CSS** — full `:root` block with primitives and semantic tokens

All values must follow `.claude/references/conventions.md` (4px grid,
rem for type, px for spacing, OKLCH/HSL colors, z-index scale).

**Markup consumes tokens only through named utilities** (`text-lg`, `bg-primary`,
`gap-4`, `rounded-md`, etc.) — never through arbitrary values referencing CSS
variables. Define all tokens in `@theme` so the named utilities exist.

### Step 3 — Set Up Dark Mode

Add `.dark` overrides for all semantic color tokens. Override semantics
only — never primitives. If using Next.js, check if `next-themes` is
installed; if not, suggest it.

### Step 4 — Configure Fonts

- **Next.js** — Use `next/font` with `variable` option for the CSS custom property.
- **Other frameworks** — Add a Google Fonts `<link>` with `display=swap`.

### Step 5 — Create cn() Utility

If React/Next.js and `clsx` + `tailwind-merge` are not already present,
tell the user to install them and create `src/lib/utils.ts` with the
`cn()` function (see `/css-design-system` for the pattern).

### Step 6 — Add Base Styles

Add `@layer base` with box-sizing reset, body defaults (font, size,
line-height, colors from tokens), heading styles, and a
`prefers-reduced-motion` reset. Add a scrollbar-hiding utility in
`@layer utilities`.

### Step 7 — Pull from Figma (optional)

If Figma MCP is connected:

1. Run `create_design_system_rules` to generate persistent design rules
2. Read Figma variables/tokens
3. Map Figma tokens to the project's token system
4. Flag any Figma values that don't fit the 4px grid or established scales

### Step 8 — Generate Documentation

Create `DESIGN_SYSTEM.md` in the project root:

```markdown
# Design System

## Colors
| Token | Light | Dark | Usage |
| :--- | :--- | :--- | :--- |
| `--color-bg-primary` | white | gray-950 | Page background |
| `--color-text-primary` | gray-900 | gray-50 | Body text |
...

## Spacing (4px grid)
| Token | Value | Common use |
| :--- | :--- | :--- |
| `--spacing-1` | 4px | Icon gaps |
| `--spacing-2` | 8px | Inline gaps |
...

## Typography
...

## Z-Index Scale
...
```

---

## Output Checklist

When complete, report what was created:

```markdown
## ✅ Project Setup Complete

### Files Created
- `src/app/tokens.css` — Design tokens (primitives + semantic + dark mode)
- `src/lib/utils.ts` — cn() utility
- `DESIGN_SYSTEM.md` — Token documentation

### Files Modified
- `src/app/globals.css` — Added @layer base/components/utilities
- `src/app/layout.tsx` — Added font variable class

### Next Steps
- [ ] Install missing deps: `pnpm add clsx tailwind-merge`
- [ ] Review token values and adjust to your brand
- [ ] Connect Figma MCP to pull exact design tokens
```

---

## Guardrails

- **Don't override existing tokens** without asking. If tokens already exist, show what you'd change and get approval.
- **Don't install packages.** List what needs installing and let the user run it.
- **Use the css-design-system skill** as the reference for token architecture — don't deviate from the three-tier pattern.
- **Scale to the project.** A small prototype doesn't need 50 tokens. A production app does.
