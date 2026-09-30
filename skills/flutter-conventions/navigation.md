## Navigation and routing

Draft defaults; the project's router (Navigator 1/2, go_router, etc.) and architecture doc take precedence.

- Cache the navigator/router in a `State` per `state.md` (`_navigator = Navigator.of(context)` in `didChangeDependencies`); this also makes it safe to use after an `await`, without touching `context`.
- Navigation triggered by async work (after a save, a login) belongs in a controller/service layer that exposes the outcome, with the widget reacting to it; avoid `await` then `context`-based navigation in the widget (see `review-flutter-async-and-disposal`, section A).
- Pass results back with `pop(result)` and typed `push<T>` / `await`ed routes rather than shared mutable state or callbacks stashed on the route.
- Route names/paths are constants defined once, not string literals at call sites.
- A screen that needs to react to being covered or revealed uses `RouteAware` (callback order in `state.md`).
