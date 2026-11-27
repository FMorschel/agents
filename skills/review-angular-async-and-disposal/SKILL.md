---
name: review-angular-async-and-disposal
description: "Use when writing or reviewing Angular/TypeScript code for async correctness (RxJS and promises), change detection cost and resource lifecycle (subscriptions, listeners, timers, third-party objects, dynamic components). Four-part checklist: async correctness, change detection cost, leaks and retention, memory savings. Angular counterpart of `review-flutter-async-and-disposal`; also works as a pre-flight for writing code."
---

## Async, change detection and lifecycle checks (Angular)

A checklist for reviewing Angular/TypeScript code, and a pre-flight for writing it. It is the counterpart of `review-flutter-async-and-disposal`: the same four parts, with Angular and RxJS mechanisms. Architecture purity (`layered-architecture`) and style (`resolve-project-conventions`) are separate concerns, not covered here.

Code smells compile and probably work today; they misbehave in subtle ways or degrade later. Report a smell as a smell. Epistemic rule (from `dart-edit-protocol`, valid for any language): never call something *incorrect* unless the project's compiler or linter agrees (`ng build`/`tsc`, `ng lint`/`eslint`); if you are not sure it is intentional, phrase it as a question. Commands in `language-tooling/languages/typescript-node.md`.

Before applying, find out the project's style, because it changes what is a finding: **zone.js or zoneless**, **NgModules or standalone**, **signals or RxJS**, **`OnPush` or `Default`** (`resolve-project-conventions`).

### A. Async correctness

- **Nested `subscribe`:** a `subscribe` inside another `subscribe` loses cancellation and ordering. Use a flattening operator chosen by its semantics: `switchMap` (only the last matters, e.g. search as you type; cancels the previous one), `concatMap` (in order, one at a time), `exhaustMap` (ignores new ones while one runs, e.g. a save button), `mergeMap` (concurrent and unbounded: set `concurrent` when the list is large).
- **Unhandled error in the stream:** a `subscribe` with no error handler, or an error that reaches the outer stream, **kills the stream** for good (a `valueChanges` or typed search stops responding after the first failure). Put the `catchError` *inside* the inner observable (`switchMap(q => http.get(q).pipe(catchError(...)))`) so the outer one survives.
- **Swallowed errors:** `catchError(() => EMPTY)` or `of([])` with no log or user feedback; an empty `try { await ... } catch {}`; catching `any` where a specific type is expected. Prefer at least a minimal log over an empty catch.
- **Floating promises:** a call that returns a `Promise` without `await`, `.catch` or an explicit `void` (`@typescript-eslint/no-floating-promises` catches it, when enabled). An `async ngOnInit()` whose error nobody handles is the most common form.
- **Cold observables called more than once:** each `subscribe` (or each `| async` on the same observable) fires another HTTP request. Share with `shareReplay({ bufferSize: 1, refCount: true })`, convert with `toSignal`, or subscribe once and distribute with `@if (data$ | async; as data)`.
- **`firstValueFrom`/`lastValueFrom`:** on an observable that never completes the promise never resolves; on one that completes without a value it throws `EmptyError`. `toPromise()` is deprecated.
- **`await` in a loop** that could run concurrently (`Promise.all`, `forkJoin`) when order is not needed (and the reverse: `Promise.all`/`forkJoin` over work that must be sequential).
- **Race conditions:** two overlapping calls updating the same state without `switchMap`/a last-wins guard; state read before an `await` and written after it; an old response arriving after the new one.
- **Outside or inside the wrong zone:** async code run in `NgZone.runOutsideAngular` that later changes screen state without going back with `ngZone.run(...)` (the screen does not update); in a zoneless or `OnPush` project, changing a plain field after an `await` does not redraw: the state must be a signal or call `markForCheck`.
- **Signals `effect()`** that writes to another signal or does heavy work: compute with `computed`, leave `effect` for side effects (log, DOM, storage).

### B. Change detection cost

