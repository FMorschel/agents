---
name: write-regression-test
description: "Use whenever a bug is being fixed, or when converting a `regression-test-backlog.md` entry into a real test. Defines how to write a regression test that provably fails on the pre-fix code and passes on the fix, where it lives, who writes it, and how the backlog entry is closed. Companion to `write-dart-tests`."
---

## Writing a regression test

A fix is not done until a regression test pins the defect. A green suite and a clean `dart analyze` are not a substitute — the suite is green precisely because it never covered this case. The only thing that lifts this rule is an explicit human "no test" / "skip the regression test"; "just fix it" is about speed, not coverage. If it is skipped, say so plainly in the report and leave the backlog entry at *pending regression test*.

Write the test itself following `write-dart-tests`; this skill adds what is specific to regressions.

### Who writes it

- **Test-owning agents only**: `tester` (new-feature flow) or `test writer` (existing-feature flow). `implementer` never writes it, even for a one-line fix. The implementer reports `fix applied — regression test still needed`.
- `bug verifier` never writes it either: its throwaway repro and the backlog entry are the *source* for the test, not the test.

### Source material

1. Find the entry in `agents/Bug Hunt/regression-test-backlog.md` for this module (or the report/issue if there is none). Take the **defect location**, **what went wrong**, and the **minimal repro**.
2. Read the defect location yourself. The repro shows *that* it fails; you need to know *why*, so the test asserts the right thing and not the incidental symptom.

### Shape of the test

- **Assert the correct behavior, not the bug.** The test describes what should happen (`'last page cursor does not point past the end'`), never what the buggy code did.
- **Name it after the behavior**, and reference the bug ID in a one-line comment only if the *why* is non-obvious: `// Regression: BUG-001, off-by-one when length is a multiple of pageSize.` Don't narrate the fix.
- **Smallest input that triggers the defect**, and add the neighbors that bound it: the failing value plus the value just below and above (`24`, `25`, `26` items). Regressions usually live at a boundary, and the neighbors stop a "fix" that only patches the one reported value.
- **Same public entry point the bug was reported through**, not the private helper where the defect happens to sit. A test at the helper survives a refactor that reintroduces the bug one layer up.
- **Deterministic.** If the original failure was a race or timing issue, control the clock/scheduler/completer so the test forces the bad interleaving instead of hoping for it. A flaky regression test is worse than none.
- Put it in the module's existing test file, in a `group('regressions', ...)` (or the file's existing convention), not in a new scratch file.

### Prove it catches the defect (red → green)

The test must **fail against the pre-fix code and pass against the fixed code**. A test that passes both ways is not pinning the defect.

- **Preferred order — test first:** write the test while the bug is still present, run it, confirm it fails *for the reason in the backlog entry* (not a compile error or an unrelated failure), then let the fix land and confirm green.
- **If the fix changes the surface the test needs**, write the test right after the fix, then verify: locally revert *only the production change* (`git stash push -- <production files>` or an equivalent temporary edit), run the new test, confirm red, restore the fix, confirm green. Never commit the reverted state.
- Report both runs: which test, failing output on old code (one line), passing on new.

### Closing the loop

- Update the backlog entry's **Status** from *pending regression test* to *regression test merged*, in the same change as the test.
- Run the full suite, then follow the `dart-edit-protocol` skill.
- Do not route to `commit-composer` while the regression test is missing; that is a blocking gap, on the same footing as an architecture violation.

### When the bug can't be reproduced in a unit test

Escalate to the smallest test level that can (integration or widget test) rather than dropping the test. If no automated test is feasible, do not silently skip: state why, propose the closest guard (an assertion, a lint, a documented manual check), and get an explicit human decision.
