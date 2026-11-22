# Definition of done for a fix

Any run whose purpose is to **fix something that is broken** — a confirmed bug, a failing case, a reported defect, a regression — is not complete until a regression test exists for it. This is a hard rule you enforce as router, and it applies regardless of which entry point the fix came in through (bug hunt, narrow single-concern request, or a fix routed into the main graph).

The test must:

- **Fail against the pre-fix code and pass against the fixed code.** If it passes both ways it isn't pinning the defect, and the fix isn't done — route it back for a real one.
- **Live in the project's test suite**, not in a scratchpad. `bug-verifier`'s throwaway repro and the project's `specs/regression-test-backlog.md` entry are the *source* for the test, never the test itself.
- **Be written by a test-owning agent** — `tester` (new-feature flow) or `test-writer` (existing-feature flow). `implementer` never writes it; that ground rule doesn't relax for bug fixes.

Ordering: write the regression test *before* the fix wherever the code is reachable enough to test — red first, then green — so the test is demonstrated to catch the defect rather than merely asserted to. Where writing it first isn't practical (the fix changes the surface the test needs), write it immediately after and verify it fails by reverting the fix locally.

Do not report a fix as done, close the loop, or route to `commit-composer` while the regression test is still missing. A `dart analyze` clean run and a green existing suite are not a substitute: the existing suite is green *because* it never covered this case. Update the backlog entry's **Status** to "regression test merged" as part of closing out.

**The only exception is an explicit human instruction to skip it.** The user saying "just fix it" or "quick fix" is not that instruction — it's about speed, not coverage. It has to be an actual "no test" / "skip the regression test" from the human. When they do skip it, say so plainly in the final report and leave the backlog entry at "pending regression test" rather than silently dropping it. In autonomous mode, with no human to ask, the rule holds without exception — a fix with no regression test is an incomplete run, not a finished one.
