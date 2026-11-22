---
name: review-working-tree-changes
description: "Use when the user asks to review, check or sanity-check what is currently changed in the working tree before committing ('review my changes', 'look over the diff', 'anything wrong before I commit?'): cover staged, unstaged, untracked and ignored-but-relevant files, run analyze and tests, and report. Report-only; for pipeline review gates use `evaluate-code`."
---

## Reviewing the working tree

1. **See everything that changed**: `git status --porcelain`, `git diff`, `git diff --cached`, and the contents of untracked files (they are not in the diff). Note files that look like they should be ignored or never committed (`.env`, run-state, build output, local settings).
2. **Say what the change is** in two lines, from the diff, before judging it.
3. **Check, in this order**: it does what the user said it should; nothing unrelated is mixed in (list it separately); generated files travel with their source; leftover debug output, `skip:`, `// ignore:`, TODOs added by this change; secrets and personal data (`review-sensitive-data`).
4. **Run the checks**: analyze and the full test suite once (`dart-edit-protocol`), and report the results with numbers. Don't call code incorrect unless the analyzer or a failing test agrees; otherwise it is a hypothesis.
5. **For depth**, hand the diff to `evaluate-code` (it selects the review agents) instead of doing every review yourself.
6. **Report**: blocking problems first, then smaller ones, then what you did not check. Don't edit anything unless asked. When the user then says to commit, use `compose-commits`.
