---
name: pr-raise
description: >-
  Raise a GitHub pull request the safe way: run the project's quality gates
  (format check, lint, type check, build) FIRST, and only open the PR if every
  gate passes — then write a high-quality PR description and create the PR with
  `gh`. Use this skill whenever the user wants to open, raise, create, submit,
  or "put up" a pull request, or says things like "PR this", "push and open a
  PR", "ship this branch", or "make a PR for these changes" — even if they don't
  explicitly mention running checks. The gates are non-negotiable and part of
  this skill; never skip straight to `gh pr create`.
---

# GitHub PR

Open a pull request only after the branch is proven green. The whole point of
this skill is that **a PR is never raised on broken code**: run the project's
checks first, stop hard if any fail, and only then write the description and
create the PR. Treat "raise a PR" as a request for the full gated pipeline, not
just the final `gh pr create` call.

## Pipeline

```
1. Preflight    → is this even raise-able? (git state, gh auth, base branch)
2. Quality gates → format · lint · typecheck · build   (ALL must pass)
3. Description   → analyze commits + diff, fill template, confirm
4. Create PR     → push branch, gh pr create, return URL
```

Do them in order. If a step fails, **stop there** and report — do not silently
proceed to the next step, and never jump to step 4 because the user is in a
hurry. A fast PR on red code is worse than a slow one.

---

## Step 1 — Preflight

Confirm the request is actionable before spending time on checks. Resolve any
problem before continuing:

- **Is this a git repo?** `git rev-parse --is-inside-work-tree`. If not, stop.
- **Is `gh` installed and authenticated?** `gh auth status`. If it errors, tell
  the user to run `gh auth login` (or install the GitHub CLI) and stop. Don't
  work around it with raw git/API calls.
- **What is the base branch?** Usually the repo's default branch:
  `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`, falling back
  to `git symbolic-ref --short refs/remotes/origin/HEAD | sed 's@^origin/@@'`.
  The user may override (e.g. PR into `develop`).
- **Are you on a feature branch?** `git branch --show-current`. If the current
  branch _is_ the base branch, you can't PR it into itself — stop and offer to
  create a branch first.
- **Are there commits to PR?** `git log --oneline <base>..HEAD`. If empty,
  there's nothing to propose; stop and say so.
- **Is the working tree clean?** `git status --porcelain`. Uncommitted changes
  will NOT be in the PR. If there are any, surface them and ask whether to commit
  first — don't assume. (If the user already said "commit and PR in one go,"
  commit them with a sensible message, then continue.)

Keep this lightweight — a few quick commands. Fail early with a clear message
rather than discovering a problem after a 3-minute build.

---

## Step 2 — Quality gates (all must pass)

This is the heart of the skill. Run the project's checks and **only proceed if every one passes.**

> [!IMPORTANT]
> **React/TypeScript projects**: If the project is a React/TypeScript frontend project, you must delegate the verification and code fixing to the `quality-fixer-frontend` protocol first to ensure proper stub checks, MSW mocking, and React Testing Library assertion quality checks pass before raising the PR.

| Gate      | What it proves                        |
| --------- | ------------------------------------- |
| format    | Code matches Prettier formatting      |
| lint      | No ESLint (or equivalent) violations  |
| typecheck | No TypeScript type errors             |
| build     | The project actually compiles/bundles |

### Find the real commands

Detect the **package manager** from the lockfile:

| Lockfile               | Manager | Run prefix |
| ---------------------- | ------- | ---------- |
| `bun.lockb`/`bun.lock` | bun     | `bun run`  |
| `pnpm-lock.yaml`       | pnpm    | `pnpm run` |
| `yarn.lock`            | yarn    | `yarn`     |
| (none → default)       | npm     | `npm run`  |

Then read `package.json` `scripts` and map each gate to the **first** script
that exists (names vary across projects):

| Gate      | Script name candidates (first match wins)                                        |
| --------- | -------------------------------------------------------------------------------- |
| format    | `format:check`, `prettier:check`, `check:format`, `format-check`, `check-format` |
| lint      | `lint:check`, `lint`, `eslint:check`, `eslint`                                   |
| typecheck | `typecheck`, `type-check`, `tsc`, `check-types`, `types`                         |
| build     | `build`, `compile`                                                               |

Two cautions:

- **Prefer the read-only "check" variants for format/lint.** A plain `format`
  or `prettier` script is often `prettier --write`, which _mutates_ files and
  hides the problem. A pre-PR gate must only report, not rewrite. If only a
  writing-style script exists, run `prettier --check .` directly instead.
- **Typecheck fallback:** if there's a `tsconfig.json` but no typecheck script,
  run `npx tsc --noEmit` (type-checks without emitting files).

If the project isn't plain JS/TS (monorepo, Makefile, other ecosystem), find the
equivalents and apply the same rule — every gate green before the PR:

