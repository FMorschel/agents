---
name: write-dart-tests
description: "Use whenever you write or edit automated tests in any language (Dart/Flutter with `package:test`/`flutter_test`, TypeScript/Angular, Java, Ruby): file placement and naming, group/test structure, what makes an assertion meaningful, fakes vs. mocks, dependency injection, controlling time/randomness/file system/HTTP/plugins/databases in tests, test data, the fail-first check, and how to write up the axis sweep from `test-case-matrix.md`. The Dart/Flutter detail is the most complete; the commands, runners and files for each language are in the `language-tooling` skill. Flutter widget, golden and integration tests are in `write-flutter-ui-tests`. Companion to `write-regression-test` for bug fixes."
metadata:
  scope: general
---

## Writing tests

This skill covers *how a test is written*, in any language. Deciding *which cases exist* is the axis sweep in `skills/write-dart-tests/test-case-matrix.md` — do that first, write the case list down, then use this skill to write them.

Commands, runners and files for each language are in the `language-tooling` skill. In Dart/Flutter, also load `write-flutter-ui-tests` for UI; for Angular, see the Angular section of the TypeScript file of `language-tooling`. The examples below alternate between languages; translate to the project's.

### Match the repo before anything else

Before writing the first test, look at 2–3 existing test files next to the code under test and copy their conventions: runner (Jest vs. Vitest vs. Jasmine, JUnit 5 vs. TestNG, RSpec vs. Minitest, `package:test` vs. `flutter_test`), assertion style, how fakes are built, fixture helpers, naming. Do not introduce a second convention into a repo that already has one. If there is genuinely nothing to copy, use the defaults below and say so in your report.

### File placement and naming

- Mirror the production code's layout under the tests, in the language's pattern: Dart `lib/src/foo/bar.dart` → `test/foo/bar_test.dart`; Java `src/main/java/.../Bar.java` → `src/test/java/.../BarTest.java`; Ruby `lib/foo/bar.rb` → `spec/foo/bar_spec.rb` (or `test/foo/bar_test.rb`); TypeScript/Angular `bar.ts` → `bar.spec.ts` (or `.test.ts`) next to the file, or under `__tests__/`/`test/`, as the project does. A project that already lays out its tests another way keeps its layout.
- One test file per unit under test. Split a file only when the unit itself was split.
- A folder (in Dart, `test/src/`) is reserved for testing infrastructure itself — reusable checkers/matchers, test simplification utilities, and similar cross-cutting test tooling — not test cases mirroring the production code.

### Structure

- One top-level group named after the unit (`group` in Dart, `describe` in Jest/Jasmine/RSpec, the test class in JUnit — `group('Paginator', ...)`), nested groups per method or behavior, and tests named as a sentence describing the behavior, not the method call: `'returns an empty page when the cursor is past the end'`, not `'getPage test 3'`.
- Arrange / act / assert in that order, separated by a blank line when the test is more than three lines. No logic (loops, conditionals) in a test body; if you need a loop, that is a table of cases — use the language's parameterization (a list of records in Dart, `it.each`/`test.each` in Jest, `@ParameterizedTest` in JUnit, `[...].each` or `shared_examples` in RSpec) and generate one test per row so a failure names its row. A loop *inside* a single test is fine when there are many cases that can be checked programmatically (e.g. asserting an invariant over a generated/large input set) rather than enumerated as named behaviors.
- Use the setup hook (`setUp`, `beforeEach`, `@BeforeEach`, `before`) for state that every test in the group needs and that is cheap to rebuild. Avoid sharing mutable state between tests through a top-level variable that is not reset in the setup.
- Every unit test is independent and order-insensitive. If a unit test needs another test to have run first, it is wrong. This doesn't apply to integration tests, where a deliberate ordered sequence of steps against a real/live system is often the point.
- Never disable a test (`skip`, `xit`, `@Disabled`, `pending`) to make the suite pass. If it is unavoidable, leave the reason and a reference (ticket, issue) on the test itself and report it.

### Tags

