---
name: flutter-conventions
description: "Use whenever you write, edit or review Flutter widget code: `State` classes (caching `.of(context)` lookups in didChangeDependencies, fixed lifecycle override order), widget composition (widget classes, not helper methods), rebuild scoping (narrow selectors, read vs. watch), theming, navigation, async UI states, and controller ownership/disposal. Index skill: load only the topic files that match the task."
---

## Flutter conventions

Companion to `design-dart-class` and `edit-dart-class` (generic class shape and ordering) and `review-flutter-async-and-disposal` (reviewer checklist for async, rebuild cost and leaks). Where a topic file below conflicts with those on the specific point it covers, the topic file wins.

Read only the files that match what you are touching:

| Touching… | Read |
| --- | --- |
| A `State<T>` class, `.of(context)` lookups, lifecycle method order | [state.md](state.md) |
| Splitting or extracting UI code | [widgets.md](widgets.md) |
| `context.watch`/`read`/`select`, Selector, listenable builders | [rebuilds.md](rebuilds.md) |
| Colors, text styles, spacing, `Theme.of` | [theming.md](theming.md) |
| Navigator/router calls, passing results back | [navigation.md](navigation.md) |
| FutureBuilder/StreamBuilder, loading/error/empty states | [async-ui.md](async-ui.md) |
| TextEditingController, FocusNode, AnimationController, etc. | [controllers.md](controllers.md) |

After editing Dart files, follow the post-edit Dart workflow from the global instructions: `dart fix --apply`, `dart analyze` (fix every diagnostic), then `dart format` on each edited file.