- **Function call or getter with work in the template** (`{{ filter(list) }}`, `*ngIf="compute()"`): runs on every cycle. Use `computed`, a pure pipe, or compute once upstream.
- **Wider scope than what changes:** a large component in `ChangeDetectionStrategy.Default` redrawing a huge subtree when a leaf changes; extract the part that changes into an `OnPush` component with immutable inputs or signals.
- **`@for`/`*ngFor` without `track`/`trackBy`:** Angular recreates the DOM of the whole list when the reference changes (`track item.id`, not `$index`, when items can be reordered).
- **New literals on every cycle:** `[options]="{ a: 1 }"`, `[list]="items.filter(...)"` or an arrow function in the template passed to an `OnPush` child: the reference changes on every cycle and defeats `OnPush`.
- **Repeated `| async`** on the same observable (one subscription per use); subscribe once.
- **Long lists** rendered in full instead of `cdk-virtual-scroll-viewport` or pagination.
- **High-frequency events** (`scroll`, `mousemove`, `resize`) that trigger change detection on every event: `runOutsideAngular` and come back only when the state changes, or use `fromEvent` with `auditTime`/`throttleTime`.
- **Expensive work in hooks that always run** (`ngDoCheck`, `ngAfterViewChecked`) or in impure pipe constructors.
- **Missing `@defer` and lazy routes** for a heavy part that only appears later (informational only, see D).

### C. Leaks and retention

For each item, you must **point at the missing teardown**; do not speculate about leaks you cannot trace in the code you are reading.

- **`subscribe()` never torn down in a component, directive or short-lived service:** the right teardown is `takeUntilDestroyed()` (from `@angular/core/rxjs-interop`; outside an injection context, pass a `DestroyRef`), the `async` pipe, `toSignal`, or `Subscription.unsubscribe()` in `ngOnDestroy`. Excused: `HttpClient` (completes by itself) and observables that complete by construction. `take(1)`/`first()` only tear down if the observable actually emits; on one that may never emit, they still leak.
- **`shareReplay(1)` without `refCount: true`** keeps the source subscribed forever.
- **`Subject`/`BehaviorSubject` of a `providedIn: 'root'` service** subscribed by a component without teardown: the service lives forever and keeps the component alive through the closure.
- **`router.events`, `valueChanges` and `statusChanges`** subscribed without teardown (Angular does not tear them down). `ActivatedRoute` observables (`params`, `queryParams`) are torn down by the router itself when the component is destroyed, so they are not a finding.
- **DOM and `window`/`document` listeners:** `addEventListener` without a matching `removeEventListener` (same function instance); the return of `Renderer2.listen` is a removal function and must be called in `ngOnDestroy`. `@HostListener` is managed by Angular.
- **Timers:** `setInterval`/`setTimeout`/`interval()`/`timer()` without `clearInterval`/`clearTimeout`/teardown.
- **Third-party and browser objects:** `ResizeObserver`, `IntersectionObserver`, `MutationObserver`, `WebSocket`, `EventSource`, chart and map instances, `Worker`, which need `disconnect()`, `close()`, `destroy()` or `terminate()` in `ngOnDestroy`.
- **Dynamic components and views:** `ViewContainerRef.createComponent` without `destroy()` on the `ComponentRef`; dialogs and overlays (`MatDialogRef`, `Overlay`) whose `afterClosed()` or `backdropClick()` subscriptions are not torn down when the parent goes away.
- **Long-lived collections that grow:** static maps/arrays, service caches without removal or eviction, callback lists.
- **Long-lived closures over a short-lived component:** callbacks registered on a singleton service or on `window` capturing the component's `this`.
- `ngOnDestroy` exists when the class has something to tear down; `DestroyRef.onDestroy` is the alternative for code that is not a component class.

### D. Memory savings (only when genuinely free)

Report only a saving that costs **no readability and no speed**:

- Holding a large object (a full HTTP response, a `ComponentRef`) for the class's lifetime when only a small derived value is used from it.
- Copying a collection (`[...list]`, `structuredClone`, `JSON.parse(JSON.stringify(...))`) when a direct read does the same job.
- Eagerly loading something only needed later, when `@defer` or a lazy route (`loadComponent`/`loadChildren`) is a direct swap.
- An unbounded cache whose access pattern clearly justifies an eviction policy.

Do not suggest micro-optimizations that trade clarity for a few bytes. Anything that needs profiling (Angular DevTools, the browser's Performance/Memory tab) to be confirmed goes in a separate **"Worth measuring"** aside, never as a finding.

### Findings format

```
## Findings

### path/to/file.ts
- L##: [async | change-detection | leak | saving] — <description>
  Why it matters: <one sentence>
  Suggested fix: <one sentence>

### Worth measuring (not a finding)
- path:L## — <possible saving that needs measurement>
```

Omit clean files and empty sections. A real leak (section C) must be fixed before the work is considered done; async and change detection smells are informational, unless the linter flags them as errors.
