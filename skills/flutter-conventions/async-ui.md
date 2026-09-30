## Async UI states

Draft defaults; adjust to the project's state-management approach.

- Model async UI state explicitly: loading, error, empty and data are separate states, and every screen or section that loads data renders all four deliberately. A missing branch (no error UI, blank while loading) is a defect.
- Never create the `Future`/`Stream` inside `build` for `FutureBuilder`/`StreamBuilder`; create it once (in `initState`, a controller/provider, or a memoized field) so rebuilds don't restart it.
- Prefer having the controller/provider own the async call and expose a state object the widget just renders, over widgets awaiting directly (this also avoids `context`-after-`await` problems).
- A `StreamController` feeding a `StreamBuilder` is owned and closed by whoever created it, and it must not receive events after `close()` (guard with `isClosed`); a `Completer` backing a memoized `Future` is completed at most once (guard with `isCompleted`) and never left pending when its owner is disposed. Ownership and disposal details are in `controllers.md`.
- Keep loading/error/empty widgets as small shared widget classes (see `widgets.md`) so screens stay consistent, instead of re-inlining spinners and error text.
- Errors shown to the user are user-facing messages, not raw exception `toString()` output.
