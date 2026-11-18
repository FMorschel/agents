---
name: catalog-flutter-widgets
description: "Use whenever you add or change a public Flutter widget or screen, or when asked about Widgetbook, widget catalogs or the Flutter Widget Previewer (`@Preview`). Every new public widget and screen gets a Widgetbook use case and an `@Preview`, so it can be reviewed, accessibility included, at different sizes, text scales, themes and text directions. Says what each entry covers, where it goes, and what to do when the project has no Widgetbook yet."
---

## Cataloging Flutter widgets

The point is **review**: a human (or `flutter visual reviewer`) can look at a widget in isolation and check its layout and accessibility at different sizes and text scales without navigating the app to reach it. It complements tests, it does not replace them: automated accessibility guideline tests still live in `write-flutter-ui-tests`.

### Which widgets get an entry

- **Every new public widget and every new screen**, and an existing one whose public constructor or look changed.
- **Not private helper widgets** (`_Foo`) inside a screen or widget file; they are covered through their parent's entry. Do not make a widget public just to catalog it.

### Widgetbook use case

Follow the project's existing Widgetbook setup (folder, annotation style `@widgetbook.UseCase` vs. a manual tree, naming). Each entry:

- **One use case per meaningful state**: default, empty, loading, error, disabled, long content (a 200-character name, a single unbroken 60-character word). The same states the widget's tests and goldens cover.
- **Knobs** for the constructor parameters a reviewer would want to vary (text, enabled, counts), with realistic defaults.
- **Addons** (configured once in the Widgetbook app, not per use case): device/viewport sizes from a small phone to desktop, text scale (at least 1.0, 1.5 and 2.0), light and dark theme, and a left-to-right and a right-to-left locale. A use case that only renders correctly at one of these is a finding for review, not something to hide by locking the addon.
- **Fakes, not real services**: the widget gets its dependencies through its constructor (see `write-dart-tests`, Dependency injection), so the use case passes fakes or builder-function data. Never point a use case at a real backend or real personal data.

### `@Preview` (Flutter Widget Previewer)

Add an `@Preview` from `package:flutter/widget_previews.dart` alongside each Widgetbook use case, for the widget's default state at least:

- On a top-level (or static) function with no parameters that returns the widget, built with the same fakes as the Widgetbook use case. Put it in the widget's file or the project's preview location, matching what the repo already does.
- Use the annotation's parameters the installed Flutter version supports (`name`, `size`, `textScaleFactor`, `brightness`, a wrapper for theme or localization) to show the variants a reviewer needs most, at minimum a larger text scale.
- Check that the project's Flutter version ships `widget_previews.dart` before adding one. If it does not, skip `@Preview` and say so in the report instead of upgrading Flutter.

### When the project has no Widgetbook yet

Do not scaffold a Widgetbook app unasked: it is a new package and a new app target. Propose the setup once (where it would live, which addons), and until the user says yes, add only the `@Preview` (when the Flutter version supports it) and list the missing Widgetbook entries in the report.

### Before reporting done

- The Widgetbook app and previews build (`flutter analyze`, and run code generation when the project uses the annotation generator), following `dart-edit-protocol`.
- Open the new entries at the largest text scale and in right-to-left at a phone size. An overflow, clipped text, an unlabeled icon button or a tap target that shrinks is reported, and fixed if it is in the widget you just wrote.
