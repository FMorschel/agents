## Controllers and disposal ownership

Covers `TextEditingController`, `FocusNode`, `ScrollController`, `PageController`, `TabController`, `AnimationController`, `ValueNotifier`, `StreamController` and similar. The reviewer checklist for leaks lives in `review-flutter-async-and-disposal`; this is the rule for writing them.

- **The class that creates it owns it and disposes it.** Create in `initState` (or as a `late final` field initializer) and dispose in `dispose`. Never dispose a controller that was passed in.
- Declare owned controllers `late final` (or `final` with an initializer) and non-nullable; they are created once and never reassigned.
- Dispose in `dispose()` before `super.dispose()`, in reverse order of creation. Cancel subscriptions and timers and remove listeners there too.
- Controllers that need a `vsync` use `SingleTickerProviderStateMixin` / `TickerProviderStateMixin` on the `State`.
- If a controller's configuration depends on widget properties, update it in `didUpdateWidget` (comparing `oldWidget`), don't recreate it in `build`.
- **`StreamController`s** follow the same ownership rule: the creator calls `close()` in `dispose()` (before `super.dispose()`), and any `StreamSubscription` it listens with is cancelled there too. Prefer a single-subscription controller unless multiple listeners are genuinely needed (`StreamController.broadcast`). Don't add to a controller after closing it: guard with `isClosed` when events can arrive late.
- **`Completer`s** have no `dispose`, but the owner must not complete one twice: guard with `if (!completer.isCompleted)` before `complete`/`completeError`, especially when several paths (success, error, cancel, `dispose`) can race to finish it. Complete or error any pending completer in `dispose()` so awaiters aren't left hanging forever.
- Never create controllers inside `build`.
