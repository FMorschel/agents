---
name: catalog-flutter-widgets
description: "Use whenever you add or change a public Flutter widget or screen, write or review its UI tests, or are asked about Widgetbook, widget catalogs or the Flutter Widget Previewer (`@Preview`). Every new public widget and screen gets a Widgetbook use case and an `@Preview`: they are part of its test coverage (shared state builders for widget, golden and accessibility tests; visual regression where Widgetbook Cloud is set up) and let it be reviewed, accessibility included, at different sizes, text scales, themes and text directions. Says what each entry covers, who writes it, where it goes, and what to do when the project has no Widgetbook yet."
---

## Cataloging Flutter widgets

A Widgetbook entry is **part of a widget's tests**, not documentation next to them. It does two jobs:

- **Testing.** Its use cases are the widget's named states, built once and reused by the widget, golden and accessibility tests (see "Use cases as test fixtures"). Where the project runs Widgetbook Cloud, each use case is snapshotted across the addon combinations on every PR, which is visual regression testing at a breadth hand-written goldens rarely reach.
- **Review.** A human (or `flutter visual reviewer`) can look at the widget in isolation and check its layout and accessibility at different sizes and text scales without navigating the app to reach it.

So a new public widget without its use cases has a test gap, the same way it would without a widget test. Automated accessibility guideline tests still live in `write-flutter-ui-tests`; the catalog adds the cases a guideline test cannot judge (does it still read well at 2.0, in RTL, on a small phone).

### Who writes it

- **Widgetbook use cases** live in the `widgetbook/` package, outside `lib/`, and count as test files: `tester` (or `test-writer` when backfilling) writes them, together with the widget's tests and from the same state builders.
- **`@Preview` functions** sit in `lib/` next to the widget, so they are production code: `implementer` writes them.

### Which widgets get an entry

- **Every new public widget and every new screen**, and an existing one whose public constructor or look changed.
- **Not private helper widgets** (`_Foo`) inside a screen or widget file; they are covered through their parent's entry. Do not make a widget public just to catalog it.

### Where Widgetbook lives

All Widgetbook files go in a `widgetbook/` package beside `lib/` (at the app package's root), never inside `lib/` or `test/`, and that package is part of a **pub workspace** with the app (Dart 3.6+):

```yaml
# pubspec.yaml (the app)
workspace:
  - widgetbook
dev_dependencies:
  app_widgetbook: any        # tests import the shared state builders from here

# widgetbook/pubspec.yaml
name: app_widgetbook
resolution: workspace
dependencies:
  app: any                   # the widgets under review
  widgetbook: …
```

The app depending on `app_widgetbook` as a dev dependency while `app_widgetbook` depends on the app is a cycle pub resolves inside a workspace (checked: `pub get` succeeds and a test in the app imports a builder from `app_widgetbook`). A workspace member's SDK constraint and shared dependency versions must agree with the root's. If the project already keeps Widgetbook somewhere else, follow it and do not move it unasked.

Within the package, follow the project's existing setup (annotation style `@widgetbook.UseCase` vs. a manual tree, naming); with nothing to copy, mirror `lib/`'s folders and keep the state builders in `widgetbook/lib/src/states/`, separate from the use cases that wrap them.

### Widgetbook use case

Each entry:

- **One use case per meaningful state**: default, empty, loading, error, disabled, long content (a 200-character name, a single unbroken 60-character word). The same states the widget's tests and goldens cover.
- **Knobs** for the constructor parameters a reviewer would want to vary (text, enabled, counts), with realistic defaults.
- **Addons** (configured once in the Widgetbook app, not per use case): device/viewport sizes from a small phone to desktop, text scale (at least 1.0, 1.5 and 2.0), light and dark theme, and a left-to-right and a right-to-left locale. A use case that only renders correctly at one of these is a finding for review, not something to hide by locking the addon.
- **Fakes, not real services**: the widget gets its dependencies through its constructor (see `write-dart-tests`, Dependency injection), so the use case passes fakes or builder-function data. Never point a use case at a real backend or real personal data.

### Use cases as test fixtures

The states in the catalog and the states under test must be the same states, built by the same code, so they cannot drift apart.

- Each use case's widget comes from a plain builder function (`Widget buildUserCardLongName()`, using the builder-function test data from `write-dart-tests`) in `widgetbook/lib/src/states/`, which the app's tests import through the `app_widgetbook` dev dependency (see Where Widgetbook lives). The use case wraps it with knobs; the tests pump it directly.
- Widget tests assert behavior on those states, golden tests pin their look, and the accessibility guideline test runs over each of them (`write-flutter-ui-tests`).
- **Widgetbook Cloud**, when the project uses it, already snapshots every use case per addon combination and asks for review on the PR. Follow its review flow: an unexplained snapshot difference is a regression, the same rule as a failing golden. Do not duplicate in local goldens what Cloud already pins, unless the project keeps both deliberately. Never set it up unasked (it is an external service).

### `@Preview` (Flutter Widget Previewer)

Add an `@Preview` from `package:flutter/widget_previews.dart` alongside each Widgetbook use case, for the widget's default state at least:

- On a top-level (or static) function with no parameters that returns the widget, built with the same fakes as the Widgetbook use case. Put it in the widget's file or the project's preview location, matching what the repo already does.
- Build it from the same state builder as the Widgetbook use case and the tests.
- Use the annotation's parameters the installed Flutter version supports (`name`, `size`, `textScaleFactor`, `brightness`, a wrapper for theme or localization) to show the variants a reviewer needs most, at minimum a larger text scale.
- Check that the project's Flutter version ships `widget_previews.dart` before adding one. If it does not, skip `@Preview` and say so in the report instead of upgrading Flutter.

### When the project has no Widgetbook yet

Do not scaffold a Widgetbook app unasked: it is a new package, a new app target and a workspace change to the root `pubspec.yaml`. Propose the setup once (the `widgetbook/` workspace package above, and which addons), and until the user says yes, add only the `@Preview` (when the Flutter version supports it) and list the missing Widgetbook entries in the report. Still write the state builders, in the test helpers the repo already uses, so the tests use them now; moving them into `widgetbook/lib/src/states/` is part of the setup.

### Before reporting done

- The Widgetbook app and previews build (`flutter analyze`, and run code generation when the project uses the annotation generator), following `dart-edit-protocol`.
- Open the new entries at the largest text scale and in right-to-left at a phone size. An overflow, clipped text, an unlabeled icon button or a tap target that shrinks is reported, and fixed if it is in the widget you just wrote.
