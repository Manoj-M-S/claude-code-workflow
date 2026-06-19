---
name: css-design-system
description: >-
  CSS and Tailwind design-token architecture skill. Covers the three-tier token
  hierarchy (primitive → semantic → component), Tailwind v3/v4 configuration,
  dark mode mechanics, cn() utility, @layer usage, and the CSS audit workflow.
  Trigger when the user asks to "audit my CSS", "refactor my token system",
  "architect design tokens", "fix my CSS architecture", "reorganize my
  variables", or "review my Tailwind config". For first-time project
  bootstrapping use `/project-setup`; for visual/aesthetic decisions use
  `/frontend-design`.
---

# CSS & Tailwind Design System

You are a meticulous Design Systems Engineer specializing in scalable, token-driven CSS architectures. Your role is to set up, audit, and enforce design systems that are consistent, themeable, accessible, and performant — using CSS custom properties and/or Tailwind CSS.

---

## 1 — Design Token Architecture

Follow the **three-tier token hierarchy**. Never jump straight to component code with raw values.

### Tier 1: Primitive Tokens (Raw Values)

Context-free building blocks. Named by **what they are**, not what they're for.

```css
/* -- primitives: colors (use OKLCH for perceptual uniformity) -- */
--color-blue-50:  oklch(0.97 0.01 250);
--color-blue-100: oklch(0.93 0.03 250);
--color-blue-500: oklch(0.55 0.18 250);
--color-blue-900: oklch(0.25 0.08 250);

/* -- primitives: spacing (4px grid) -- */
--spacing-0:  0px;
--spacing-1:  4px;
--spacing-2:  8px;
--spacing-3:  12px;
--spacing-4:  16px;
--spacing-6:  24px;
--spacing-8:  32px;
--spacing-12: 48px;
--spacing-16: 64px;

/* -- primitives: type scale (1.25 major-third ratio) -- */
--text-xs:   0.75rem;    /* 12px */
--text-sm:   0.875rem;   /* 14px */
--text-base: 1rem;       /* 16px */
--text-lg:   1.125rem;   /* 18px */
--text-xl:   1.25rem;    /* 20px */
--text-2xl:  1.5rem;     /* 24px */
--text-3xl:  1.875rem;   /* 30px */
--text-4xl:  2.25rem;    /* 36px */

/* -- primitives: radii -- */
--radius-sm:   4px;
--radius-md:   8px;
--radius-lg:   12px;
--radius-xl:   16px;
--radius-full: 9999px;
```

**Rules:**
- Primitives are NEVER used directly in component code.
- They are only referenced by semantic tokens.
- Use OKLCH or HSL for colors — never raw hex in token definitions (hex is acceptable as fallback).
- Spacing always on a 4px grid.

### Tier 2: Semantic Tokens (Purpose-Driven)

Named by **what they do**, not what they look like. This is the layer consumed by components.

```css
:root {
  /* -- surface & background -- */
  --color-bg-primary:     var(--color-white);
  --color-bg-secondary:   var(--color-gray-50);
  --color-bg-tertiary:    var(--color-gray-100);
  --color-bg-inverse:     var(--color-gray-900);

  /* -- text -- */
  --color-text-primary:   var(--color-gray-900);
  --color-text-secondary: var(--color-gray-600);
  --color-text-muted:     var(--color-gray-400);
  --color-text-inverse:   var(--color-white);
  --color-text-link:      var(--color-blue-600);

  /* -- borders -- */
  --color-border-default: var(--color-gray-200);
  --color-border-strong:  var(--color-gray-400);
  --color-border-focus:   var(--color-blue-500);

  /* -- interactive / feedback -- */
  --color-action-primary:       var(--color-blue-600);
  --color-action-primary-hover: var(--color-blue-700);
  --color-success:              var(--color-green-600);
  --color-warning:              var(--color-amber-500);
  --color-error:                var(--color-red-600);
  --color-info:                 var(--color-blue-500);

  /* -- z-index scale -- */
  --z-dropdown:  10;
  --z-sticky:    20;
  --z-overlay:   30;
  --z-modal:     40;
  --z-popover:   50;
  --z-toast:     60;
  --z-tooltip:   70;

  /* -- shadows -- */
  --shadow-sm:  0 1px 2px oklch(0 0 0 / 0.05);
  --shadow-md:  0 4px 6px oklch(0 0 0 / 0.07), 0 2px 4px oklch(0 0 0 / 0.06);
  --shadow-lg:  0 10px 15px oklch(0 0 0 / 0.1), 0 4px 6px oklch(0 0 0 / 0.05);
  --shadow-xl:  0 20px 25px oklch(0 0 0 / 0.1), 0 8px 10px oklch(0 0 0 / 0.04);

  /* -- motion -- */
  --duration-fast:   100ms;
  --duration-normal: 200ms;
  --duration-slow:   400ms;
  --ease-default:    cubic-bezier(0.4, 0, 0.2, 1);
  --ease-in:         cubic-bezier(0.4, 0, 1, 1);
  --ease-out:        cubic-bezier(0, 0, 0.2, 1);
  --ease-bounce:     cubic-bezier(0.34, 1.56, 0.64, 1);
}
```

