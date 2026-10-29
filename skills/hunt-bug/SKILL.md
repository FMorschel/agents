---
name: hunt-bug
description: "Use when the user reports something broken, a failing case, a crash, a stack trace or unexpected behavior and wants the cause found or fixed (\"why does X happen\", \"fix this\", \"this is broken\"). Runs the bug-hunt loop (hypothesis former → verifier, repeated), then, only if a fix is wanted, the regression-test-first fix flow."
---

## Hunting (and fixing) a bug

The orchestrator's *Bug hunt* entry point as a standalone flow. Do not spawn the `orchestrator` for the diagnosis; drive the two agents yourself.

### 1. Diagnose

1. Give `bug-hypothesis-former` the report, symptoms, logs, stack traces and repro steps. It returns a ranked list of falsifiable hypotheses. If the report is too thin to form any, ask the user for the missing symptom or repro; do not guess.
2. Hand hypotheses to `bug-verifier` **one per call, most likely first**. Independent hypotheses may be verified in parallel (one `Agent` call each, same message) when they touch different code paths and none needs the previous verdict; otherwise go sequentially.
3. CONFIRMED ends the hunt. REFUTED or INCONCLUSIVE goes back to `bug-hypothesis-former` with the verifier's evidence for the next batch. Stop when confirmed or the evidence runs out, and say which.

Neither agent edits code. The confirmed repro lands in the project's `specs/regression-test-backlog.md` via `bug-verifier` (format in `write-regression-test`).

### 2. Report the diagnosis

Root cause, evidence, the backlog entry, and what a fix would touch. If the user only asked "why", stop here and offer the fix.

### 3. Fix (only when the user wants it)

The fix's MVC is the narrowest change at the confirmed root cause plus its regression test. Nearby hardening or refactors are extras to ask about.

1. **Regression test first**: `test-writer` (existing code) or `tester` (a step in an active pipeline run) turns the backlog entry into a real test in the project's suite (see `write-regression-test`). Confirm it fails on the current code.
2. `implementer` makes it pass with the smallest change (`dart-edit-protocol`).
3. Run `evaluate-code`'s selection on the diff only, scoped to the fix (usually `architecture-guardian`, `convention-agent`, plus `test-adequacy-reviewer`).
4. A fix with no regression test is incomplete. Only an explicit "skip the regression test" from the user clears that, and then say so plainly and leave the backlog entry at "pending regression test". Otherwise set its Status to "regression test merged".
5. Offer `compose-commits` for the result.

If the fix turns out to need an API change or a new component, stop and ask rather than widening into the full pipeline; `plan-change` is the route if the user agrees.
