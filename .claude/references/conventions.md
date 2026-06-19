# Project Conventions — Single Source of Truth

This file is the authoritative reference for low-level frontend conventions.
Skills, hooks, and `CLAUDE.md` all point here; the hooks enforce these rules
automatically. When in doubt, this file wins.

---

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
  - **Arbitrary values that reference a CSS variable are banned** — `text-[var(--x)]`, `text-[length:var(--x)]`, `text-[color:var(--x)]`, `gap-[var(--gap)]`, `bg-[var(--x)]`, and the v4 shorthand `text-[--x]` are all prohibited. Tailwind v4 + Turbopack mis-rewrite `var()` inside arbitrary values (the variable name is dropped, producing broken CSS like `color: var()`) and break the dev server. **Design tokens are defined in the `@theme` block in `globals.css` and consumed only through named utilities** — `text-lg`, `text-heading`, `bg-surface`, `border-muted`, `gap-4`, `rounded-sm`, etc. If a needed utility does not exist, add the token to `@theme` to extend the named scale rather than reaching for an arbitrary value.

## Design Tokens & Theming

- **No raw hex colors** — all colors via design tokens, never `#3B82F6` inline. Define color tokens in the Tailwind v4 `@theme` block and consume them through named utilities (`bg-primary`, `text-heading`, `border-muted`).
- **No hardcoded spacing/typography values** — use named utilities backed by `@theme` tokens (`text-sm`, `gap-4`, `p-4`, `rounded-md`); if a value has no token, add it to `@theme` or raise it as a design decision rather than inventing one.
- **Single source of truth** — tokens defined once in the `@theme` block (or `:root`/`.dark` for theme-able values consumed via `@theme inline`), never duplicated per component.
- **Support dark mode via tokens**, not per-component overrides. Define theme-able semantic tokens on `:root`/`.dark` and reference them in `@theme inline` so named utilities automatically adapt to the active theme.

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
