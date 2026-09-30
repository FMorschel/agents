---
name: write-dart-tests
description: "Use whenever you write or edit Dart/Flutter tests (`package:test`, `flutter_test`): file placement and naming, group/test structure, what makes an assertion meaningful, fakes vs. mocks, and the fail-first check. Also covers how to write up the axis sweep from `test-case-matrix.md`. Companion to `write-regression-test` for bug fixes."
---

## Writing Dart tests

This skill covers *how a test is written*. Deciding *which cases exist* is the axis sweep in `skills/write-dart-tests/test-case-matrix.md` — do that first, write the case list down, then use this skill to write them.

### Match the repo before anything else

Before writing the first test, look at 2–3 existing test files next to the code under test and copy their conventions: runner (`package:test` vs. `flutter_test`), assertion style, how fakes are built, fixture helpers, naming. Do not introduce a second convention into a repo that already has one. If there is genuinely nothing to copy, use the defaults below and say so in your report.

### File placement and naming

- Mirror `lib/` under `test/`: `lib/src/foo/bar.dart` → `test/foo/bar_test.dart`.
- One test file per unit under test. Split a file only when the unit itself was split.
- `test/src/` is reserved for testing infrastructure itself — reusable checkers/matchers, test simplification utilities, and similar cross-cutting test tooling — not test cases mirroring `lib/src/`.

### Structure

- One top-level `group` named after the unit (`group('Paginator', ...)`), nested `group`s per method or behavior, and `test`s named as a sentence describing the behavior, not the method call: `'returns an empty page when the cursor is past the end'`, not `'getPage test 3'`.
- Arrange / act / assert in that order, separated by a blank line when the test is more than three lines. No logic (loops, conditionals) in a test body; if you need a loop, that is a table of cases — use a list of records and generate one `test` per row so a failure names its row. A loop *inside* a single test is fine when there are many cases that can be checked programmatically (e.g. asserting an invariant over a generated/large input set) rather than enumerated as named behaviors.
- Use `setUp` for state that every test in the group needs and that is cheap to rebuild. Avoid sharing mutable state between tests through a top-level variable that is not reset in `setUp`.
- Every unit test is independent and order-insensitive. If a unit test needs another test to have run first, it is wrong. This doesn't apply to integration tests, where a deliberate ordered sequence of steps against a real/live system is often the point.

### Assertions that actually pin behavior

- Assert the **specific expected value**, never mere presence: `expect(page.items, [10, 11, 12])`, not `expect(page.items, isNotEmpty)`; `expect(result, isNotNull)` is only right when non-null is the whole contract.
- Prefer one behavior per test. Several `expect`s are fine when they describe the same behavior (an object's fields after one operation); several unrelated behaviors are several tests.
- Exceptions: `expect(() => call(), throwsA(isA<FooException>()))`, and check the message or fields with `having` when the contract documents them. `throwsA(anything)` and bare `throwsException` are too weak.
- Async: `await expectLater(future, completion(...))` / `throwsA`, and `emitsInOrder` for streams. Never leave a future un-awaited in a test; a passing test that never awaited its assertion is vacuous. The general `async`/`await` rule (`async` on anything returning a `Future`, `await` every future unless `unawaited(...)` or a diagnostic-specific `// ignore:`) in `review-flutter-async-and-disposal` applies to tests and helpers too.
- Every branch that changes the result gets a case on **both** sides, and boundaries get `x - 1`, `x`, `x + 1` (`0`, `-1` for counts and indexes).
- One negative case per *distinct failure path* (a declined input, an error path), not one global negative, and not one per axis when several axes fail the same way.

### Fakes vs. mocks

- Prefer a hand-written fake that implements the abstraction (`class FakeRepo implements Repo`) over a generated mock; fakes keep the test about behavior and survive refactors that change call order.
- Use a mock only to verify an interaction that *is* the contract (a call that must happen exactly once, in a given order), and keep the number of stubbed calls small. Mocking is also the right tool for third-party surfaces you don't own — API/network calls, external package clients — where there's no in-repo abstraction to fake against.
- Never mock the unit under test, and never mock away the logic the test claims to cover — a test whose every collaborator is stubbed and whose assertion restates the stub is tautological.
- Inject dependencies through the constructor as abstractions (matches the layered architecture); do not reach for globals or `@visibleForTesting` seams unless the code already has them.

### Time, randomness, IO

- Inject a clock / random source; never `DateTime.now()` inside a test's expectation. Prefer `package:clock` (`clock.now()`) over a hand-rolled clock abstraction, and use `withClock`/a fake `Clock` in tests to control it.
- Use in-memory implementations or temp directories for IO, cleaned up in `tearDown`.
- **No network in unit tests.** If a test genuinely needs network (e.g. an integration test exercising a real client), it must never point at an official/production source — use a sandbox/staging endpoint, a local mock server, or a dedicated test account, never the real service.
- For Flutter: `testWidgets` with `pumpWidget`, `pump`/`pumpAndSettle` deliberately, finders by key or type, and dispose controllers you create.

### Fail-first check (contract-first work)

When the implementation does not exist yet, the tests must **fail against a stub** (`throw UnimplementedError()`) before you hand off, otherwise they may be vacuous. Run the suite and confirm each new test fails for the *expected* reason — a compile error or a wrong-reason failure means the test is not yet a real oracle.

When backfilling tests for existing code, the opposite holds: run them and confirm they pass against the current implementation. A suite you have not run is a draft, not a deliverable.

### Writing up the axis sweep

List each **applicable** axis from `skills/write-dart-tests/test-case-matrix.md` on its own line, then dismiss everything else in one line:

```
- <axis> — covered by <test name(s)> | CONTRACT SILENT → gap-finder      (greenfield)
- <axis> — covered by <test name(s)> | UNTESTABLE: <why>                    (backfill)
N/A: <axis>, <axis>, … (<a few words why, only if not obvious>)
```

Every axis still shows up somewhere, either on its own line or in the `N/A:` line, so "checked and dismissed" never looks the same as "forgotten". But a dismissed axis costs a few words, not a paragraph and never a test. A contract-silent axis is reported, not invented: do not guess an expected value the contract never promised.

### Scope

- `tester` never edits production files; `implementer` never edits test files. If a test cannot pass without a production change, report it as an implementation requirement.
- Do not test private members directly; test them through the public behavior that uses them. If that is impossible, the design needs the discussion, not the test a workaround.
- Test what the request and contract ask for. If you're adding tests "just because", for completeness, or to harden something against a threat the request never mentioned, stop: list them under `Unrequested extras` as a question for the human, and leave them out unless they say yes.

### After editing

Follow the `dart-edit-protocol` skill. For contract-first tests, failures at the "run all tests" step in *this step's* suite are expected; only loop for tooling problems (format, analyzer complaints in the test file).
