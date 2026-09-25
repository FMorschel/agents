---
name: edit-dart-class
description: "Use whenever you add, move, or edit members of a Dart class (constructors, fields, methods, getters/setters, operators, toString) or change constructor/method parameters. Defines the required member ordering inside the class body and the parameter-ordering rule (broad-to-specific, required first, named preferred)."
---

## Editing a Dart class

This skill covers *where* members go (ordering, blank lines, parameter order). For *what form* a class and its data should take — primary constructors, field vs. `late` field vs. getter, mutability, equality, class kind, naming — use the `design-dart-class` skill alongside it.

Every edit to a class body must leave the class in the layout below — not just the lines you touched. When you add a member, insert it at its correct position. When you edit a class that is already out of order, reorder the members you are touching and mention the rest rather than silently reshuffling the whole file.

### Class body order (top to bottom)

1. **Constructors**
2. **Fields**
3. **Static methods**
4. **Instance methods**
5. **Getters and setters** (together)
6. **Operators**
7. **`toString`** — if it exists, it is *always* the last member of the class body, no exceptions

Three rules apply at every level:

- **Overrides come before the class's own members.** Anything annotated `@override` (fields, methods, getters/setters, operators) goes first *within its category*, ahead of the non-override members of that category, because it changes inherited behavior and the reader should see that first. The only exception is `toString`, which stays last in the class body. Overrides are always instance members (`static` members can't be overridden), so they never compete with static ones: static members of a category still come first. Inside the override block, the remaining ordering keys still apply (modifier, privacy, nullability, priority/alphabetical); the class's own members follow the full set of keys. Constructors are unaffected.

- **Private members go at the bottom of their own category.** "Private" means the name starts with `_`. A category is one of the groups listed in this document (e.g. "static final fields", "instance methods"). Private members never float above public ones of the same category, but they also don't sink below the next category.
- **Tiebreaker inside a group:** order by *priority* (the member the reader most needs to see first, or the one others build on). If members are not meaningfully related, order them alphabetically. Never leave it to arbitrary/original order when adding a member — place it by this rule.

### 1. Constructors

In this order, each group sorted alphabetically by name, and each group's private constructors (`Foo._()`) after its public ones:

1. The unnamed constructor (`Foo(...)`) — always the very first thing in the body, whatever its modifiers
2. `const` named generative constructors
3. Non-const named generative constructors
4. `const factory` constructors
5. `factory` constructors

If the class uses a **primary constructor** (Dart 3.13+; see the `design-dart-class` skill for when to prefer one), the header takes the unnamed-constructor slot and declares the fields, so the body starts with the remaining constructors and its field section omits the header-declared fields.

### 2. Fields

Sort by these keys, in this order of precedence:

1. **Scope:** `static` before instance
2. **Override:** `@override` fields before the class's own fields
3. **Modifier:** `late final` > `final` > `late` (then any remaining plain mutable fields last)
   - `const` (static const) counts as the top of the `final` tier: it goes ahead of `late final`.
4. **Privacy:** public, then private (private at the bottom of that modifier group, *before* the next modifier group starts)
5. **Nullability:** non-nullable (initialized) before nullable
6. **Tiebreaker:** priority, else alphabetical

Any odd mix (e.g. `static late final int? _x`) is handled by applying the keys in order, never by inventing an exception.

Example instance-field block (note the blank lines, see "Blank lines between sections"):

```dart
final int field;

final int? nullableField;

final int _other;

late int something;

late int _else;
```

(`nullableField` is its own section, `_other` sits at the bottom of the `final` group, `something` starts the `late` group, and `_else` sits at the bottom of the `late` group.)

When adding a derived value, whether it should be a field, a `late` field or a getter is decided by the `design-dart-class` skill; this skill then places it by its final form (getter → accessors section, field → fields section).

### 3. Methods

- Static methods first, then instance methods.
- Within each, public first, then private (alphabetical/priority tiebreak inside each).
- Overrides are instance-only, so they lead the *instance* methods: static methods, then `@override` instance methods, then the class's own instance methods. `toString` is the exception: it goes last in the class (see below).

### 4. Getters and setters

- Together in one section after the instance methods.
- Order: static accessors, then `@override` (instance) accessors, then the class's own instance accessors; public before private within each.
- A getter and its matching setter stay adjacent (getter first).