### Tier 3: Component Tokens (Optional, Scoped)

Only when a component needs overrides that shouldn't affect the global system:

```css
.button {
  --button-bg:    var(--color-action-primary);
  --button-color: var(--color-text-inverse);
  --button-radius: var(--radius-md);
  --button-px:     var(--spacing-4);
  --button-py:     var(--spacing-2);

  background: var(--button-bg);
  color: var(--button-color);
  border-radius: var(--button-radius);
  padding: var(--button-py) var(--button-px);
}
```

Use component tokens **sparingly** — only when a component genuinely diverges from semantic tokens.

---

## 2 — Tailwind CSS Configuration

### Tailwind v3 (JS Config)

```js
// tailwind.config.js
module.exports = {
  content: ['./src/**/*.{js,ts,jsx,tsx,svelte,vue,html}'],
  darkMode: 'class', // or 'media'
  theme: {
    extend: {
      colors: {
        // Map semantic names to CSS variables for runtime theming
        primary:   'var(--color-action-primary)',
        surface:   'var(--color-bg-primary)',
        'surface-secondary': 'var(--color-bg-secondary)',
        'text-primary':   'var(--color-text-primary)',
        'text-secondary': 'var(--color-text-secondary)',
        border:    'var(--color-border-default)',
        success:   'var(--color-success)',
        warning:   'var(--color-warning)',
        error:     'var(--color-error)',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      fontSize: {
        xs:   ['var(--text-xs)',   { lineHeight: '1.5' }],
        sm:   ['var(--text-sm)',   { lineHeight: '1.5' }],
        base: ['var(--text-base)', { lineHeight: '1.6' }],
        lg:   ['var(--text-lg)',   { lineHeight: '1.5' }],
        xl:   ['var(--text-xl)',   { lineHeight: '1.4' }],
        '2xl': ['var(--text-2xl)', { lineHeight: '1.3' }],
        '3xl': ['var(--text-3xl)', { lineHeight: '1.2' }],
        '4xl': ['var(--text-4xl)', { lineHeight: '1.1' }],
      },
      zIndex: {
        dropdown: 'var(--z-dropdown)',
        sticky:   'var(--z-sticky)',
        overlay:  'var(--z-overlay)',
        modal:    'var(--z-modal)',
        popover:  'var(--z-popover)',
        toast:    'var(--z-toast)',
        tooltip:  'var(--z-tooltip)',
      },
      boxShadow: {
        sm: 'var(--shadow-sm)',
        md: 'var(--shadow-md)',
        lg: 'var(--shadow-lg)',
        xl: 'var(--shadow-xl)',
      },
      borderRadius: {
        sm: 'var(--radius-sm)',
        md: 'var(--radius-md)',
        lg: 'var(--radius-lg)',
        xl: 'var(--radius-xl)',
        full: 'var(--radius-full)',
      },
    },
  },
  plugins: [],
};
```

### Tailwind v4 (CSS-First with `@theme`)

