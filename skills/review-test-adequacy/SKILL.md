---
name: review-test-adequacy
description: "Use when the user asks what test cases are missing, what is not tested, whether existing tests are enough or actually pin the logic, or what to still test (\"missing test case(s)\", \"are these tests good enough\", \"what else should I test\"). Checks the tests against the finished implementation: per-branch depth (tautological assertions, negative paths, boundaries, unpinned business rules) and axis breadth from `test-case-matrix.md`. Report-only; it never writes tests. Used by `test adequacy reviewer` in the pipeline."
---

## Reviewing test adequacy

One question: do these tests exercise the business rules in the implementation, or do they just call the API and check it does not throw? Read the implementation (wherever the logic lives) next to the test file and check that each branch and rule has a meaningful assertion behind it. You need the finished code, because real implementations often have more branches than any contract implied.

You report gaps; you never write or edit tests. When the user asked what is missing, end by offering to write the cases through `improve-test-coverage` (do not start it).

### Standalone vs. pipeline

- **Pipeline** (`test adequacy reviewer` after `implementer`): the scope is the code **this step** added or changed, and you receive `tester`'s axis sweep to verify. Code the step did not touch is out of scope.
- **Standalone** (the user named a file, class, module or diff): whatever they named is in scope, pre-existing branches included. There is no inherited sweep, so run the sweep from `skills/write-dart-tests/test-case-matrix.md` yourself against the implementation. `[blocking]` has no gate to block here; keep the labels anyway so the list reads in priority order.

### Depth: is each branch pinned?

- **Tautological assertions**: `expect(result, isNotNull)` where the logic guarantees something specific; it should assert the actual expected value.
- **Missing negative paths**: an error/exception branch with no test forcing it. One per distinct failure path, not one per axis.
- **Boundary conditions**: a branch on `if (x > 0)` with no test at `x == 0` or `x < 0`.
- **Business rules with no dedicated test**: a rule (a specific validation, a specific ordering) that no test isolates; it may pass incidentally through another test without being pinned.

### Breadth: did the sweep cover the axes?

A suite can pin every branch it touches while touching one axis of the matrix and none of the others that apply. Run the sweep as a second pass, and verify any sweep you were handed rather than inheriting it. Three findings are specifically yours:

- **An N/A the implementation contradicts**: the sweep dismissed an axis, but the code visibly branches on it. That untested branch is a depth gap, so it is `[blocking]`.
- **Config sensitivity nobody tested**: grep for lint checks, analysis-option reads, feature flags, settings lookups. A config read that changes the result with no test setup for the other arm is worth reporting. `[blocking]` only when the contract depends on that arm, otherwise `[info]`.
- **An axis the implementation handles that no contract mentioned**: report the test gap, and call the scope question out separately for `gap-finder`/`scope-arbiter`. Do not resolve it yourself.

### Blocking vs. informational

Mark each finding `[blocking]` or `[info]`.

- **Depth** findings block: a branch or rule in scope that no test pins, or a tautological assertion standing in for a real one.
- **Breadth** findings are informational: axes the sweep missed, untested config arms, unplanned axes. They are reported so the human can decide.

If you are about to ask for a test "just because", for completeness, or to make code "more secure"/"more robust" when the request never mentioned it, it is not a gap. List it under `Unrequested extras` as a question ("is this necessary?").

### What not to do

- Second-guess test *style*; that is `convention agent`.
- Call a test wrong when the implementation is what is questionable. If a mismatch looks like an implementation bug, say so separately, and only if `dart analyze` does not already explain it (`dart-edit-protocol` epistemic rule). A real bug goes to `hunt-bug`.
- Decide what an unspecified axis *should* do. Naming it is your job; specifying it belongs to `api designer`/`task structurer`, the scope call to `scope arbiter`.
- Pad the axis section. A confirmed-inapplicable axis is a one-word entry, not a finding.

### Output

```
## Test adequacy: <Step N | target>

### Gaps
- [blocking] <business rule / branch> — not pinned by any test.
  Missing case: <what a test should assert>

### Axis coverage (breadth)
- <applicable axis> — verified covered by <test name(s)> | [info] GAP: <what's unexercised>
- [blocking] <axis> — sweep claimed N/A, but <path:L##> branches on it
Confirmed N/A: <axis>, <axis>, …

### Tautological / weak assertions
- [blocking] path/to/test.dart:L## — asserts <weak thing>, should assert <specific thing>

### Unplanned axis (→ gap-finder / scope-arbiter)
- [info] <axis> — implemented at path:L##, not present in any contract slice.

### Unrequested extras (→ human)
- <test you'd be tempted to ask for> — <why it goes beyond the request> — necessary?

### Adequate
- (one line, if no gaps)
```

Omit any empty section except **Axis coverage**, which always appears: applicable axes on their own lines, the rest in the single `Confirmed N/A:` line, so "swept" never looks like "nobody checked".
