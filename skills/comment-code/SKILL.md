---
name: comment-code
description: "Use whenever you write or edit comments or doc comments in code (Dart especially): inline comments on executing code and documentation on declarations (functions, methods, constructors, fields, getters, setters). Inline comments explain why, never what; declaration docs follow a fixed shape and prefer comment references."
---

## Commenting code

Two kinds of comments, two different jobs. Decide which one you are writing first.

### Inline comments (on executing code)

Explain **why** the code is there: the constraint, the surprising behavior, the bug it works around, the reason this approach was chosen over the obvious one. The code already says *what* it does; a comment that restates it is noise and gets stale.

Never write:

```dart
// Prints foo
print(foo);
```

Write a comment only when a reader would otherwise ask "why?":

```dart
// The server rejects empty batches, so skip the call instead of sending one.
if (items.isEmpty) return;
```

If you can't state a *why*, don't comment. Prefer renaming or extracting code over explaining unclear code with a comment.

### Declaration comments (doc comments)

Use `///` doc comments.

**Functions, methods, constructors**

- The first paragraph is a **single phrase/sentence** saying what it does.
- Following paragraphs add context: when to use it, edge cases, side effects, throws, examples.
- Explain complex parameters (and only those) by referencing them with `[param]`.
- Add a short example when usage isn't obvious.

```dart
/// Splits [text] into chunks that fit within [maxLength].
///
/// Breaks happen at whitespace when possible; a word longer than
/// [maxLength] is split mid-word rather than dropped. If [keepDelimiters]
/// is `true`, the whitespace stays attached to the end of each chunk.
List<String> chunk(String text, {required int maxLength, bool keepDelimiters = false})
```

**Getters, fields, setters**

- Explain what the value **means for the class**, not its type or how it is stored.
- For a setter, mention any separate side effects (notifies listeners, invalidates a cache, triggers a rebuild) when they're worth knowing. Skip this if there are none.

```dart
/// Whether the user has confirmed the order and it can no longer be edited.
bool get isLocked => _lockedAt != null;
```

### Always prefer comment references

Use `[name]` references instead of plain-text or backticked names whenever the target is a symbol that resolves in scope: parameters, other members, classes, enum values, top-level functions. Use `[Class.member]` or `[Class.new]` for constructors when needed. References make the docs navigable and let the analyzer flag them when the symbol is renamed or removed. Backticks are for code that isn't a resolvable symbol (literals like `null`, `true`, snippets).

### Multi-line TODOs

When a TODO spans more than one line, every line after the first must start with **two spaces** between `//` and the text. This is how the analyzer knows the continuation belongs to the TODO.

```dart
// TODO(FMorschel): bla bla
//  bla bla.
```

Without the extra space, the second line is treated as an ordinary comment and is dropped from the TODO.

### Don't

- Don't restate the signature, the name, or the types in prose.
- Don't add section-divider or banner comments.
- Don't leave commented-out code.
- Don't write TODOs without something actionable, or continuation lines without the two-space indent.

### After editing

For Dart, follow the post-edit workflow from the global instructions: `dart fix --apply`, `dart analyze` (unresolved comment references show up here, fix them), then `dart format` on each edited file.
