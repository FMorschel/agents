---
name: write-dart-tests
description: "Use whenever you write or edit Dart/Flutter tests (`package:test`, `flutter_test`): file placement and naming, group/test structure, what makes an assertion meaningful, fakes vs. mocks, dependency injection, controlling time/randomness/file system/HTTP/plugins/databases in tests, test data, and the fail-first check. Also covers how to write up the axis sweep from `test-case-matrix.md`. Companion to `write-regression-test` for bug fixes."
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
- Mock library: whichever the project already uses. With none, pick per case: `mocktail` (no codegen) for a few stubs, `mockito` (`@GenerateMocks`) when its generated, type-checked mocks pay for the build step.
- Never mock the unit under test, and never mock away the logic the test claims to cover — a test whose every collaborator is stubbed and whose assertion restates the stub is tautological.

### Dependency injection

Tests should construct the unit with its fakes directly, with no wrapper widget, provider scope or locator setup in between.

- **Default:** constructor injection everywhere, with the abstraction as the parameter type. A service locator (`get_it`, read in widgets through `watch_it`) wires the real objects once at the app root; nothing below the root calls the locator, and tests never register into it.
- **The project wins:** if it already injects some other way (provider, riverpod, a locator read deep in the tree), follow it rather than introducing a second style.
- Do not reach for globals or `@visibleForTesting` seams unless the code already has them.

### Time, randomness, IO and platform

The packages named below are the user's pre-approved defaults for projects that have no equivalent yet: adding one as a dependency for this purpose needs no separate yes, but say so in the report. A project that already solves the problem another way keeps its way.

- **Now:** never `DateTime.now()` inside a test's expectation. Use `package:clock` (`clock.now()`) in code and `withClock` / a fake `Clock` in tests.
- **Timers, debounces, retries, delays:** `package:fake_async` (`fakeAsync((async) { …; async.elapse(const Duration(seconds: 5)); })`, combined with `withClock` when the code also reads the time); in widget tests, `tester.pump(duration)`. Never a real wait.
- **Randomness:** usually assert the shape (length, format, uniqueness), not the value. When the test needs a specific value, inject a `Random` or an ID-generator abstraction and pass `Random(42)` or a fake returning fixed IDs.
- **File system:** `package:file`. Production code takes a `FileSystem` (defaulting to `const LocalFileSystem()`), tests pass a `MemoryFileSystem` (`MemoryFileSystem.test(style: …)` when path style matters). A real temp directory only when the real OS behavior is the point, cleaned up in `tearDown`.
- **HTTP:** layers above the data source get a hand-written fake repository. Only the data source's own tests fake the wire, with `package:http`'s `MockClient` (or the Dio equivalent) injected through the constructor.
- **Plugins and platform APIs** (shared_preferences, path_provider, secure storage, `Platform.isX`, environment variables): wrap each behind a small project interface, injected through the constructor; tests pass a fake. Use `package:platform` (`LocalPlatform` / `FakePlatform`) for OS checks and environment, the way `package:file` covers disk.
- **Local databases:** follow the project. With nothing in place, data-source tests run the real engine in memory (`sqflite_common_ffi` with `inMemoryDatabasePath`, drift's `NativeDatabase.memory()`) so SQL and migrations are exercised; layers above get a fake repository. Seeding from a data dump is fine when it holds no sensitive data; anything with real personal data must be anonymized first (`review-sensitive-data`).
- **No network in unit tests.** If a test genuinely needs network (e.g. an integration test exercising a real client), it must never point at an official/production source — use a sandbox/staging endpoint, a local mock server, or a dedicated test account, never the real service.

### Test data

- **Builder functions** by default: one shared helpers file (match the repo's location, else `test/fixtures/`) with functions that have sensible defaults and named overrides, `aUser(name: 'Ana')`, so each test states only what matters to its case.
- **JSON fixture files** for API-shaped data (a response body, a serialization round-trip), under `test/fixtures/`, decoded in the test.

### Flutter UI

Widget, golden and integration test rules live in `write-flutter-ui-tests`; load it for any UI test. The short version:

- `testWidgets` with `pumpWidget`, `pump`/`pumpAndSettle` deliberately, finders by key or type, and dispose controllers you create.
- **Guard UI appearance with golden tests.** When a widget's look must stay the same (or a change to it must be deliberate), add a `matchesGoldenFile` assertion on the widget's finder, pumped at a fixed size and theme. Follow the repo's existing golden setup; if it has none, use `flutter_test`'s built-in `matchesGoldenFile` and say so in your report. Update goldens only for an intended visual change (`flutter test --update-goldens`), never to silence a failure.

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
