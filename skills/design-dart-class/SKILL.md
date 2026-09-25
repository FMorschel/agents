---
name: design-dart-class
description: "Use when creating a Dart class or deciding how to shape it: primary constructors (Dart 3.13+), field vs. `late` field vs. getter, setter vs. method, mutability, equality, class kind/openness, constructors, visibility, helper placement and naming. Companion to `edit-dart-class`, which governs member ordering and layout."
---

## Designing a Dart class

This skill covers *what form* a class and its data should take. Once you've decided, follow the `edit-dart-class` skill for *where* each member goes in the class body (ordering, blank lines, parameter order). Use both together when writing or restructuring a class.

### Primary constructors (Dart 3.13+)

If the package's `pubspec.yaml` `environment: sdk:` constraint is 3.13 or higher, prefer a **primary constructor** for data-like classes: classes whose fields are all set straight from the unnamed constructor's parameters (value objects, models, DTOs, immutable records-in-class-form). Declare the fields in the class header instead of writing a body constructor plus separate field declarations:

```dart
class const Rgba({
  required final int r,
  required final int g,
  required final int b,
  final int a = 255,
}) {
  const Rgba.transparent() : this(r: 0, g: 0, b: 0, a: 0);

  factory Rgba.fromArgb32(int value) => Rgba(...);
}
```

Why: each field would otherwise be written three times (declaration, `this.x` parameter, and often its type again) and can drift out of sync; the header states the class's data shape and constness once. Fields declared this way live in the header, so they're not repeated in the body's field section; the rest of the body follows the ordering in `edit-dart-class` (the unnamed constructor slot is taken by the header, so the body starts with the remaining constructors).

Don't convert (leave the class as is) when:

- the class isn't data-like: the constructor computes, validates beyond simple asserts, or derives fields, or the fields don't map one-to-one onto parameters;
- a field needs something the header can't express: `late` fields, or fields with non-trivial initializers that aren't parameters. Doc comments and annotations are **not** a reason to avoid it: written above a declaring parameter in the header, they apply to both the parameter and the field it declares, so keep them there;
- the SDK constraint is below 3.13 (never use the syntax there), or you're only making a small edit to a class that doesn't use it — don't migrate a class as a drive-by; convert when you're already restructuring its constructor or fields, or when creating a new data class.

### Setter or method?

Use a **setter** for a simple change to one member: assigning it, possibly normalizing or validating the value, and notifying listeners (`notifyListeners()`, a `ValueNotifier`-style update) — telling observers the value changed is part of a plain assignment, not a side effect. Use a **method** as soon as the change has other side effects (I/O, starting or stopping timers, updating other members, triggering work) or reads as an action rather than a property. A method is preferred even when it takes a single parameter, and even when it takes none.

```dart
// Action with effects: a method, named as a verb.
void activate() {
  _active = true;
  _startHeartbeat();
  notifyListeners();
}

// Simple state change: a setter is enough, even with a notification.
set opacity(double value) {
  final clamped = value.clamp(0.0, 1.0);
  if (clamped == _opacity) return;
  _opacity = clamped;
  notifyListeners();
}
```

So `active = true` as a setter is only right if it just flips the flag (and notifies); if turning the class on does anything more, like the heartbeat above, that's `activate()`. A good setter use case: a settings-like or value-object property (`opacity`, `name` with `.trim()`, `zoom` clamped to a range) where the assignment is the whole operation and reading it back returns what was set (or its normalized form). If a setter would do more than that, or surprise a caller who just wrote `x.foo = y`, make it a method. Always pair a setter with a getter of the same name.

### Field, `late` field, or getter?

When adding a value that is derived from other members, pick the form by its cost model:

- **Field (even `final`):** stored for the whole life of the instance. Costs memory always, computes once (at construction). Prefer it for values that are expensive to compute, read often, or must keep a stable identity (same instance every time).
- **`late` field with an initializer (`late final x = ...;`):** computed lazily on first access and stored only *after* it's initialized, so an instance whose `late` field is never accessed pays no memory and no compute. Prefer it for expensive values that are often not needed. (A `late` field without an initializer is stored once it's assigned, not on access.)
- **Getter:** stores nothing, but is re-evaluated on every call. Prefer it for cheap derivations from other fields (e.g. `int get asArgb32 => ...`), for values that must always reflect current mutable state, and when a fresh object per call is acceptable.