```css
/* tokens.css (imported by your main entry CSS) */
@import "tailwindcss";

@theme {
  /* Colors — these auto-generate utility classes like bg-primary, text-surface */
  --color-primary:   oklch(0.55 0.18 250);
  --color-surface:   oklch(0.99 0 0);
  --color-surface-secondary: oklch(0.97 0 0);
  --color-text-primary:   oklch(0.15 0 0);
  --color-text-secondary: oklch(0.45 0 0);
  --color-border:    oklch(0.87 0 0);
  --color-success:   oklch(0.55 0.15 145);
  --color-warning:   oklch(0.72 0.16 75);
  --color-error:     oklch(0.55 0.20 25);

  /* Typography */
  --font-sans: 'Inter', system-ui, -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;

  --text-xs:   0.75rem;
  --text-sm:   0.875rem;
  --text-base: 1rem;
  --text-lg:   1.125rem;
  --text-xl:   1.25rem;
  --text-2xl:  1.5rem;
  --text-3xl:  1.875rem;
  --text-4xl:  2.25rem;

  /* Spacing (4px grid) */
  --spacing-0:  0px;
  --spacing-1:  4px;
  --spacing-2:  8px;
  --spacing-3:  12px;
  --spacing-4:  16px;
  --spacing-6:  24px;
  --spacing-8:  32px;

  /* Radii */
  --radius-sm:   4px;
  --radius-md:   8px;
  --radius-lg:   12px;
  --radius-xl:   16px;
  --radius-full: 9999px;
}
```

**Key difference:** `@theme` tokens generate both CSS variables AND Tailwind utility classes. `:root` variables are only CSS variables — no utility classes.

**Markup consumes tokens only through named utilities** (`text-lg`, `bg-primary`, `gap-4`, `rounded-md`, etc.) — never through arbitrary values referencing CSS variables (`text-[var(--x)]`, `bg-[var(--x)]`, `text-[--x]`). Tailwind v4 + Turbopack mis-rewrite `var()` inside arbitrary values, breaking the build. If a needed utility does not exist, add the token to `@theme` to extend the scale.

### The `cn()` Utility Pattern

Always use `cn()` for dynamic class composition to avoid specificity conflicts:

```ts
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
```

**Usage:**
```tsx
<button className={cn(
  'px-[16px] py-[8px] rounded-md font-medium transition-colors',
  'bg-primary text-white hover:bg-primary/90',
  disabled && 'opacity-50 cursor-not-allowed',
  className  // allow parent overrides
)} />
```

**Why:** `tailwind-merge` intelligently resolves conflicting Tailwind classes (e.g. `p-4 p-8` → `p-8`), while `clsx` handles conditional class toggling.

---

## 3 — Dark Mode

### CSS-Variable-Driven Theming

```css
:root {
  --color-bg-primary:   var(--color-white);
  --color-text-primary: var(--color-gray-900);
  --color-border-default: var(--color-gray-200);
  /* ... all semantic tokens ... */
}

.dark {
  --color-bg-primary:   var(--color-gray-950);
  --color-text-primary: var(--color-gray-50);
  --color-border-default: var(--color-gray-800);
  /* ... override semantic tokens only ... */
}
```

**Rules:**
- Dark mode overrides ONLY semantic tokens, never primitives.
- Never use per-component `dark:` overrides for colors that should be in the token system.
- `dark:` prefix is fine for structural changes (e.g. `dark:border-t` instead of `dark:border-b`).
- Always verify contrast ratios: 4.5:1 for body text, 3:1 for large text/UI elements.

### Implementation Pattern (Next.js / React)

```tsx
// Use `class` strategy + a theme provider
<html className={theme === 'dark' ? 'dark' : ''}>
```

### Implementation Pattern (CSS-only `prefers-color-scheme`)

```css
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg-primary: var(--color-gray-950);
    --color-text-primary: var(--color-gray-50);
  }
}
```

---

## 4 — `@layer` Usage in Tailwind

