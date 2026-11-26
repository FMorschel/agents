---
name: comment-code
description: "Use whenever you write, add, change or review comments or doc comments in code, in any language (Dart, TypeScript/Angular, Java, Ruby): inline comments on executing code, documentation on declarations (functions, methods, constructors, fields, getters, setters) and TODOs. Comments are written in Brazilian Portuguese (identifiers stay in English). Inline comments explain why, never what; declaration docs follow a fixed shape and prefer comment references."
---

## Commenting code

Two kinds of comments, two different jobs. Decide which one you are writing first.

Comments are written in **Brazilian Portuguese**. Identifiers stay in English. (The examples below are in English for readability; write the real comments in Brazilian Portuguese.)

The syntax changes per language (`///` in Dart, `/** */` in TypeScript and Java, `#` with YARD in Ruby, and the references `[name]`, `{@link name}`, `{Class#method}`), but the rules below do not. The syntax of each is in `language-tooling`; the examples here are in Dart and TypeScript, and the project wins if it already has a style (`resolve-project-conventions`).

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

```typescript
// The server rejects empty batches, so skip the call instead of sending one.
if (items.length === 0) return;
```

If you can't state a *why*, don't comment. Prefer renaming or extracting code over explaining unclear code with a comment.

### Declaration comments (doc comments)

Use the language's doc-comment form (`///` in Dart; `/** ... */` in TypeScript/TSDoc and Java/Javadoc; `#` above the declaration, in YARD format, in Ruby).

**Functions, methods, constructors**

- The first paragraph is a **single phrase/sentence** saying what it does.
- Following paragraphs add context: when to use it, edge cases, side effects, throws, examples.
- Explain complex parameters (and only those) by referencing them (`[param]` in Dart, `@param param` in TSDoc/Javadoc/YARD).
- Add a short example when usage isn't obvious.
- In languages with types in the code (Dart, TypeScript, Java), don't repeat the type in the documentation; in YARD the type is part of the tag (`@param name [String]`).

```dart
/// Splits [text] into chunks that fit within [maxLength].
///
/// Breaks happen at whitespace when possible; a word longer than
/// [maxLength] is split mid-word rather than dropped. If [keepDelimiters]
/// is `true`, the whitespace stays attached to the end of each chunk.
List<String> chunk(String text, {required int maxLength, bool keepDelimiters = false})
```

```typescript
/**
 * Splits the text into chunks that fit within `maxLength`.
 *
 * Breaks happen at whitespace when possible; a word longer than
 * `maxLength` is split mid-word rather than dropped.
 *
 * @param keepDelimiters if `true`, the whitespace stays attached to the end of each chunk.
 */
function chunk(text: string, maxLength: number, keepDelimiters = false): string[]
```

**Getters, fields, setters**

- Explain what the value **means for the class**, not its type or how it is stored.
- For a setter, mention any separate side effects (notifies listeners, invalidates a cache, triggers a rebuild or a new change detection) when they're worth knowing. Skip this if there are none.

```dart
/// Whether the user has confirmed the order and it can no longer be edited.
bool get isLocked => _lockedAt != null;
```

### Always prefer comment references

Use the language's symbol reference instead of plain-text or backticked names whenever the target is a symbol that resolves in scope: parameters, other members, classes, enum values, top-level functions. In Dart: `[name]`, and `[Class.member]` or `[Class.new]` for constructors; in TSDoc/Javadoc: `{@link Class.member}` / `{@link Class#member}`; in YARD: `{Class#method}`. References make the docs navigable and let the analyzer or doc generator flag them when the symbol is renamed or removed. Backticks are for code that isn't a resolvable symbol (literals like `null`, `true`, snippets).

### TODOs

Include something actionable. In Dart, when a TODO spans more than one line, every line after the first must start with **two spaces** between `//` and the text. This is how the analyzer knows the continuation belongs to the TODO. Other languages have no such rule; keep continuations aligned with the same indent.

```dart
// TODO(<windows-user-name>): first line
//  continuation.
```

To fill in `<windows-user-name>`, use the name returned by `$env:USERNAME` in PowerShell on the current machine. Never copy a username from another machine.

Without the extra space, in Dart the second line is treated as an ordinary comment and is dropped from the TODO.

### Existing comments

- Update an existing comment only when the code change makes it wrong or incomplete.
- Otherwise leave it as is, including its wording and language.
- Don't add banner or section-divider comments, and don't leave commented-out code.

### Don't

- Don't restate the signature, the name, or the types in prose.
- Don't add section-divider or banner comments.
- Don't leave commented-out code.
- Don't write TODOs without something actionable, or continuation lines without the two-space indent.

### After editing

Follow the language's post-edit workflow. For Dart, follow `dart-edit-protocol` (unresolved comment references show up in the analyzer, fix them). For the other languages, use `language-tooling`: run the project's linter and formatter (`language-tooling`); broken references are only caught if the project has a doc checker (`eslint-plugin-tsdoc`/`jsdoc`, `javadoc -Xdoclint`, `yard stats`).