Pick the lightest form that satisfies the value's cost and semantics; don't turn existing members from one form into another as a drive-by — only when you're already changing them or adding a new one. Where a member lands in the class body follows from its form (getter → accessors section, field → fields section, per `edit-dart-class`), so changing the form also changes its position.

### Mutability

Data classes are `const` and immutable: `final` fields, a `const` constructor, and a `copyWith` (or similar) when callers need a changed copy. Controllers, services and other stateful classes may be mutable, but only when they actually hold state; a stateless service should still be `const`.

### Equality and `hashCode`

Override `==` and `hashCode` on a data class if instances will be compared against each other, including as members of a `Set`, `List` lookups (`contains`, `indexOf`), or keys/values of a `Map`. If nothing ever compares two instances, don't add them. Always override both together, and base them on the same fields.

### Class kind and openness

- **App:** classes are open by default (no `final`/`sealed` modifiers unless there's a specific reason).
- **Package:** make everything `final` unless it is a public interface that users are meant to extend or implement. Where such an interface can be one, prefer a `mixin` (or `mixin class`) over an open class.
- **Reuse:** always prefer extending or mixing in over `implements`. Use `implements` only when extending or mixing in is not possible.

### Constructors

- Prefer `const` constructors.
- Use a `factory` only when a generative constructor can't do the job (returning a cached/subtype instance, parsing that can't fit an initializer list, etc.).
- A named constructor is justified only when an unnamed one already exists, or when the name explains something clearly that the unnamed form couldn't (e.g. `Rgba.transparent()`, `Rgba.fromArgb32(...)`).

### Visibility and encapsulation

Keep fields public and plain (no getter/setter wrapper) unless there's logic to run on access. Make a member private when a caller touching it could make some logic misbehave (broken invariants, out-of-sync derived state); when the value must still be readable, expose it through a getter over a private field.

Example: a controller that keeps a list in its state. If that list were public, the UI could add or remove items directly, bypassing the controller's logic (no notification, no validation, derived state out of sync). Keep the list private and expose a getter that returns an unmodifiable view:

```dart
final List<Item> _items = [];

List<Item> get items => List.unmodifiable(_items);

void add(Item item) {
  _items.add(item);
  notifyListeners();
}
```

`List.unmodifiable` copies on every call; when the list is large or read often, cache the view, or return `UnmodifiableListView(_items)` to avoid the copy while still blocking writes (it reflects later changes to the source list). Apply the same idea to other mutable collections (`Set`, `Map`) and mutable objects.

### Namespacing helpers: extension, static class, top-level function

- Behavior that belongs to one specific type: an **extension** on that type — it's intrinsically related to it.
- Otherwise, helpers with no natural owner: a **static-only class** (it gives a namespace) rather than loose top-level functions.

Static-only classes are allowed. If the project already uses them, follow suit freely. If it doesn't use any yet, don't introduce the pattern on your own initiative — but this section counts as the "stated elsewhere" that permits it, so use one when helpers genuinely need a namespace. Only an explicit rule in the project's own docs or lint config that forbids them overrides this; in that case follow the project and mention the mismatch.

### Class scope

If a class name is broad and the class handles separate features, check whether those features need to coexist in one class. If not, suggest splitting it into separate classes instead of adding more to it.

### Naming

- Classes are nouns; methods are verbs.
- Conversion methods use `toXYZ` (`toJson()`, `toArgb32()`).
- Conversion-like getters (a view of the same value) use `asXYZ` (`asArgb32`).

### Related skills and agents

- `edit-dart-class`: where members go once you've decided their form.
- `comment-code`: how to write doc comments and inline comments on the class and its members.
- `architecture guardian` (agent): checks new classes against the project's layered architecture.
