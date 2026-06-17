---
name: project-setup
description: >-
  Bootstrap a project's styling foundation — design tokens, Tailwind config,
  dark mode, fonts, cn() utility, and base styles. Detects the stack
  (Next.js/React, Tailwind v3/v4) and scaffolds everything from scratch.
  Optionally pulls tokens from Figma MCP. Triggers on: "setup project",
  "bootstrap styles", "initialize design tokens", "setup tailwind",
  "project setup", "scaffold design system", or "configure styles".
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

Create the token file based on the detected stack.

**For Tailwind v4** — Create `src/app/tokens.css` (or appropriate path):
- Import `tailwindcss`
- Define `@theme` block with colors (OKLCH), spacing (4px grid), typography (rem scale), radii, shadows, z-index scale, motion tokens
- Reference the `css-design-system` skill for the full three-tier token architecture

**For Tailwind v3** — Create/update `tailwind.config.ts`:
- Extend theme with semantic color names mapping to CSS variables
- Add font families, font sizes (from tokens), z-index scale, shadows, radii
- Create `src/styles/tokens.css` with `:root` CSS variable definitions

**For vanilla CSS** — Create `src/styles/tokens.css`:
- Full `:root` block with all primitive and semantic tokens
- `.dark` override block

### Step 3 — Set Up Dark Mode

Add `.dark` class overrides for all semantic color tokens:

```css
.dark {
  --color-bg-primary: var(--color-gray-950);
  --color-text-primary: var(--color-gray-50);
  --color-border-default: var(--color-gray-800);
  /* ... all semantic tokens ... */
}
```

If using Next.js, check if `next-themes` is installed. If not, suggest it.

### Step 4 — Configure Fonts

**Next.js** — Use `next/font`:
```ts
import { Inter } from 'next/font/google';
const inter = Inter({ subsets: ['latin'], variable: '--font-sans' });
```

**Other frameworks** — Add Google Fonts link with `display=swap`:
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

### Step 5 — Create cn() Utility

If React/Next.js and not already present:

1. Check if `clsx` and `tailwind-merge` are installed
2. If not, tell the user to install: `pnpm add clsx tailwind-merge`
3. Create `src/lib/utils.ts`:

```ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
```

### Step 6 — Add Base Styles

Add `@layer base` with:
- Box-sizing reset
- Body defaults (font family, size, line-height, colors from tokens)
- Heading styles (line-height, font-weight)
- `prefers-reduced-motion` reset for animations
- Scrollbar hiding utility in `@layer utilities`

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
