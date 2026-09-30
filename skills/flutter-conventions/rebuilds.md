## Rebuild scoping

- **`watch` only in `build`.** `context.watch<T>()` (and `Provider.of<T>(context)` with listening on) registers a rebuild dependency, so it belongs in `build` and nowhere else.
- **`read` in callbacks and lifecycle methods.** Event handlers (`onPressed`, `onChanged`), `initState` follow-ups and other non-`build` code use `context.read<T>()` (or a value cached per `state.md`). Never `watch` in a callback.
- **Narrow selectors.** Watch the smallest slice that the widget renders: `context.select((Foo f) => f.name)`, `Selector`, or `ValueListenableBuilder` on a single `ValueNotifier`, instead of watching a whole `ChangeNotifier`/model when only one field is used.
- **Push the watch down.** If only one leaf depends on a changing value, put the `watch`/`select` in that leaf (a small widget class, see `widgets.md`) so ancestors and siblings don't rebuild.
- Prefer `const` child subtrees so a rebuilt parent doesn't rebuild static children.
