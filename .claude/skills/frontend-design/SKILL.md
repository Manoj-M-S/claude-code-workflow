---
name: frontend-design
description: >-
  Guidance for distinctive, intentional visual design when building new UI or
  reshaping an existing one. Covers aesthetic direction, typography, layout,
  interactive polish, responsive execution, dark mode theming, and UX quality.
  Triggers on: "design a page", "make this look premium", "create a landing page",
  "visual identity", "theme choices", "typography pairing", "styling ideas",
  "aesthetics", "creative UI design", "design review", "polish the UI",
  "improve UX", "add animations", or "make it responsive".
---

# Frontend Design & UX

Approach this as the design lead at a small studio known for giving every client a visual identity that could not be mistaken for anyone else's. Make deliberate, opinionated choices about palette, typography, and layout that are specific to this brief, and take one real aesthetic risk you can justify.

---

## 1. Ground it in the Subject

If the brief does not pin down what the product or subject is, pin it yourself before designing:
- Name one concrete subject, its audience, and the page's single job, and state your choice.
- Build with the brief's real content and subject matter throughout (materials, instruments, artifacts, and vernacular of that specific industry/world).
- Do not use abstract filler content.

---

## 2. Design Principles

### The Hero is a Thesis
Open with the most characteristic thing in the subject's world (e.g., a headline, an image, an animation, a live demo, or an interactive moment). Avoid generic templates (like a large number, small label, supporting stats, and a gradient accent) unless it is truly the best possible fit.

### Personality via Typography
Pair display and body faces deliberately. Set a clear type scale with intentional weights, widths, and letter-spacing. Make the type treatment itself a memorable part of the design, not just a neutral delivery vehicle for text.

### Structure is Information
Eyebrows, dividers, labels, and lists must encode something true about the content, not decorate it. For example, numbered markers (`01`, `02`, `03`) should only be used if the content actually is a sequence (like a timeline or process).

### Leverage Motion Deliberately
Identify where animation serves the subject (e.g., page-load sequences, scroll-triggered reveals, or hover micro-interactions). One coordinated, orchestrated moment lands harder than scattered effects. Be careful not to overdo animations, which can make a site feel bloated or AI-generated.

### Match Complexity to the Vision
- **Maximalist directions**: Need elaborate, layered, and rich execution.
- **Minimalist directions**: Need absolute precision in spacing, borders, typography, and subtle details.

---

## 3. Process: Brainstorm, Explore, Plan, Critique, Build

To avoid common AI-generated design patterns (like warm cream background + serif font, or near-black background + single acid accent, or broadsheet layout with zero border-radius), work in two passes:

1. **Pass 1 — Design Plan**:
   - **Color**: Describe the palette as 4–6 named colors (using OKLCH, HSL, or hex).
   - **Type**: Choose typefaces for 2+ distinct roles (display face vs. body face).
   - **Layout**: Draft a layout concept using one-sentence descriptions and ASCII wireframes.
   - **Signature**: Identify the single unique element this page will be remembered by.
2. **Pass 2 — Self-Critique**:
   - Review the plan. If any part looks like a default that could apply to any generic website, revise it before writing any code.
   - When writing the code, be careful of selector specificity (e.g. paddings and margins between sections).

---

## 4. Restraint & Writing in Design

- **Spend your boldness in one place**: Let the signature element be the one memorable thing, keeping everything around it quiet, disciplined, and clean.
- **Write from the end user's perspective**: Use active voice, call actions by what the user controls ("Save changes" not "Submit"), and make error messages helpful and actionable rather than vague or apologetic.
- **Empty states are invitations**: Treat empty screens as calls to action rather than blank space.

---

## 5. UI Polish & Execution Checklist

When implementing or reviewing UI, verify every item below. This is the practical execution layer that turns a design direction into a polished product.

### Visual Quality
- **Rich aesthetics**: Harmonized color palettes (using HSL, OKLCH, or curated Tailwind scales), smooth gradients, modern typography, and clean layouts. No generic colors.
- **Interactive polish**: Add subtle interactive states (`hover:`, `focus:`, `active:`), smooth transitions (`transition-colors duration-200 ease-in-out`), and loading skeletons. Avoid `transition-all` — transition only the properties that change.
- **Dark mode continuity**: Components must look just as striking in dark mode as in light mode. Test both themes.

### Spacing & Layout
- **Spacing consistency**: All margins, paddings, and gaps use pixels (`px`) or design tokens. Never `rem` for spacing.
- **Typography in `rem`**: All font sizes in `rem`. Unitless line-height. Max prose width `65ch`.
- **4px/8px grid**: Every spacing value is a multiple of 4px.

### Responsive Execution
- **Mobile-first**: Base styles for small screens, `min-width` breakpoints layer up.
- **Test at real breakpoints**: 375px (mobile), 768px (tablet), 1024px+ (desktop).
- **Touch targets**: All interactive buttons and links have a minimum touch target size of 44×44px on mobile.

### UX Quality
- **Loading states**: Never leave a screen blank when fetching data. Build clean placeholder skeletons or loaders.
- **Empty states**: Treat empty screens as calls to action rather than blank space.
- **Error states**: Provide helpful, actionable error messages. No generic "Something went wrong."
- **Keyboard navigation**: All interactive elements focusable with visible focus styles.
- **Reduced motion**: Respect `prefers-reduced-motion` for all animations and transitions.