- **When to tag:** in a project that already uses tags (or categories, `@Tag`, RSpec `metadata`), or one with no tests yet, tag new tests as below. In a project that has tests but no tags, ask the user before introducing them; until they agree, don't tag.
- **Two kinds of tags, no others:**
  - **Feature** (`checkout`, `auth`): for a feature whose tests span folders (data source, repository, service, widgets), so filtering by it (in Dart, `dart test -t checkout`) runs all of it.
  - **Test type**, for speed: `slow` (over about a second), `golden` (alias `screenshot`), `db`. Agents' inner loop may exclude `slow` and `golden` (in Dart, `dart test -x slow -x golden`); the full suite still runs before anything is reported done (`dart-edit-protocol`).
  - **No layer tags.** Test folders mirror the production code, so selecting a folder (in Dart, `dart test test/data/`) already selects a layer.
- **Declare every tag** where the tool allows it (Dart `dart_test.yaml`: `tags: { checkout: {}, slow: {} }`; JUnit `@Tag` with a `junit-platform.properties`; RSpec `config.define_derived_metadata`), so a misspelled tag is reported instead of silently matching nothing. In Dart, put the tag on the file (`@Tags(['checkout'])` before `library;`) when every test in it shares it, on a `group`/`test` (`tags: ['slow']`) otherwise.

### Assertions that actually pin behavior

