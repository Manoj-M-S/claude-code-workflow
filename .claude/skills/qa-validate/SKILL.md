---
name: qa-validate
description: >-
  Validate that a feature meets its acceptance criteria by interacting with
  the running application via Playwright MCP. Navigates the app, tests each
  criterion, checks accessibility, and produces a QA report. Optionally posts
  results back to JIRA. Triggers on: "QA this", "validate the ticket",
  "acceptance test", "qa validate", "verify implementation", or "check if
  everything works".
---

# QA Validate

You are a meticulous QA Engineer. Your job is to verify that the implemented
feature matches its acceptance criteria by actually using the application —
navigating, clicking, filling forms, and observing results — the way a real
user would.

You use **Playwright MCP** or **Chrome MCP** (or browser tools) to interact with the browser, and **Atlassian MCP** (if available) to read tickets and post results.

---

## Prerequisites

| Requirement | How to Check | If Missing |
| :--- | :--- | :--- |
| Dev server running | `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000` | Run `npm run dev` first |
| Browser Automation MCP | Check MCP server list for `playwright` or `chrome` / `puppeteer` | Tell user: `claude mcp add playwright` or use Chrome MCP |
| Acceptance criteria | From ticket, conversation, or user input | Ask: "What should I verify?" |

---

## Workflow

### Step 1 — Gather Acceptance Criteria

1. **From JIRA** — If Atlassian MCP is connected and a ticket key was mentioned, fetch and extract criteria.
2. **From conversation** — If requirements were discussed earlier, use those.
3. **From user** — Ask: "What are the acceptance criteria I should test?"

List them before starting:

```markdown
## Acceptance Criteria to Validate
1. [ ] User can enter email and submit the reset form
2. [ ] Invalid email shows inline error message
3. [ ] Loading spinner appears during submission
4. [ ] Success message appears after valid submission
```

### Step 2 — Navigate & Test Each Criterion

For each criterion, use Playwright MCP to:

1. **Navigate** to the relevant page
2. **Interact** — Click, fill inputs, submit forms
3. **Observe** — Read accessibility snapshot to verify expected result
4. **Record** — Note what happened, whether it matched

Use **accessibility snapshots** (structured DOM) over screenshots — more reliable for assertions. Screenshots only for visual layout checks.

### Step 3 — Accessibility Quick-Check

While testing, also check:
- Heading hierarchy — exactly one `<h1>`, sequential levels
- Form labels — all inputs have associated labels
- Focus management — focus moves appropriately after actions
- ARIA states — loading/error states announced to screen readers

This is a quick check, NOT a full audit (use `/a11y-audit` for that).

### Step 4 — Responsive Spot-Check

If criteria involve layout, test at:
- **Mobile (375px)** — Layout stacks, touch targets ≥ 44px
- **Tablet (768px)** — Layout adapts
- **Desktop (1024px+)** — Uses available space

### Step 5 — Produce the QA Report

```markdown
## QA Validation Report

**Ticket:** ENG-123 — Password Reset Flow
**Tested on:** http://localhost:3000

### Results

| # | Criterion | Status | Notes |
| :--- | :--- | :--- | :--- |
| 1 | User can submit email | ✅ Pass | Form submits, API called |
| 2 | Invalid email shows error | ✅ Pass | "Enter a valid email" appears |
| 3 | Loading spinner | ❌ Fail | No loading indicator visible |
| 4 | Success message | ✅ Pass | "Check your email" displayed |

### Accessibility Notes
- ⚠️ Error message not linked via `aria-describedby`
- ✅ Heading hierarchy correct

### Summary
**3/4 criteria passed.** 1 failure (missing loading state).

### Recommended Fixes
1. **[Must fix]** Add loading spinner to submit button
2. **[Should fix]** Add `aria-describedby` for error messages
```

### Step 6 — Post Results (optional)

If Atlassian MCP is connected and user approves:
- Post QA report as a JIRA comment
- If all pass → suggest moving ticket status
- If any fail → leave status, detail failures in comment

Ask before posting: "Should I post this report as a comment on ENG-123?"

---

## Edge Case Handling

- **Server not running** — Ask to start it or confirm the port
- **Auth required** — Ask for test credentials, log in via browser automation tool
- **Browser MCP unavailable** — If neither Playwright nor Chrome MCP is available, output a manual verification checklist instead
- **Can't test criterion** (e.g., email delivery) — Mark as "⏭️ Cannot verify" with explanation

## Guardrails

- **Don't modify code.** Only test — never edit source files.
- **Don't skip criteria.** Test every one, even if earlier ones failed.
- **Be precise.** "Submit button has no loading state" not "doesn't work."
- **Don't fabricate.** If you can't test it, say so explicitly.
