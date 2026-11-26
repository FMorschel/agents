---
name: preserve-existing-code
description: Load BEFORE editing any code that already exists, whether a project file or a snippet pasted into the conversation (fixing a bug, renaming, refactoring, tweaking a function) to limit the diff to the lines the task requires, with no cleanup, reformatting or incidental changes around them. To decide what a feature or fix should include, use `minimum-viable-change`.
---

# Preserve existing code

Do not touch code you do not need to touch. Every line of the diff must be necessary for the task.

The examples use Dart, TypeScript, Java and Ruby; each language's commands and suppression syntax are in `language-tooling`.

## Rules

- do not reformat, reorder, rename or tidy lines you are not otherwise changing; blank lines and trailing commas are not a reason to edit a line;
- `print`, `console.log`, `System.out.println`, `puts`, log calls and `TODO`s already in the code: change them only if the task requires it;
- lint or type suppressions already in the code stay (`// ignore:` in Dart, `// eslint-disable-next-line` and `// @ts-expect-error` in TypeScript, `@SuppressWarnings` in Java, `# rubocop:disable` in Ruby). Never add a new one without asking the user first;
- before removing a defensive check (a null check, an `assert`, or a `try/catch`/`rescue` that looks unnecessary), ask the user. The exception is the nullability case below;
- incorrect or legacy names (for example, Portuguese identifiers): leave them as they are, do not add new ones, and mention it to the user when you notice one;
- automatic tool fixes (`dart fix`, `eslint --fix`, `rubocop -A`, formatters applied to the whole file) only land on the lines the task already changes; the rest of the diff they produce is reverted or asked about.

## Nullable values

When a nullable value is checked or asserted, first try to replace the non-null assertion (`!` in Dart and TypeScript, `Objects.requireNonNull` in Java) with an `if` that handles the null case (early return, skip, default value). In languages with type narrowing (Dart, TypeScript, Kotlin), the `if` removes the need for the assertion.

- a local variable is only a tool for narrowing: use it when the value is a field, getter, mutable property or other expression that the compiler does not narrow and that an `if` has to check. Parameters and local variables are already narrowed, so no local is needed;
- never copy `value!` into a local just to give it a name once. That changes nothing about null safety; it only touches lines;
- if there is no sensible way to handle the null with an `if`, keep the existing assertion or `assert` as it is, without adding a local;
- in languages without narrowing (Java, Ruby), the rule applies in spirit: do not swap an existing check for another one out of preference.

```dart
final entity = _entity;
if (entity == null) return;

entity.save();
```

```typescript
const entity = this.entity;
if (entity == null) return;

entity.save();
```

## Local variables before a `return`

In this project, a local variable that holds the final value right before a `return` is there on purpose: it lets whoever is debugging hover over it and see the computed value before the function ends.

- If the code already has that local, keep it. Do not remove it, inline it into the expression or collapse it, however small the function.
- This holds for every kind of edit: refactors and cleanups (including the automatic fixes above, `/simplify` and code review suggestions), lint or analyzer hints that suggest the variable is unnecessary (for example, `unnecessary_local_variable`/`prefer-inline` and equivalents), and moving or extracting code, where the local must travel with the `return`.
- Adding it is not mandatory in every function. Do not add it everywhere by default or as a side change in code you are not otherwise editing. Add it when it helps debugging, for example when the returned value is computed from a call or several steps. Once it exists, this rule protects it.

```dart
final rows = await super.findAll(filter: databaseFilter);

return rows;
```

Do not turn this into `return super.findAll(filter: databaseFilter);`. The same goes in the other languages:

```ruby
rows = find_all(filter: database_filter)

return rows
```

```java
List<Row> rows = findAll(databaseFilter);

return rows;
```

Reason: returning an expression directly gives the debugger nothing to inspect, and forces a breakpoint plus a watch expression to see the value. The local costs one line, so removing it only makes debugging harder.
