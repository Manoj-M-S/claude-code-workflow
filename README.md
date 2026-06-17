# 🤖 Claude Code Developer Workflow

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude--Code-ultimate--workflow-purple.svg)](https://docs.anthropic.com/claude/docs/claude-code)
[![Shell Scripting](https://img.shields.io/badge/Shell-bash-green.svg)](#lifecycle-hooks)
[![Custom MCPs](https://img.shields.io/badge/MCP-Playwright%20%7C%20Figma%20%7C%20Jira-orange.svg)](#mcp-servers)

An automated, high-discipline agentic development workflow configuration for **Claude Code**. It turns isolated AI behaviors into a unified, sequential, and highly disciplined engineering system that automatically enforces requirements, styling conventions, and strict code-quality gates before any code is committed or submitted.

---

## 📐 Architecture & Pipeline Flow

This workflow coordinates Claude's lifecycle using **Agents** (orchestrators), **Skills** (interactive execution steps), and **Hooks** (automated gatekeepers).

```mermaid
graph TD
    A[Start Session] -->|Hook: SessionStart| B(env-check.sh)
    B --> C{Orchestrators}

    subgraph Task Pipeline
        C -->|build this ticket| D[Classify & Plan]
        D -->|/grill-me clarify · /task-planner| E[Implement per task]
        E -->|lightweight verify · atomic commit · repeat| F[Quality Gate & QA]
    end

    subgraph PR Pipeline
        C -->|ship it| G[Quality Fixer Frontend]
        G -->|Hook: PostToolUse| H(post-edit.sh)
        H --> I[PR Reviewer / A11y & SEO Audit]
        I --> J[PR Raise]
    end

    F -->|Hook: Stop| K(pre-stop.sh)
    J -->|Hook: Stop| K
    K -->|Passes| L[Session End / Code Committed]
```

---

## 🗺️ Which Tool When?

Not sure where to start? Use this table to find the right entry point for common scenarios.

| Scenario | Use |
| :--- | :--- |
| Starting a brand-new project (tokens, dark mode, Tailwind) | `/project-setup` |
| Building a ticket end-to-end (plan → code → quality → QA) | `task-pipeline` agent |
| Pressure-testing a plan before writing any code | `/grill-me` |
| Doing strict test-first Red-Green-Refactor TDD on a unit | `/tdd` *(standalone, opt-in — not a pipeline step)* |
| Generating a single component | `/component-generator` |
| Turning a Figma design into production code | `/figma-to-code` |
| Auditing or refactoring an existing token system | `/css-design-system` |
| Deciding visual direction, palette, or typography | `/frontend-design` |
| Fixing failing lint, type errors, or broken tests | `/quality-fixer-frontend` |
| Reviewing a PR diff for bugs, architecture, and nits | `/pr-review` |
| Shipping — raising a pull request with full gates | `pr-pipeline` agent or `/pr-raise` |
| Accessibility audit (WCAG 2.1 AA) | `a11y-audit` subagent |
| SEO, meta tags, structured data audit | `seo-audit` subagent |
| Validating a feature in a real browser | `/qa-validate` |
| Writing QED42 blog content or content briefs | `/qed42-blog-writing` |
| Sharpening a vague or underspecified prompt | `/prompt-optimizer` |
| Identifying and refactoring shallow modules | `/improve-codebase-architecture` |

---

## 🛠️ Folder Structure

```filetree
.claude/
├── settings.json              # Main settings, hook configs, permissions, and MCP servers
├── agents/                    # Multi-step orchestrator pipelines
│   ├── task-pipeline.md       # Ticket classification & build pipeline
│   ├── pr-pipeline.md         # Pre-shipping validation & PR creator
│   ├── a11y-audit.md          # WCAG 2.1 AA accessibility specialist (subagent)
│   └── seo-audit.md           # SEO, structured data, and meta tag auditor (subagent)
├── hooks/                     # Lifecycle shell scripts triggered by Claude events
│   ├── env-check.sh           # Warns if local env vars don't match .env.example
│   ├── protect-secrets.sh     # Blocks reading secret files (.env, .pem, .key, etc.)
│   ├── post-edit.sh           # Checks files after edit/write (format, lint, conventions, secrets)
│   └── pre-stop.sh            # Runs typechecks, tests, and duplicate scans on exit
├── skills/                    # Domain-specific developer skills (15 slash commands)
│   ├── tdd/                   # Enforces Red-Green-Refactor TDD flow
│   ├── task-planner/          # Generates structured implementation plans
│   ├── grill-me/              # Pressure-tests feature specs step-by-step
│   ├── css-design-system/     # Token architecture, Tailwind config, CSS audit
│   ├── frontend-design/       # Aesthetic direction, typography, visual identity
│   ├── project-setup/         # One-time bootstrap: tokens, dark mode, fonts, cn()
│   ├── quality-fixer-frontend/# Automates lint, formatting, typecheck, test, build fixes
│   ├── qa-validate/           # Playwright browser integration testing
│   ├── pr-raise/              # Strict gated push & GitHub PR creation
│   ├── pr-review/             # Comprehensive diff review & issue labeling
│   ├── figma-to-code/         # Translates Figma design MCP data to React/Svelte
│   ├── component-generator/   # Scaffolds UI components with tests
│   ├── prompt-optimizer/      # Rewrites vague prompts to high-performance prompts
│   ├── improve-codebase-architecture/ # Deep module refactoring proposals
│   └── qed42-blog-writing/    # QED42 content strategy, briefs, and drafts
└── references/                # Shared reference files consumed by skills
    ├── conventions.md         # Single source of truth for frontend conventions
    ├── voice-and-editorial.md # QED42 voice, tone, and editorial rules (used by qed42-blog-writing)
    ├── positioning.md         # QED42 positioning and services (used by qed42-blog-writing)
    └── writing-patterns.md    # QED42 case study patterns (used by qed42-blog-writing)
```

---

## 🤖 Orchestrator Agents (`.claude/agents/`)

Orchestrator agents chain multiple skills in a structured sequence to execute broad workflow stages.

### 📋 Task Pipeline (`task-pipeline.md`)
* **Trigger phrases:** `"build this ticket"`, `"task pipeline"`, `"implement this"`, `"start work on"`
* **Flow:** Classifies the ticket → Uses `/grill-me` to surface ambiguities (one question at a time) → Runs `/task-planner` for a dependency-ordered task breakdown → Implements each task using `/component-generator` conventions (tests written alongside code), runs a lightweight verify, and commits atomically before moving on → Full quality gate (lint + typecheck + tests + build) → Browser QA.

### 🚀 PR Pipeline (`pr-pipeline.md`)
* **Trigger phrases:** `"ship it"`, `"PR pipeline"`, `"full PR"`
* **Flow:** Requirements check → CSS/convention audit → Runs `/quality-fixer-frontend` → Writes a PR description → Opens pull request using `/pr-raise`.

### ♿ Accessibility Audit (`a11y-audit.md`)
* **Focus:** WCAG 2.1 AA standards.
* **Flow:** Analyzes DOM structure, keyboard usability (tab order, focus-visible), ARIA roles, visual color contrast (minimum 4.5:1), and semantic HTML correctness.

### 🔍 SEO Audit (`seo-audit.md`)
* **Focus:** Auditing search visibility, heading hierarchy, unique element IDs, Next.js/Svelte metadata, and OpenGraph/JSON-LD structured data formats.

---

## ⚡ Automated Git Lifecycle Hooks (`.claude/hooks/`)

Defined inside `.claude/settings.json`, these hooks act as automated quality gates. They prevent Claude from submitting code that doesn't meet project standards.

### 1. `PreToolUse` (Read | Bash) → `protect-secrets.sh`
* **Purpose:** Runs before Claude reads a file or executes a shell command.
* **Validation:** Blocks access to secret files (`.env`, `.env.*`, `*.pem`, `*.key`, `*.p12`, `id_rsa`, credentials, `.ssh/`). Allows `.env.example`. For Bash commands, detects read utilities (`cat`, `grep`, `head`, `tail`, etc.) targeting secret files.

### 2. `SessionStart` → `env-check.sh`
* **Purpose:** Runs when Claude starts a session.
* **Validation:** Reads `.env.example` and compares it to `.env.local` or `.env`. Warns (non-blocking) if local configuration keys are missing.

### 3. `PostToolUse` (Edit | Write) → `post-edit.sh`
* **Purpose:** Runs immediately after Claude modifies or creates a file.
* **Validation:**
  * **Prettier**: Rejects files not formatted correctly.
  * **ESLint**: Catches syntax and linting errors.
  * **Styling Units**: Enforces `rem` for typography and `px` for spacing/borders.
  * **Tailwind Optimization**: Prevents repeated utility class clusters of 6+ utilities.
  * **Color Custom Properties**: Rejects hardcoded hex/rgb colors; mandates CSS variable tokens.
  * **Stacking Context**: Catches hardcoded `z-index` numbers; mandates tokenized indexes.
  * **Bundle-Size Guard**: Blocks wildcard imports (`lucide-react`) or bloated libraries (`lodash`, `moment`).
  * **`!important` Detection**: Flags `!important` and suggests specificity fixes.
  * **Secret Scan**: Catches hardcoded credentials (AWS keys, private key headers, API tokens) being written into source files.

### 4. `Stop` → `pre-stop.sh`
* **Purpose:** Runs when Claude attempts to finish a turn and stop.
* **Validation:**
  * Runs TypeScript compiler (`tsc --noEmit`) to verify type safety.
  * Scans across files for duplicate exported function names to prevent redundant logic.
  * Runs the project's test suite (`npm test`, `pnpm test`, etc.) in non-watch mode.
  * **Reentry Block:** If checks fail, it returns an exit code `2`, which **forces Claude to stay active** to fix the reported bugs before concluding.

---

## 🛠️ Custom Developer Skills (`.claude/skills/`)

Skills are specialized tools containing detailed prompt guidelines that Claude invokes to execute specific tasks.

| Skill | Purpose | Key Commands / Behavior |
| :--- | :--- | :--- |
| **`/tdd`** | Enforces test-driven development cycles. | Red (write failing test) → Green (make it pass) → Refactor. |
| **`/task-planner`** | Translates tickets to step-by-step execution plans. | Prepares test strategy, risk analysis, and Git branch structure. |
| **`/grill-me`** | Interrogates specifications before coding. | Asks clarifying questions one-at-a-time to eliminate ambiguity. |
| **`/css-design-system`** | Audits/architects CSS token systems. | Three-tier tokens, Tailwind config, dark mode, audit workflow. |
| **`/frontend-design`** | Visual/aesthetic design direction. | Palette, typography pairing, signature elements, brainstorm→critique. |
| **`/project-setup`** | One-time project styling bootstrap. | Tokens, Tailwind config, dark mode, fonts, cn(), base styles. |
| **`/quality-fixer-frontend`** | Fixes failing lint, typecheck, or tests. | Runs compiler and linters, auto-fixing issues where possible. |
| **`/qa-validate`** | End-to-end user journey validation. | Automates local Playwright/Chrome-devtools testing steps. |
| **`/pr-raise`** | Pre-PR gated publisher. | Runs format, lint, typecheck, and build before calling `gh pr create`. |
| **`/pr-review`** | Code reviewer. | Scours diffs for architectural issues and logs them by severity. |
| **`/figma-to-code`** | Figma design to code. | Translates Figma mockups to CSS-token-aligned component code. |
| **`/component-generator`** | Scaffolds UI components. | Generates accessible, responsive, tested React/Svelte components. |
| **`/prompt-optimizer`** | Improves AI prompts. | Rewrites vague prompts to structured, high-performance prompts. |
| **`/improve-codebase-architecture`** | Module depth analysis. | Identifies shallow modules and proposes deep-module refactors. |
| **`/qed42-blog-writing`** | QED42 content work. | Topic suggestions, content briefs, market research, first drafts. |

---

## 🔌 Model Routing & MCP Servers

The workflow utilizes custom MCP (Model Context Protocol) servers to hook Claude up to external developer ecosystems:

### Configured MCP Servers (in `.claude/settings.json`)
* **Playwright MCP (`@playwright/mcp`)** - Orchestrates headless browser interactions for automated E2E testing.
* **Chrome DevTools MCP (`chrome-devtools-mcp`)** - Monitors live web pages, network calls, console logs, and errors during verification.
* **Context7 MCP (`@upstash/context7-mcp`)** - Fetches latest developer documentation for standard UI framework tools (React, Next.js, Tailwind).

### External Integrations
* **Jira / Atlassian MCP** - Connects Claude to your project tickets for planning.
  ```bash
  claude mcp add --transport sse atlassian https://mcp.atlassian.com/v1/sse
  ```
* **Figma Plugin** - Reads vector design nodes directly from mockups.
  ```bash
  claude plugin install figma@claude-plugins-official
  ```

---

## 🚀 How to Setup

To import this workflow setup into an existing development repository:

### 1. Copy the configuration folder
Clone or copy the `.claude/` directory and `CLAUDE.md` into the root of your project:
```bash
git clone https://github.com/Manoj-M-S/claude-code-workflow.git
cp -r claude-code-workflow/.claude ./
cp claude-code-workflow/CLAUDE.md ./
```

### 2. Make hooks executable
Ensure the lifecycle shell scripts are executable:
```bash
chmod +x .claude/hooks/*.sh
```

### 3. Verify GitHub CLI authentication
This workflow uses the GitHub CLI (`gh`) to automate Pull Request creation. Confirm you are authenticated:
```bash
gh auth status
```
If you aren't logged in, run:
```bash
gh auth login
```

### 4. Boot up Claude Code
Launch Claude Code in your project root. It will read the `.claude/settings.json` and initialize the workflow hooks:
```bash
claude
```

---

## ⚙️ Customizing the Workflow

The workflow is designed to be tuned for your project. Here are the most common adjustment points:

| What to change | Where |
| :--- | :--- |
| **Frontend conventions** — px/rem rules, Tailwind-cluster threshold, color-token enforcement | `.claude/references/conventions.md` — the single source of truth; editing here updates all skills that reference it |
| **px/rem & Tailwind-cluster thresholds** — the exact regex patterns and numeric limits | `.claude/hooks/post-edit.sh` — sections 3 (styling units) and 4 (repeated class clusters); adjust the regex or the `>=6` utility threshold |
| **Enable or disable a hook** — e.g. turn off the post-edit secret scan | `.claude/settings.json` — remove or comment out the relevant hook object inside `hooks.PostToolUse`, `hooks.PreToolUse`, etc. |
| **Add paths to the secret-file blocklist** — protect additional credential files | `.claude/settings.json` → `permissions.deny` array **and** `.claude/hooks/protect-secrets.sh` `is_secret_path()` function — both must be updated together |
| **Add or remove MCP servers** | `.claude/settings.json` → `mcpServers` block |

---

## ✨ Inspiration & Credits

This workflow config draws on ideas and patterns from several sources:

| Source | Contribution |
| :--- | :--- |
| **[Andrej Karpathy](https://x.com/karpathy/status/2015883857489522876)** | The behavioral guidelines in `CLAUDE.md` — think before coding, simplicity first, surgical changes, goal-driven execution |
| **[Matt Pocock](https://www.totaltypescript.com/)** | TypeScript-strictness patterns reflected in the conventions — no `any`, explicit prop interfaces, strict mode throughout |

*Did this workflow draw on something else you recognise? Open a PR and add it here.*

---

## 🤝 Contributing

We welcome contributions to make this workflow configuration even more robust! Feel free to:
1. Open an issue to discuss design enhancements or new skills.
2. Submit a Pull Request. Please make sure that all local checks pass (run `.claude/hooks/pre-stop.sh` manually to verify).

## 📄 License

This workflow setup is open-source software licensed under the [MIT License](LICENSE).