- Assert the **specific expected value**, never mere presence: `expect(page.items, [10, 11, 12])`, not `expect(page.items, isNotEmpty)`; `expect(result, isNotNull)` is only right when non-null is the whole contract.
- Prefer one behavior per test. Several `expect`s are fine when they describe the same behavior (an object's fields after one operation); several unrelated behaviors are several tests.
- Exceptions: check the **type** and, when the contract documents them, the message or fields. Dart: `expect(() => call(), throwsA(isA<FooException>()))` (message or fields with `having`); Jest: `expect(() => f()).toThrow(FooError)`; JUnit: `assertThrows(FooException.class, () -> f())`; RSpec: `expect { f }.to raise_error(FooError, /stable part/)`. `throwsA(anything)`, bare `throwsException` and "throws anything" are too weak.
- Async: always await. Dart: `await expectLater(future, completion(...))` / `throwsA`, and `emitsInOrder` for streams; Jest/Vitest/Jasmine: `await expect(promise).rejects.toThrow(...)`, and in Angular `fakeAsync` + `tick`/`flush` or `waitForAsync`; Java: `CompletableFuture.get(timeout)` or Awaitility; Ruby: wait for the result, never `sleep`. Never leave a future/promise un-awaited in a test; a passing test that never awaited its assertion is vacuous. For RxJS observables prefer marble tests (`TestScheduler`) or `firstValueFrom`/`subscribe` with `done`, and check that the test fails if the observable never emits. The general Dart `async`/`await` rule (`async` on anything returning a `Future`, `await` every future unless `unawaited(...)` or a diagnostic-specific `// ignore:`) in `review-flutter-async-and-disposal` applies to tests and helpers too.
- Every branch that changes the result gets a case on **both** sides, and boundaries get `x - 1`, `x`, `x + 1` (`0`, `-1` for counts and indexes).
- One negative case per *distinct failure path* (a declined input, an error path), not one global negative, and not one per axis when several axes fail the same way.

### Fakes vs. mocks

- Prefer a hand-written fake that implements the abstraction (`class FakeRepo implements Repo`, a class implementing the Java interface, an object satisfying the TypeScript type) over a generated mock; fakes keep the test about behavior and survive refactors that change call order.
- Use a mock only to verify an interaction that *is* the contract (a call that must happen exactly once, in a given order), and keep the number of stubbed calls small. Mocking is also the right tool for third-party surfaces you don't own — API/network calls, external package clients — where there's no in-repo abstraction to fake against.
- Mock library: whichever the project already uses (`mocktail`/`mockito` in Dart, `jest.fn`/`vi.fn`/Jasmine spies in TypeScript, Mockito in Java, RSpec `double`/`instance_double` in Ruby). With none, pick per case: in Dart, `mocktail` (no codegen) for a few stubs, `mockito` (`@GenerateMocks`) when its generated, type-checked mocks pay for the build step; in the other languages, the language's default.
- Never mock the unit under test, and never mock away the logic the test claims to cover — a test whose every collaborator is stubbed and whose assertion restates the stub is tautological.

### Dependency injection

Tests should construct the unit with its fakes directly, with no wrapper widget, provider scope or container setup in between.

- **Default:** constructor injection everywhere, with the abstraction as the parameter type. A service locator or container (`get_it`, read in widgets through `watch_it`, in Dart) wires the real objects once at the app root; nothing below the root calls it, and tests never register into it when the unit can be built directly.
- **The project wins:** if it already injects some other way (provider, riverpod, Spring, Angular `inject()`, a locator read deep in the tree), follow it rather than introducing a second style. In Angular, `TestBed.configureTestingModule({ providers: [{ provide: X, useValue: fake }] })` is the equivalent of passing the fake through the constructor, and services with no framework dependency should still be instantiated directly with `new`.
- Do not reach for globals or test-only seams (`@visibleForTesting`, exposed `protected` methods, `rewire`) unless the code already has them.

### Time, randomness, IO and platform

The packages named below are the user's pre-approved defaults for projects that have no equivalent yet: adding one as a dependency for this purpose needs no separate yes, but say so in the report. A project that already solves the problem another way keeps its way.

**Any other new dependency a test wants** (a database engine, an assertion helper, a fixture library) is an extra that needs the user's yes, unless its publisher is `dart.dev`, `tools.dart.dev`, `flutter.dev`, or one already used by a package in the project's `pubspec.yaml` (check with `pub_dev_search` or the package's pub.dev page). Without the yes, use what the project already has, or fake the dependency instead.

| Concern | Rule | Dart | TypeScript / Angular | Java | Ruby |
| --- | --- | --- | --- | --- | --- |
| **Now** | Never read the real clock in an expectation; inject a clock | `package:clock` (`clock.now()` in code, `withClock` / a fake `Clock` in tests); never `DateTime.now()` in an expectation | `jest.useFakeTimers().setSystemTime(...)` / `vi.setSystemTime`; Angular `fakeAsync` | injected `java.time.Clock`, `Clock.fixed(...)` | `travel_to` (ActiveSupport), Timecop |
| **Timers, debounces, retries, delays** | Advance a fake clock; never a real wait | `package:fake_async` (`fakeAsync((async) { …; async.elapse(const Duration(seconds: 5)); })`, combined with `withClock` when the code also reads the time); in widget tests `tester.pump(duration)` | `jest.advanceTimersByTime`, `vi.advanceTimersByTime`, `tick(ms)` in `fakeAsync` | Awaitility, injectable scheduler | Timecop, inject the `sleep` |
| **Randomness** | Assert the shape (length, format, uniqueness), not the value; when a value is needed, inject the source | inject a `Random` or an ID-generator abstraction; `Random(42)` or a fake returning fixed IDs | injected generator, fixed seed | `new Random(42)` / injected generator | `Random.new(42)` / injected generator |
| **File system** | Production code takes the abstraction; the test uses an in-memory one; a real temp directory only when the real OS behavior is the point, cleaned up at the end (Dart: `tearDown`) | `package:file`: production takes a `FileSystem` (default `const LocalFileSystem()`), tests pass a `MemoryFileSystem` (`MemoryFileSystem.test(style: …)` when path style matters) | `memfs`, or a temp directory (`os.tmpdir()`) | Jimfs, JUnit `@TempDir` | `FakeFS`, `Dir.mktmpdir` |
| **HTTP** | Layers above the data source get a hand-written fake repository; only the data source's own tests fake the wire | `package:http`'s `MockClient` (or the Dio equivalent) injected through the constructor | Angular `HttpTestingController` (`provideHttpClientTesting`), `msw` or `nock` in Node | WireMock, OkHttp `MockWebServer`, `MockRestServiceServer` | WebMock, VCR |
| **Plugins and platform APIs** (shared_preferences, path_provider, secure storage, `Platform.isX`, environment variables) | Wrap each behind a small project interface, injected through the constructor; the test passes a fake | `package:platform` (`LocalPlatform` / `FakePlatform`) for OS checks and environment, the way `package:file` covers disk | inject `window`/`localStorage`/`navigator` through a token | inject `System`/`Environment` through an interface | inject `ENV` or a config object |
| **Local databases** | Follow the project. With nothing in place, data-source tests run the real engine in memory so SQL and migrations are exercised; layers above get a fake repository | `sqflite_common_ffi` with `inMemoryDatabasePath`, drift's `NativeDatabase.memory()` | in-memory SQLite (`better-sqlite3`), Testcontainers | H2 or Testcontainers with the same engine as production | in-memory SQLite / `database_cleaner` transactions |

Seeding from a data dump is fine when it holds no sensitive data; anything with real personal data must be anonymized first (`review-sensitive-data`).

**No network in unit tests.** If a test genuinely needs network (e.g. an integration test exercising a real client), it must never point at an official/production source — use a sandbox/staging endpoint, a local mock server, or a dedicated test account, never the real service.

### Test data

- **Builder functions** by default: one shared helpers file (match the repo's location, else a `fixtures/` folder — in Dart `test/fixtures/`) with functions that have sensible defaults and named overrides, `aUser(name: 'Ana')` (or `aUser({ name: 'Ana' })`, `a_user(name: 'Ana')`, a Java builder), so each test states only what matters to its case. In Ruby, `FactoryBot` when the project already uses it.
- **JSON fixture files** for API-shaped data (a response body, a serialization round-trip), under `fixtures/`, decoded in the test.

### UI

Widget, golden and integration test rules for Flutter live in `write-flutter-ui-tests`; load it for any Flutter UI test. The short version:

- `testWidgets` with `pumpWidget`, `pump`/`pumpAndSettle` deliberately, finders by key or type, and dispose controllers you create.
- **Widgetbook use cases are part of a widget's tests where the project keeps a catalog.** Follow its convention: a new public widget or screen gets them (plus an `@Preview`), built from the same state builders the widget tests pump (`catalog-flutter-widgets`). Do not introduce a catalog just for testing.
- **Guard UI appearance with golden tests.** When a widget's look must stay the same (or a change to it must be deliberate), add a `matchesGoldenFile` assertion on the widget's finder, pumped at a fixed size and theme. Follow the repo's existing golden setup; if it has none, use `flutter_test`'s built-in `matchesGoldenFile` and say so in your report. Update goldens only for an intended visual change (`flutter test --update-goldens`), never to silence a failure.

**Angular.** Test the component with `TestBed` and `ComponentFixture` (and Angular Material/CDK `harnesses` when there are any), query the DOM by role or `data-testid`, not by CSS class, and call `fixture.detectChanges()` explicitly and deliberately.

**Any language:** a component test covers states (loading, empty, error, many items), not just the happy path, and a screenshot test only belongs where the appearance must stay the same.

### Fail-first check (contract-first work)

When the implementation does not exist yet, the tests must **fail against a stub** before you hand off, otherwise they may be vacuous. The stub: `throw UnimplementedError()` in Dart, `throw new Error('not implemented')` in TypeScript, `throw new UnsupportedOperationException()` in Java, `raise NotImplementedError` in Ruby. Run the suite and confirm each new test fails for the *expected* reason — a compile error or a wrong-reason failure means the test is not yet a real oracle.

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
- Write the cases the request and the contract ask for **and** the ones the sweep suggests, even "just because" or "for completeness": more tests help, and a test someone suggests (a sweep, a reviewer, the user, yourself) is written, never turned into a question and never left out. Only a test that needs a production-code change to pass is an "unrequested extra" to ask about (see "Suggested cases, even for completeness" in `test-case-matrix.md`).

### After editing

Follow the post-edit flow for the language (Dart: the `dart-edit-protocol` skill; the others: `language-tooling`). For contract-first tests, failures at the "run all tests" step in *this step's* suite are expected; only loop for tooling problems (format, analyzer/linter complaints in the test file).
