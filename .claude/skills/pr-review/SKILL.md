---
name: pr-review
description: >-
  Thoroughly review a GitHub pull request from its link or number. Fetches the
  PR, reads beyond the diff into the surrounding code, and produces a prioritized
  review — correctness, edge cases, security, performance, error handling, tests,
  and repo conventions — with concrete file:line findings classified by severity,
  then optionally posts it to GitHub. Use this skill whenever the user gives a PR
  URL or number and wants it reviewed, or says things like "review this PR",
  "look over my pull request", "can you check this PR", "PR feedback", or
  "is this PR good to merge" — even if they don't spell out what to look for.
  Always read the actual changed files in context; never review from the diff
  hunks alone.
---

# PR Review

Review a pull request the way a careful senior engineer would: read the change
in the context of the code around it, think about what could go wrong, and give
feedback that's specific, prioritized, and actionable. The goal is to **catch
real problems and unblock a good merge** — not to rubber-stamp, and not to bury
the author in nitpicks.

Two principles run through everything below:

- **Review beyond the diff.** A diff hunk hides whether callers were updated,
  whether an edge case is handled three lines above the change, whether a test
  actually exercises the new path. Read the whole changed files (and their
  callers) before judging.
- **Specific and prioritized, or it's noise.** Every finding gets a file:line
  and, where possible, a concrete fix. Every finding gets a severity so the
  author knows what blocks the merge versus what's optional.

## Pipeline

```
1. Fetch    → pull PR metadata, description, diff, files, commits, CI status
2. Context  → read the full changed files + callers; verify the description
3. Analyze  → walk the review dimensions; collect findings
4. Classify → Blocking / Should-fix / Nit / Question
5. Report   → structured review with a clear verdict
6. Post     → (opt-in) push the review to GitHub
```

---

## Step 1 — Fetch the PR

Accept a URL (`https://github.com/owner/repo/pull/123`) or a number. Confirm
`gh auth status` works first; if not, tell the user to `gh auth login`.

```bash
PR="<url-or-number>"
gh pr view "$PR" --json title,body,author,baseRefName,headRefName,state,url,\
labels,additions,deletions,changedFiles,commits,reviewDecision,isDraft
gh pr diff "$PR"                 # the patch
gh pr diff "$PR" --name-only     # just the file list
gh pr checks "$PR"               # CI / status checks
```

From this you get: the author's stated intent (`body`), size and scope
(`additions`/`deletions`/`changedFiles`), commit history, and whether CI is
green. **If CI is failing, lead with that** — a failing build/test often makes
deeper review premature; note it and decide with the user whether to continue.

If the PR links an issue (look in the body for `Closes #N` / `Fixes #N`), read
it — it tells you what the change is _supposed_ to do:

```bash
gh issue view <N> --json title,body
```

---

## Step 2 — Read beyond the diff

This is what separates a real review from a skim. Get the actual files at the
PR's head so you can read full context, not just the changed lines:

```bash
gh pr checkout "$PR"   # checks out the PR branch (needs a clean working tree)
```

If checking out isn't desirable (dirty tree, don't want to switch branches),
fetch the ref instead and read files from it:

```bash
gh pr diff "$PR" --name-only        # list changed files
# then open each changed file in full to read it in context
```

While reading, actively look for what the diff _doesn't_ show:

- **Callers and call sites.** If a signature, return type, or behavior changed,
  grep for every caller and check they were updated. A green build doesn't prove
  callers handle the new behavior correctly.
- **The surrounding function.** Is the edge case already handled just outside
  the hunk? Did the change break an invariant the rest of the function relies on?
- **Tests for the new code.** Open the test files. Do they actually exercise the
  new path, including failure cases — or just assert the happy path compiles?
- **Verify the description against reality.** Does the diff do what the body
  claims? Does it also do things the body _doesn't_ mention (scope creep,
  unrelated changes, a sneaky config tweak)? Flag mismatches.

For generated files, lockfiles, vendored code, and large data fixtures: skim for
anything alarming but don't line-review them — say you skipped them and why.

---

## Step 3 — Analyze: the review dimensions

Walk these deliberately. Not every dimension applies to every PR — skip the
irrelevant ones, but don't skip them out of haste.

- **Correctness** — Does it do what it claims? Logic errors, off-by-ones,
  inverted conditions, wrong operator, incorrect async/await, race conditions.
- **Edge cases** — Empty/null/undefined inputs, zero and negative numbers, empty
  collections, very large inputs, unicode, timezones, concurrent access,
  first-run vs. steady-state.
- **Error handling** — Are failures caught and handled, or swallowed? Are errors
  surfaced with enough context? Does it leak resources on the error path
  (unclosed handles, missing cleanup)? Are promises/rejections handled?
- **Security** — Injection (SQL, command, XSS, template), missing authz checks,
  secrets committed or logged, unsafe deserialization, SSRF, path traversal,
  insecure defaults, dependency with known CVEs. Treat anything touching auth,
  user input, file paths, or network with extra suspicion.