- **Go**: `go build ./...`, `go vet ./...`, `gofmt -l .` (empty = clean), `golangci-lint run`
- **Rust**: `cargo build`, `cargo clippy -- -D warnings`, `cargo fmt --check`
- **Python**: `mypy .`, `ruff check .`, `ruff format --check .`, plus build/tests
- **Monorepo**: scope to the changed package, or use the workspace runner
  (`turbo run build`, `nx affected -t lint`, `pnpm -r ...`) so all affected
  packages are actually checked — root-only scripts can miss per-package failures.

### Order: cheap and likely-to-fail first

Run **format → lint → typecheck → build**. All four must pass regardless, so
order doesn't change the outcome — but formatting and lint fail in seconds while
the build can take minutes, so this order surfaces common failures fastest.

### When a gate fails

1. **Stop the pipeline.** Don't run the remaining gates or create the PR.
2. **Show the actual failing output** — the type error, the lint rule + file,
   the build stack trace. "Lint failed" alone isn't actionable.
3. **Offer to fix the auto-fixable ones, with consent.** `format`/`lint` often
   have safe fixers (`prettier --write`, `eslint --fix`). Offer them, and only
   after the user agrees: run the fixer, show the diff, commit it (or let them),
   then re-run that gate. Never auto-fix-and-commit silently — surprise commits
   erode trust.
4. **Type errors and build failures are real bugs.** Don't paper over them by
   loosening config (`// @ts-ignore`, disabling rules, `skipLibCheck`) unless the
   user explicitly asks. Diagnose and propose a real fix, or hand it back.

Only when **everything is green** do you move on.

---

## Step 3 — Write the PR description

Part of raising the PR, not an afterthought. The reviewer should understand
_what changed and why_ without reading every line of the diff. Optimize for the
reviewer (and for whoever runs `git blame` in a year), not for restating the diff.

Gather your raw material:

```bash
git log <base>..HEAD --pretty=format:'%s%n%b'   # commit subjects + bodies
git diff <base>...HEAD --stat                    # files + insertion/deletion counts
git diff <base>...HEAD                           # full diff if you need detail
git branch --show-current                         # branch name often encodes the issue
```

### Title

One line, imperative present tense ("Add retry to upload", not "Added"/"Adds"),
under ~70 chars, scoped to the change not the file. **Match the repo's
convention** — if commits/merged PRs use Conventional Commits, follow suit:

- `feat(auth): add passwordless email login`
- `fix(api): handle null cursor in pagination`
- `chore(deps): bump eslint to v9`

Otherwise a plain imperative sentence is fine.

### Body

**Prefer the repo's own template** if one exists — fill in its sections, don't
replace it:

```bash
cat .github/pull_request_template.md 2>/dev/null \
  || cat docs/pull_request_template.md 2>/dev/null
```

If there's none, use this default:

```markdown
## Summary

<1–3 sentences: what this PR does and why. Lead with the why.>

## Changes

- <key change, grouped by concern — not a file-by-file dump>
- <call out anything reviewers should look at closely>

## Testing

- <how it was verified: tests added, manual steps, screenshots for UI>

<Closes #123 — or "Relates to #123" if it doesn't fully close it>
```

Guidance:

- **Summary** — start with the motivation ("Uploads were timing out on large
  files, so…"). Two or three sentences max.
- **Changes** — group by concern, not file. Flag risky or non-obvious bits.
- **Testing** — say what gives confidence this works.
- **Issue links** — `Closes #N`/`Fixes #N` auto-close on merge; `Relates to #N`
  when the PR is only part of the fix.
- **Scale to the change** — a typo fix gets a one-liner; don't pad with empty
  "Testing: N/A" boilerplate. A 400-line feature warrants real sections.
- **Don't invent rationale.** If the _why_ isn't clear from commits or the
  conversation, ask the user rather than writing a confident-but-wrong summary.

Show the drafted title and body to the user and let them tweak it before you
create the PR — unless they've clearly said to do it end-to-end.

---

## Step 4 — Create the PR

```bash
git push -u origin HEAD

# write the body to a file — safer than --body for anything with backticks,
# quotes, or newlines
gh pr create --base "<base>" --title "<title>" --body-file /tmp/pr-body.md
```

- Use `--draft` if the user wants a draft.
- If a PR already exists for the branch, `gh pr create` will say so. Don't error
  out — the changes are pushed; offer to update the existing description
  (`gh pr edit`) or open it (`gh pr view --web`).
- After success, **return the PR URL** so the user can click through.

---

## Guardrails

- **Never skip the gates to save time.** If the user insists ("just open it,
  I'll fix CI later"), you may comply, but say plainly that the branch is
  unverified and default to opening it as a **draft**.
- **Never weaken checks to make them pass** (disabling rules, ignoring types,
  excluding files) unless the user explicitly directs it.
- **One gate failing fails the whole pipeline.** Green-ish is not green.
