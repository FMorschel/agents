## `State` conventions

Two rules specific to `State<StatefulWidget>` subclasses. Everything else about shaping and ordering the class still comes from `design-dart-class` and `edit-dart-class`; this file only overrides their generic tiebreak for the handful of well-known lifecycle overrides listed below, and adds a pattern for `.of(context)` lookups that those skills don't cover.

### 1. Cache `.of(context)` lookups in `didChangeDependencies`

`Navigator.of(context)`, `Theme.of(context)`, `MediaQuery.of(context)`, `ScaffoldMessenger.of(context)`, `Provider.of<T>(context, listen: false)`, and similar static `.of(context)` accessors walk the widget tree (via `context.dependOnInheritedWidgetOfExactType` or an ancestor search) every time they're called. Calling one directly inside `build` re-does that walk on every rebuild for a value that usually hasn't changed; calling one inside `initState` is unsafe because the widget isn't fully attached to the tree yet — the framework's own guidance is to do the lookup from `didChangeDependencies` instead.

Prefer storing the result in a field, assigned in `didChangeDependencies`, over calling `.of(context)` inline in `build` or elsewhere:

```dart
class _MyWidgetState extends State<MyWidget> {
  late NavigatorState _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _navigator = Navigator.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _navigator.pop(),
      child: const Text('Back'),
    );
  }
}
```

- Declare the field `late` (per `design-dart-class`'s field-vs-getter guidance) rather than nullable-with-null-checks: `didChangeDependencies` always runs once before the first `build`, and again whenever an ancestor `InheritedWidget` this lookup depends on changes, so the field is never read before it's set.
- This applies to lookups whose *result* is what you need (a controller/service/theme object you call methods on or read fields from), not to values you want the widget to rebuild against via `context.watch<T>()` — those still belong in `build` so Flutter can (re)register the dependency link correctly.
- Field placement follows the normal `edit-dart-class` field rules (instance, `late`, public/private, then priority/alphabetical among these cached lookups).

### 2. `State` override method order

`edit-dart-class` orders `@override` instance methods ahead of the class's own, tiebroken alphabetically/by priority. For a `State<StatefulWidget>`, replace that tiebreak — for exactly this set of lifecycle overrides — with this fixed relative order:

1. `initState`
2. `reassemble`
3. RouteAware callbacks, **only if the class mixes in `RouteAware`**, in this order: `didPopNext`, `didPush`, `didPop`, `didPushNext`
4. `didChangeDependencies`
5. `didUpdateWidget`
6. `activate`
7. `deactivate`
8. `dispose`
9. `setState`, only if overridden
10. `build`

These members keep this relative order regardless of alphabetical order — note `build` sorts last here even though `edit-dart-class`'s default `@override` block would normally place it by priority/alphabetically among the other overrides. Any other `@override` instance method the class has is not part of this fixed list and keeps the normal `edit-dart-class` priority/alphabetical placement, always below these (after `build`), still ahead of the class's own non-override methods.

`toString`, if present, still stays last in the whole class body per `edit-dart-class` — after `build`, not before it.

### 3. Where the `super` call goes

Whenever a `State` override calls its `super` method, the position is fixed:

- **Every override except `dispose`: `super.foo(...)` is the first statement** (`super.initState()`, `super.didChangeDependencies()`, `super.didUpdateWidget(oldWidget)`, and the RouteAware callbacks when they call super). Your own code runs after the framework has set up.
- **`dispose`: `super.dispose()` is the last statement**, after your controllers, subscriptions and listeners are disposed/cancelled/removed, since the framework tears down after you.
- `build` has no super call.

```dart
@override
void initState() {
  super.initState();
  _controller = TextEditingController();
}

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```