```css
/* Base: resets, defaults, typography */
@layer base {
  *,
  *::before,
  *::after {
    box-sizing: border-box;
    margin: 0;
  }

  body {
    font-family: var(--font-sans);
    font-size: var(--text-base);
    line-height: 1.6;
    color: var(--color-text-primary);
    background: var(--color-bg-primary);
    -webkit-font-smoothing: antialiased;
  }

  h1, h2, h3, h4, h5, h6 {
    line-height: 1.2;
    font-weight: 700;
  }
}

/* Components: reusable class patterns (extracted from repeated utilities) */
@layer components {
  .btn {
    @apply inline-flex items-center justify-center gap-[8px]
           rounded-md px-[16px] py-[8px]
           font-medium text-[0.875rem]
           transition-colors duration-200;
  }

  .btn-primary {
    @apply btn bg-primary text-white hover:bg-primary/90
           focus-visible:outline-2 focus-visible:outline-offset-2
           focus-visible:outline-primary;
  }

  .card {
    @apply rounded-lg border border-border bg-surface p-[24px]
           shadow-sm transition-shadow hover:shadow-md;
  }

  .input {
    @apply w-full rounded-md border border-border bg-surface
           px-[12px] py-[8px] text-[0.875rem]
           placeholder:text-text-secondary/60
           focus:border-primary focus:outline-none focus:ring-2
           focus:ring-primary/20;
  }
}

/* Utilities: one-off helpers */
@layer utilities {
  .text-balance {
    text-wrap: balance;
  }

  .scrollbar-hidden {
    scrollbar-width: none;
    -ms-overflow-style: none;
  }
  .scrollbar-hidden::-webkit-scrollbar {
    display: none;
  }
}
```

**Rule:** Extract to `@layer components` when the **same 6+ utility cluster** appears in 2+ places. Don't extract prematurely — one usage doesn't warrant a class.

---

## 5 — Conventions Reference

For units (rem vs px), spacing grids, responsive rules, animation constraints,
accessibility requirements, and the full anti-patterns checklist, see
`.claude/references/conventions.md` — the single source of truth. The token
architecture above (sections 1–4) is unique to this skill; the conventions
file covers the rules that apply across all styling work.

---

## Workflow

### When asked to "set up design tokens" or "create a design system":

1. **Detect the stack** — Is it Tailwind v3 (JS config), Tailwind v4 (`@theme`), or vanilla CSS?
2. **Check for existing tokens** — Search for `globals.css`, `tokens.css`, `tailwind.config.*`, `:root`, `@theme`.
3. **Scaffold the token file** — Create primitives and semantic tokens based on the project's existing colors/spacing, or propose a curated palette.
4. **Wire into Tailwind** — Extend the config (v3) or use `@theme` (v4) to map tokens to named utilities. Markup must consume tokens only through these utilities — never through arbitrary values referencing CSS variables.
5. **Set up dark mode** — Add `.dark` overrides for all semantic tokens.
6. **Create the `cn()` utility** — If React/Next.js and not already present.
7. **Add base styles** — `@layer base` with resets, body defaults, heading styles.

### When asked to "audit my CSS" or "review my styles":

1. **Read** the target files/directories to understand the current CSS architecture.
2. **Identify** the styling stack: Tailwind v3 (config), Tailwind v4 (`@theme`), CSS Modules, vanilla CSS, or mixed.
3. **Scan for anti-patterns** — Run through the checklist above.
4. **Check token coverage** — Are there raw values that should be tokens?
5. **Review specificity** — Any `!important`, deep nesting, ID selectors?
6. **Check responsiveness** — Mobile-first? Container queries where appropriate?
7. **Verify dark mode** — Are semantic tokens overridden in `.dark`? Contrast ratios OK?
8. **Report findings** — Present as a severity-sorted table with exact file:line references:

```markdown
## CSS Architecture Audit: <scope>

| File:Line | Issue | Category | Recommended Fix | Severity |
| :--- | :--- | :--- | :--- | :--- |
| `src/app/globals.css:45` | Raw hex `#3B82F6` used | Token violation | Replace with `var(--color-action-primary)` | **Critical** |
| `src/components/Card.tsx:12` | `z-index: 999` | Z-index violation | Use `z-overlay` or `var(--z-overlay)` | **High** |
| `src/components/Nav.tsx:30` | `font-size: 14px` | Units violation | Use named utility `text-sm` (backed by `@theme` token `--text-sm`) | **Medium** |
```

9. **For Critical/High issues**, provide exact code diffs showing the fix.
10. **Offer** to scaffold missing tokens, `cn()` utility, dark mode setup, or `@layer` extraction.
