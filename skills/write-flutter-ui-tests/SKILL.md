---
name: write-flutter-ui-tests
description: "Use when writing or editing Flutter widget tests, golden (screenshot) tests or integration tests: which of the three to pick, how to build the widget under test (theme, size, platform, dependency injection), finder and wait rules, golden determinism and update discipline, and how integration tests are structured. Extends `write-dart-tests` for UI code."
---

## Flutter UI tests

Read `write-dart-tests` first; it covers file placement, naming, assertions and fakes. This skill adds what is specific to widgets. Match the repo's existing UI tests before using the defaults here (`resolve-project-conventions`).

### Pick the cheapest test that pins the behavior

| Need | Test | Notes |
|---|---|---|
| A widget shows/hides/enables something, reacts to a tap, calls a callback | **Widget test** (`testWidgets`) | default choice; fast, no device |
| A widget's *look* must not drift (layout, color, spacing, theme variants) | **Golden test** (`matchesGoldenFile`) | in addition to behavior assertions, never instead of them |
| A flow crosses screens, routing, real DI, storage or the backend | **Integration test** (`integration_test`) | slow; only for flows, never for single-widget logic |

Logic that can be tested without a widget (a view model, a controller, a formatter) belongs in a plain unit test. Do not pump a widget to test a function.

### Widget tests

- **Build the smallest tree that works.** Wrap the widget in `MaterialApp` (or the app's own themed wrapper) and a `Scaffold`; add providers and navigator keys only when the widget needs them. Put the wrapper in one `_buildApp` / `_pump` helper in the file so each test states only what varies.
- **Names state the behavior and the condition**, in the language and pattern the neighboring tests use (for example `DEVE exibir X QUANDO Y` / `NÃO DEVE ... QUANDO ...` when that is the repo's style).
- **Both sides of each condition**: shown and not shown, enabled and disabled, one case per value of an enum (a table of cases, so a failure names its row).
- **Find by something stable**: `find.byKey`, `find.byType`, `find.byTooltip`, `find.byIcon`, and `find.text` for user-visible labels that are the contract. Avoid index finders (`.at(3)`) and private types.
- **Interactions**: `tester.tap`, `enterText`, `drag`, then `pump()` for one frame, `pump(duration)` to step an animation. Use `pumpAndSettle()` only when you know it terminates; an infinite animation or progress indicator makes it time out, so pump explicit durations instead.
- **Dependencies**: reset and register fakes or mocks in `setUp` (reset the service locator before registering). Prefer the project's hand-written in-memory fakes (such as a `*_mock.dart` repository) when they exist. Never touch the network, real storage or real platform channels. Use a mock only for third-party surfaces and for interactions that are the contract.
- **Platform and theme variants**: set `debugDefaultTargetPlatformOverride` to test mobile vs. desktop behavior and **reset it in a `finally` or `addTearDown`** so it cannot leak into other tests. Test light and dark by pumping with the corresponding `ThemeData` / `themeMode`.
- **Size**: set the surface explicitly (`tester.view.physicalSize` and `devicePixelRatio`, with `addTearDown(tester.view.reset)`) for any layout, overflow or responsive test. A layout test at the default 800x600 proves nothing about a phone.
- **Overflow is a failure.** The framework reports it as an exception; fix the layout, do not catch the error. Add a narrow-size, long-text case for widgets that hold text.
- **Dispose** every controller, focus node and stream you create, in `addTearDown`.
- **Async**: `await` every `pump` / `tap`; never leave a `Future` un-awaited (`review-flutter-async-and-disposal`).

### Golden tests

- A golden pins appearance. Use it for components and screens whose look is a requirement; do not golden-test every widget.
- **Determinism first.** Fixed size and pixel ratio, fixed theme, fixed data (no `DateTime.now()`, random values or network images), fixed text scale, the same fonts. Animations must be finished or stopped on a known frame. A golden that differs between machines is a bug in the test: fix the cause, do not loosen the comparison. Agree with the repo on which platform generates the goldens.
- **Assert on the widget's finder**, not the whole screen, so unrelated changes do not break it: `await expectLater(find.byType(Foo), matchesGoldenFile('goldens/foo_dark.png'))`. Wrap in a `RepaintBoundary` when the finder does not isolate the widget.
- **One golden per meaningful variant**: light/dark, mobile/desktop width, and key states (empty, error, long text). Name the file after the variant (`foo_empty_dark.png`). Generate variants from a table of cases rather than copy-pasting.
- **Place goldens next to the test** (`test/.../goldens/`) and commit the images. Keep the surface component-sized so files stay small.
- **Update discipline.** `flutter test --update-goldens <file>` only for a change you intended, only for the files you intended, then **open the new images** and check them (`review-flutter-visual-changes` shows how). The golden diff in the commit must be explainable by the change. Never regenerate goldens to turn a red run green.
- **Fail-first for goldens** works in reverse: generate the golden from the current approved look, change the widget, confirm the golden test fails, then regenerate deliberately.

### Integration tests

- Live in `integration_test/`, one file per flow or screen group, named `*_test.dart`. Call `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` in `main`.
- **One app-initialization helper** in a shared utilities file (starts the app with seeded test data, such as profiles) plus shared step helpers for repeated sequences (log in, open the drawer, log out). Do not re-spell a multi-step sequence in each test.
- **Reuse known routes.** `.agents/screens-navigation/` may already describe how to reach a screen (steps, finders, preconditions); turn that into a shared step helper instead of rediscovering it, and keep the note in sync with the helper.
- **Describe the flow in the test name** as a short list of steps and validations, and comment each step in the body so a failure maps to a step. Use the project's test-helper package finders and waits if it has them (find by key/text, a `waitUntilVisible`).
- **Wait for conditions, not time.** Wait until a key or text is visible, then assert. Real flows wait on routines and network, so a fixed `pump(Duration)` is flaky; use fixed delays only to let a known animation finish.
- **Test data is test data**: dedicated test accounts and a local or sandbox backend, never production values. Keep credentials for those fixtures in the project's existing test utilities; do not add new ones in new files or paste them in chat.
- **Keep them few.** Cover the main flows and regressions that only appear across screens; push everything else down to widget or unit tests. Run with `flutter test integration_test/<file>` on desktop, or with a device id.
- Do not rely on test order; each test starts the app from a known state and cleans up what it created.

### Before reporting done

Run the new tests and their neighbors with `flutter test <paths>` (there is no MCP tool for it), then follow `dart-edit-protocol` for fix, format and analyze. A UI test you have not run is a draft. For appearance changes also run `review-flutter-visual-changes`.