- **Performance** — N+1 queries, work inside hot loops, unbounded growth,
  needless re-renders/recomputation, blocking calls on a hot path, missing
  pagination or indexes. Flag only where it plausibly matters, not micro-stuff.
- **Tests** — Is the new behavior covered? Are failure paths tested, not just
  the happy path? Are the assertions meaningful (not `expect(true)`)? Would the
  tests actually fail if the code regressed?
- **API & compatibility** — Breaking changes to public signatures, response
  shapes, config, CLI flags, or DB schema. Migration provided? Backward
  compatible, or a documented breaking change?
- **Readability & maintainability** — Names that mislead, dead code, duplicated
  logic that should be shared, overly clever one-liners, missing-but-warranted
  comments explaining _why_.
- **Repo conventions** — Does it match the patterns already used in this
  codebase (error style, logging, file layout, naming)? Consistency beats
  personal preference — review against the repo, not against your own taste.
- **Docs** — Do user-facing changes need README/changelog/comment updates that
  are missing?

---

## Step 4 — Classify every finding

Assign one of these so the author knows what's required vs. optional. This is the
single most useful thing a review provides — an unprioritized wall of comments
forces the author to guess what actually matters.

- **[Blocking]** — Must be fixed before merge: bugs, security issues, broken/
  missing tests for core behavior, breaking changes without migration.
- **[Should-fix]** — Strongly recommended but not a hard stop: weak error
  handling, missing edge-case coverage, notable readability problems.
- **[Nit]** — Optional polish: naming, formatting the linter didn't catch, minor
  style. Label clearly as optional so it doesn't read as a demand.
- **[Question]** — You need the author's intent before judging. Genuinely asking,
  not a disguised assertion.

Separate **fact** from **preference**. "This dereferences `user` which can be
null here (line 42)" is a fact. "I'd extract this into a helper" is a preference
— mark it as one. Be honest about which is which.

---

## Step 5 — Produce the review

Use this structure. Lead with the verdict and summary so the author gets the
headline immediately, then the details.

```markdown
## Review: <PR title>

**Verdict:** Approve / Approve with nits / Request changes / Needs discussion
**Summary:** <2–4 sentences — what the PR does, overall quality, and the
one or two things that drive the verdict.>

### Blocking

- **`path/to/file.ts:42`** — <what's wrong, why it matters, and the fix.>

### Should-fix

- **`path/to/file.ts:88`** — <issue + suggestion.>

### Nits (optional)

- **`path/to/file.ts:101`** — <minor.>

### Questions

- **`path/to/file.ts:55`** — <what you need to understand.>

### What's good

- <Call out genuinely solid choices. Brief and sincere — not filler.>
```

Rules for the writeup:

- **Always include real file:line references.** A finding without a location
  isn't actionable.
- **Suggest the fix, not just the flaw.** Where a concrete change is clear, show
  it — a GitHub suggestion block is ideal for small edits:

  ````markdown
  ```suggestion
  if (user?.id) {
  ```
  ````

- **Scale to the PR.** A two-line fix gets a couple of sentences; a large
  feature gets the full structure. Don't manufacture findings to look thorough —
  if it's clean, say so and approve. Don't invent problems.
- **Be constructive and direct.** Critique the code, not the author. No
  sugarcoating that hides a real bug; no harshness on a style nit.

---

## Step 6 — Post to GitHub (opt-in)

**Present the review in chat first.** Only post to GitHub if the user asks — they
may want to edit it, or just use it themselves.

Post as a single review (write the body to a file to avoid quoting issues):

```bash
gh pr review "$PR" --request-changes --body-file /tmp/review.md   # if blocking
gh pr review "$PR" --approve         --body-file /tmp/review.md   # if clean
gh pr review "$PR" --comment         --body-file /tmp/review.md   # neutral notes
```

For inline, line-anchored comments (the CLI's review verbs only post a single
summary body), use the API per comment:

```bash
gh api "repos/{owner}/{repo}/pulls/<N>/comments" -f body="<comment>" \
  -f commit_id="<head sha>" -f path="path/to/file.ts" -F line=42 -f side=RIGHT
```

Match the verb to the verdict: `--request-changes` when there's anything
Blocking, `--approve` only when you'd genuinely merge it, `--comment` otherwise.
Don't approve a PR with open Blocking findings just because the user asked you to
post — flag the contradiction first.

---

## Guardrails

- **Never approve unread code.** If the PR is too large to review properly in one
  pass, say so, review it in chunks, and don't render a verdict until you've
  covered it.
- **Don't rubber-stamp, don't nitpick to death.** Both waste the author's trust.
  Prioritize ruthlessly.
- **Don't fabricate findings or file:line numbers.** If you're unsure, open the
  file and check, or ask. A confident-but-wrong review is worse than none.
- **Stay within review.** Don't push commits or change the PR unless the user
  explicitly asks you to fix it for them.
