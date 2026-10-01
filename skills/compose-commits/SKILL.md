---
name: compose-commits
description: "Use when splitting a completed piece of work into commits for a human reviewer: grouping by logical concern (pipeline stages by default), hunk-level splitting inside a single file, matching the project's commit message convention, and the propose-by-default / execute-only-when-told rule. Used by `commit composer` at the end of the pipeline."
---

## Composing commits

The goal is commits a reviewer wants to read: grouped by *logical concern*, each one understandable and (ideally) building on its own. Not one commit per file, not one giant commit.

**Propose by default.** Creating commits (`git add`, `git commit`) is an explicit-permission action: do it only when the orchestrator or the human explicitly says to execute, even in autonomous mode. Never push, amend, rebase, or rewrite history unless told. Never commit `agents/.run-state/` files (working state, gitignored) or coverage artifacts.

### 1. Read what actually changed

`git status --porcelain`, `git diff` (staged and unstaged), and `git diff --stat`. Also look at untracked files. Anything outside the feature's scope (unrelated edits already in the tree) is **not** yours to bundle: list it separately and ask. If there is nothing to commit, say so and stop.

### 2. Group by concern

The pipeline's stage boundaries are usually the right commit boundaries, in dependency order so each commit builds:

1. Contract changes (`api designer`'s output — new signatures, abstractions)
2. Documentation (`api doc writer`)
3. Tests (`tester`)
4. Implementation (`implementer`) — one commit per plan step when steps are independently meaningful
5. Fixups from review gates — fold these into the commit they fix when they're small; keep separate only when they're a distinct concern

Adjust rather than follow blindly: fold a trivially small stage into the next; split a step that touched several unrelated concerns. **A test and the production code that makes it pass may share a commit** when a test-only commit would leave the branch red; say so.

For a fix, keep the **regression test in the same commit as the fix** (or immediately before it), so bisecting never lands on a fix without its test.

Dart/Flutter specifics:

- Generated files (`*.g.dart`, `*.freezed.dart`, …) go in the same commit as the source that triggers them.
- `pubspec.yaml` changes go in the first commit that needs the dependency; `pubspec.lock` always travels with its `pubspec.yaml` change, never alone.
- Pure `dart format` / `dart fix` churn on lines the feature didn't otherwise change goes in its own `style`/`chore` commit (or is left out and asked about), not mixed into logic commits.

### 3. Split within a file when hunks are unrelated

If one file mixes concerns (the step's change plus an incidental formatting fix; two methods changed for unrelated reasons), split it by hunk rather than committing the whole file.

**Describe hunks by content, not just position.** Line numbers shift once an earlier commit lands, so name each hunk by symbol and a one-line summary (e.g. "`parse()` null-check added"); give the line range only as a hint.

`git add -p`, `git add -i` and interactive rebase need an interactive prompt and do not work in this environment. Stage hunks non-interactively instead:

1. Write the per-commit diff to a patch file in the scratchpad directory: `git diff -U0 -- <file>` (zero context makes hunks independent), keep only the wanted hunks (delete the others, leave the `diff`/`---`/`+++` headers).
2. `git apply --cached --unidiff-zero <patch>` to stage exactly those hunks.
3. Verify with `git diff --cached` before committing. If it isn't exactly the intended content, `git reset -- <file>` (unstages only; the working tree is untouched) and redo it.

When proposing, you may save the patches per commit and reference them, so execution is deterministic. `git add -p` stays valid as a fallback for a human to run.

### 4. Message format (doc-first)

Resolve the convention with the `resolve-project-conventions` skill (`CONTRIBUTING.md`/template first, then `git log` on recent non-merge commits): conventional-commits style (`feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`), scope prefixes, imperative mood, subject line length, whether bodies and footers are common. Whether commits start capitalized or not.

- Subject: imperative, no trailing period, states *what* changed at the level a reviewer scans.
- Body (if the convention uses one): *why*, not a re-description of the diff. Note breaking changes and migration.
- If the changes don't fit the inferred convention (a type it has no prefix for), don't force a fit silently: in human-gated mode ask whether a deviation is acceptable; in autonomous mode use the closest existing category and note the mismatch.
- Default branch is `main`, never `master`. Never suggest committing to `main` directly if the repo works via branches/PRs; check the current branch first.
- If the environment specifies an attribution trailer for commits (e.g. `Co-Authored-By:`), append it to every commit message exactly as specified; otherwise add none.

### 5. Pre-flight before proposing (or executing)

- **Completeness:** the union of all proposed paths plus the "Not included" list must equal `git status --porcelain` (untracked files included). Every changed file appears in exactly one commit or in "Not included" — a file split by hunks appears in several commits, but every hunk of it lands exactly once.
- **Each commit builds:** each commit's content should compile and the analyzer should be clean at that point. When executing, check this per commit against the staged state only (`git stash push --keep-index --include-untracked`, run the Dart MCP analyze tool, then `git stash pop`), or in a temporary worktree. If you skip the check, say so in the report. Say when a commit is intentionally not standalone-green and why.
- No secrets, no `.env`, no large generated artifacts in any commit.

### Output format

```
## Proposed commits

### Commit 1
Files/hunks: path/a.dart (whole file), path/b.dart (hunk: `parse()` null-check, ~L10-40)
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

Stage per proposal (`git add <path>` for whole files, the patch method in §3 for hunks), verify with `git diff --cached --stat` that exactly the proposed content is staged, commit, and repeat. Report the resulting hashes and confirm `git status` is clean except for the "Not included" list.

If a staging step doesn't produce exactly what was proposed, **stop** and report rather than committing something different. The report must state which commits already landed (hashes), what is currently staged, and which proposed commits remain. Do not reset or undo landed commits.