### 5. Operators

After getters/setters. `@override` operators (e.g. `operator ==`) come before the class's own operators; `hashCode` is an overridden getter, so it lives at the top of the instance accessors in the getters/setters section, not here.

### 6. `toString`

Last member in the class body. If a new member would land after it, it goes before it instead.

### Parameter ordering (constructors and methods)

Order parameters from **most important/broadest** to **most specific**: *forest → tree → branch* (e.g. `forest`, `tree`, `branch`). Ask of each parameter "what contains or scopes what?" and put the container before the contained; when the parameters aren't hierarchical, order by how central each is to what the member does.

- **Prefer named parameters.** Use positional parameters only when it is easy to justify, and **never more than two**. Everything beyond that is named.
- **Required always comes first**, before optional ones, because required parameters are the more important ones. This holds both among positional parameters and among named parameters (`required` named parameters before optional named ones).
- Within each of those groups, apply the forest → tree → branch order.

### Safety when reordering parameters

- Reordering **named** parameters is non-breaking for callers.
- Reordering positional parameters, or converting positional to named, **breaks call sites**. Update every caller in the repo (use the analyzer to find them) and call out the change if the member is part of a package's public API.
- Do not change parameter names or types as a side effect of reordering.

### How to reorder without breaking things

- Move each member together with its doc comment, annotations (`@override`, `@visibleForTesting`, …) and any comments directly attached to it.
- Reordering must be a pure move: no behavior or formatting changes mixed in.
- Moving a field can only change behavior through field *initializer expressions* (`int a = compute();`), which run in declaration order before the constructor's initializer list. Initializing formals (`this.x`), initializer-list entries (`: x = y + 1`) and `late` initializers (lazy, run on first access) do not depend on where the field is declared, so those are safe to move. Before moving a field that has an initializer expression, check that neither it nor its neighbors have side effects or depend on evaluation order (non-`late` initializers can't reference `this`, but they can call functions that mutate shared state); if so, leave the order alone and flag it.

### Blank lines between sections

Every "section" is separated from its neighbors by exactly one blank line — above it if anything precedes it, below it if anything follows it. Members within the same section sit together with no blank line between them, **unless a member has a leading comment** — a doc comment (`///`) or a `// ignore: ...` / `// ignore_for_file`-style comment directly above it. Such a member always gets one blank line above it (above the comment, not between the comment and the member), even inside a section, and the next member follows the same rule. E.g. within one section of `final` fields:

```dart
final int a;
final int b;

/// The c value.
final int c;
final int d;

// ignore: some_lint
final int e;
```

A section is one group produced by the ordering keys, so a change in any key starts a new section:

- **Fields:** scope, override vs. own, modifier (`static const`, `late final`, `final`, `late`, …), **nullable vs. non-nullable** (nullable fields are their own section) and **private vs. public** (private fields are their own section). E.g. public non-nullable `final` fields, public nullable `final` fields, private non-nullable `final` fields and private nullable `final` fields are four separate sections. `static const` fields, for example, get a blank line before them if anything precedes them, and one after them if anything follows.
- **Constructors:** always separated from each other by a blank line — every constructor, even within the same group (unnamed, `const` named, non-const named, `const factory`, `factory`, private).
- **Methods, operators, `toString`:** always separated from each other by a blank line — every member, even within the same group. Section boundaries (static / override / own / private) don't add extra blank lines beyond that single one.
- **Getters and setters:** each getter/setter is separated by a blank line from the next, *except* a getter and setter of the same name, which stay together with no blank line between them (getter first). Getters/setters with different names are always separated, even if adjacent in the ordering.

Never use two or more consecutive blank lines, and no blank line right after the class's opening `{` or before its closing `}`.

### No section-divider comments

The ordering itself is the structure — never add banner or divider comments to label groups of members, such as:

```dart
// -- display toggles ------------------------------------------------------
// -- getters ------------------------------------------------------
// ===== Constructors =====
// region Fields / // endregion
```

If the class already contains comments like these, remove them when you reorder (only pure dividers — keep any comment that documents a specific member or explains non-obvious behavior). Don't replace them with a different divider style, and don't add them when creating new members.

### After editing

Follow the post-edit Dart workflow from the global instructions: `dart fix --apply`, `dart analyze` (fix every diagnostic), then `dart format` on each edited file.
