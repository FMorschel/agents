---
name: review-flutter-async-and-disposal
description: "Use when writing or reviewing Dart/Flutter code for async correctness, widget rebuild cost, and resource lifecycle (disposal, cancellation, listener removal, retention). Checklist for `code smell detector` and `memory safety agent`, and for `implementer` to avoid these mistakes up front. Defines which concern belongs to which agent."
---

## Async, rebuild and lifecycle checks

Two reviewers use this checklist and must not overlap. **`code smell detector`** owns *async correctness* and *rebuild cost*. **`memory safety agent`** owns *leaks, retention and memory savings*. Architecture/model-purity belongs to `architecture guardian`, style to `convention agent`. An `implementer` uses the whole list as a pre-flight.

Smells compile and probably work today; they misbehave subtly or degrade later. Report a smell as a smell. Per the epistemic rule in `dart-edit-protocol`, never call something *incorrect* unless `dart analyze` agrees; if unsure whether it's intentional, phrase it as a question.

### A. Async correctness (`code smell detector`)

- **`BuildContext` after `await`** without a mounted check: in a `State`, `if (!mounted) return;` (or `if (!context.mounted)` for a context passed around) before any later use of `context`, including `Navigator`, `ScaffoldMessenger`, `Theme.of`, and `context.read`. Capturing the navigator/messenger *before* the `await` is an acceptable alternative. Treat needing this check at all as a prompt to question the design: a widget awaiting something and then reaching back into `context` is often a sign the async work belongs in a controller/provider layer instead of the widget, not just a missing guard. Flag the mounted check as the immediate fix, but note the layering smell too. For `implementer` specifically: prefer separating the concern with an abstraction over the UI (controller/provider/service owning the async call and its result) rather than awaiting directly in the widget and guarding with `mounted`/`context.mounted` afterward.
- **Fire-and-forget futures** with no error handling and no intentional detachment: an un-awaited call whose failure would be an unhandled async error. Fine only when explicitly detached (`unawaited(...)` from `dart:async`, with the error path handled inside) and the reason is clear, or when all Dart async errors are already handled elsewhere (e.g. a global `runZonedGuarded`/`PlatformDispatcher.instance.onError` handler) so the failure won't go unnoticed.
- **Futures created in `build()`**: `FutureBuilder(future: fetch(), ...)` re-creates the future on every rebuild. The future belongs in `initState`, a provider/controller, or a memoized field (e.g. a `Completer`-backed field set once and reused).
- **`async` without `await`** / returning a `Future` from a function that doesn't need to be async; `await` inside a loop that could run concurrently (`Future.wait`) when order isn't required (and the reverse: `Future.wait` on work that must be sequential).
- **Swallowed errors:** `catch (_) {}`, empty `onError`, `.catchError` that returns a value and hides the failure; catching `Object`/`Exception` broadly where a specific type is expected. When an error is genuinely safe to ignore, prefer at least a minimal log over a silent empty catch, so the failure is still discoverable.
- **Completers/streams left dangling:** a `Completer` that can never complete on some path; a `StreamController` whose `onCancel`/`close` is unhandled.
- **Races:** two overlapping async calls updating the same state with no cancellation/latest-wins guard (search-as-you-type, refresh + pagination); state read before an `await` and written after it.
- **`setState` after dispose** paths (async callbacks that may complete after the widget is gone). Guard with a `mounted` check before calling `setState`.

### B. Rebuild cost (`code smell detector`)

- **Expensive work in `build()`**: sorting, filtering, parsing, regex construction, building large lists, or creating controllers/services on each rebuild. Memoize in state, a provider, or compute once upstream.
- **Rebuild scope wider than what changes:** a `setState` (or a watched provider/`ChangeNotifier`) at a high ancestor that rebuilds a large subtree when one leaf changes; extract the changing part into its own widget or use a narrower selector.
- **Missing `const`** on constant subtrees inside frequently rebuilt widgets (where the analyzer's `prefer_const_*` lints don't already catch it).
- **Unbounded/unstable lists:** `ListView(children: [...])` over a long list instead of `ListView.builder`; missing `Key`s on reorderable/dynamic children so state jumps between items.
- **Passing new closures/objects each build** to a child that compares by identity (defeats `const`/`shouldRebuild`-style short-circuits).

### C. Leaks and retention (`memory safety agent`)

For each item you must **point to the missing dispose/cancel/removal**; don't speculate about leaks you can't trace in the code you're reading.

- **Disposable fields never disposed** in `dispose()`: `AnimationController` (also `Ticker`), `TextEditingController`, `FocusNode`, `ScrollController`, `PageController`, `TabController`, `StreamController`, `ValueNotifier`/`ChangeNotifier` the class owns, custom `Disposable`s. Ownership matters: dispose what you create, not what was passed in. `super.dispose()` is called (last, in a `State`).
- **`StreamSubscription`s** from `.listen()` never cancelled (and `Timer`s never cancelled).
- **Listeners** added with `addListener`, `addObserver` (`WidgetsBinding`), or `addPostFrameCallback`-registered closures with no matching removal; the removal must use the same function instance.
- **Growing long-lived collections:** static maps/lists, singletons, caches that only ever add entries with no eviction or removal path.
- **Long-lived closures over short-lived context:** callbacks, listeners or singletons capturing a `BuildContext`/`State`/large object longer than needed.
- **Streams/notifiers created per build** and never closed.

### D. Memory savings (`memory safety agent`, only when genuinely free)

Report only a saving that costs **no readability and no speed**:

- Retaining a large object for the class's lifetime when only a small derived value is ever used from it.
- Copying a collection where a view/iterable does the same job (`toList()` you don't need).
- Eager loading of something conditionally needed where lazy initialization (`late`/lazy getter) is a drop-in change.
- An unbounded cache whose access pattern clearly warrants an eviction policy.

Do not suggest micro-optimizations that trade clarity for a few bytes (packing unrelated fields, replacing a named class with a positional record). Anything that needs profiling to confirm goes in a separate **"Worth profiling"** aside, never a finding.

### Output shapes

`code smell detector`:

```
## Smells found

### path/to/file.dart
- L##: [category] — <description>
  Why it matters: <one sentence>
  Suggested fix: <one sentence>
```

`memory safety agent`:

```
## Memory safety review

### Leaks
- path:L## — <what's undisposed/uncancelled/retained> — <why it leaks>

### Savings (no readability/performance cost)
- path:L## — <current pattern> → <lighter pattern>, no tradeoff because <why>

### Worth profiling (not a finding)
- path:L## — <possible saving that needs measurement>
```

Omit clean files and empty sections. A leak finding is **blocking** in the pipeline (a real leak isn't optional); async and rebuild smells are informational unless the analyzer flags them as errors.
