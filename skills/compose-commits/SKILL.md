---
name: compose-commits
description: "Use when splitting a completed piece of work into commits for a human reviewer: grouping by logical concern (pipeline stages by default), hunk-level splitting inside a single file, matching the project's commit message convention, and the propose-by-default / execute-only-when-told rule. Used by `commit composer` at the end of the pipeline."
---

## Composing commits

The goal is commits a reviewer wants to read: grouped by *logical concern*, each one understandable and (ideally) building on its own. Not one commit per file, not one giant commit.

**Propose by default.** Creating commits (`git add`, `git commit`) is an explicit-permission action: do it only when the orchestrator or the human explicitly says to execute, even in autonomous mode. Never push, amend, rebase, or rewrite history unless told. Never commit `agents/.run-state/` files (working state, gitignored) or coverage artifacts.

### 1. Read what actually changed

`git status`, `git diff` (staged and unstaged), and `git diff --stat`. Also look at untracked files. Anything outside the feature's scope (unrelated edits already in the tree) is **not** yours to bundle: list it separately and ask.

### 2. Group by concern

The pipeline's stage boundaries are usually the right commit boundaries, in dependency order so each commit builds:

1. Contract changes (`api designer`'s output — new signatures, abstractions)
2. Documentation (`api doc writer`)
3. Tests (`tester`)
4. Implementation (`implementer`) — one commit per plan step when steps are independently meaningful
5. Fixups from review gates — fold these into the commit they fix when they're small; keep separate only when they're a distinct concern

Adjust rather than follow blindly: fold a trivially small stage into the next; split a step that touched several unrelated concerns. **A test and the production code that makes it pass may share a commit** when a test-only commit would leave the branch red; say so.

For a fix, keep the **regression test in the same commit as the fix** (or immediately before it), so bisecting never lands on a fix without its test.

### 3. Split within a file when hunks are unrelated

If one file mixes concerns (the step's change plus an incidental formatting fix; two methods changed for unrelated reasons), propose hunk-level staging (`git add -p <file>`) rather than committing the whole file. Name exactly which hunks go where — by line range or by describing the hunk — so the proposal is executable.

Do not use `git add -i` or interactive rebase; they are not supported in this environment. If a hunk can't be split at the granularity you need, `git add -p` with `s` (split) or `e` (edit) is the tool.

### 4. Message format (doc-first)

Resolve the convention with the `resolve-project-conventions` skill (`CONTRIBUTING.md`/template first, then `git log` on recent non-merge commits): conventional-commits style (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`), scope prefixes, imperative mood, subject line length, whether bodies and footers are common. Whether commits start capitalized or not.

- Subject: imperative, no trailing period, states *what* changed at the level a reviewer scans.
- Body (if the convention uses one): *why*, not a re-description of the diff. Note breaking changes and migration.
- If the changes don't fit the inferred convention (a type it has no prefix for), don't force a fit silently: in human-gated mode ask whether a deviation is acceptable; in autonomous mode use the closest existing category and note the mismatch.
- Default branch is `main`, never `master`. Never suggest committing to `main` directly if the repo works via branches/PRs; check the current branch first.
- If the environment specifies an attribution trailer for commits (e.g. `Co-Authored-By:`), append it to every commit message exactly as specified; otherwise add none.

### 5. Pre-flight before proposing (or executing)

- Each proposed commit lists files/hunks that together compile: the analyzer should be clean at each commit if feasible. Say when a commit is intentionally not standalone-green and why.
- No secrets, no `.env`, no large generated artifacts in any commit.
- Every changed file appears in exactly one commit (or in the "not mine" list).

### Output format

```
## Proposed commits

### Commit 1
Files/hunks: path/a.dart (whole file), path/b.dart (hunk L10-40 only)
Message:
<type>(<scope>): <summary, matching this project's convention>

<body, if the convention typically includes one>

### Commit 2
...

## Not included
- <path> — <why: unrelated, run-state, generated>

## Convention
Source of truth: <CONTRIBUTING.md | inferred from N recent commits | no consistent pattern>
Deviations: <any, and how handled>
```

### Executing (only when explicitly told)

Stage per proposal (`git add <path>` / `git add -p`), verify with `git diff --cached --stat` that exactly the proposed content is staged, commit, and repeat. Report the resulting hashes and confirm `git status` is clean except for the "Not included" list. If a staging step doesn't produce exactly what was proposed, stop and report rather than committing something different.
