---
name: triage-reviewer-findings
description: "Use whenever you receive findings from a reviewer, smell detector, memory-safety pass, adequacy pass, the user's pasted review list or your own sweep, and must decide what to do with each one: fix now with a regression test, ask the user, or do as a task-related refactor. Stops real defects from being parked as 'unrequested extras'."
---

## Triaging reviewer findings

Every finding gets exactly one verdict. Apply the questions in order; the first yes wins. Do not file a finding under "Unrequested extras" before answering question 1.

1. **Does the current code misbehave, crash, leak or lose an error on valid use?** Examples: a null-bang that can throw, an unawaited future, a subscription or controller not cancelled or disposed, an error swallowed, background work with no owner that outlives a failed start. → **Fix now**, in this change, with a regression test that fails on the old code (`write-regression-test`). Never ask first.
2. **Is it a missing test case?** → **Add the test.** Tests are never extras. A test that needs a production behavior change is a separate matter: that change goes through question 3.
3. **Would fixing it change what the user sees, what the API promises, or add something new?** New feature, changed semantics, different UX, new dependency, API reshaping, a rename unrelated to the task. → **Extra: leave it out and ask**, one line each: `- <what> (raised by <who>) — necessary?`
4. **Is it a refactor the task itself needs?** Typically the task needs something an existing function already does, so extract a shared helper and migrate the old caller too. → **Do it.** An unrelated "while I'm here" cleanup in the same file is question 3 instead.
5. **Is it wrong, or only an opinion?** A reviewer may only call code incorrect when `dart analyze` agrees (`dart-edit-protocol`, the epistemic rule). Otherwise treat it as a hypothesis: verify it before acting, and drop it with a note if it does not hold.

### Example

A reviewer reports: (1) `parse()` uses `!` on a lookup that can be missing; (2) the sync subscription is never cancelled in `dispose()`; (3) "add retry with backoff to `fetch()`"; (4) `_format()` duplicates `Money.format()`; (5) "rename `Foo` to `FooController`".

| # | Verdict | Why |
|---|---|---|
| 1 | Fix now + regression test | Can throw on valid input |
| 2 | Fix now + regression test | Leak on a normal path |
| 3 | Ask | New behavior |
| 4 | Do it | The task needs a formatter and one already exists |
| 5 | Ask | Rename unrelated to the task |

### Report

State the verdict per finding in the report, fixes first, so the user only has to answer the asked ones. In the pipeline, only items from question 3 go to the orchestrator's extras list. Blocking-finding routing stays as the orchestrator defines it.
