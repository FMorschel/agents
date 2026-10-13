---
name: use-dart-analyzer
description: "Use whenever you write, review or debug Dart code built on `package:analyzer` (lint rules, analyzer plugins, assists and quick fixes, code generators, `source_gen` builders, or any other tool that inspects resolved Dart code) and that code needs to reason about types or elements: the type of a variable, parameter or return value, whether a type is or extends a given class, nullability, generics, futures, inheritance, or what an identifier, assignment or method call resolves to. Use it even when the request never says 'analyzer', such as 'add a lint that flags …', 'this rule misfires on `var` declarations' or 'make the builder find every field of type X'."
---

## Using `package:analyzer`

### Check the API against the pinned version first

The analyzer's element model has been renamed piece by piece across major versions (`declaredElement` → `declaredFragment`, `staticParameterElement` → `correspondingParameter`, transitional `…2`/`…3` names coming and going), and projects pin very different majors. Before using a member, look up the `analyzer` version in the project's `pubspec.lock` and confirm the member exists in that version: read the package source in the pub cache, or use the Dart MCP server's `hover`/`resolve_workspace_symbol`. Do the same for `source_gen`. Never write an analyzer member name from memory.

### Declaration types come from the element, not the AST

When you need the type of something a declaration introduces, go through `node.declaredFragment?.element` and read the type off the element: `type` for variables, fields and parameters, `returnType` for functions, methods and getters. The element holds the type after inference. The AST only holds what the author wrote, and in most places that's nothing.

```dart
@override
void visitVariableDeclaration(VariableDeclaration node) {
  // Wrong: `null` for `var x = 1;` and `final x = foo();`.
  final written = (node.parent as VariableDeclarationList).type?.type;

  // Right: the declared or inferred type, whether or not one was written.
  final type = node.declaredFragment?.element.type;
}
```

These are the cases where the `TypeAnnotation` is missing but the element still has the real type:

| Source | AST annotation | Element type |
| --- | --- | --- |
| `var x = 1;` / `final x = foo();` | `null` | `int` / `foo`'s return type |
| `for (final e in items)` | `null` | element type of `items` |
| `items.map((e) => e.id)` | `null` on `e` | from the context type |
| `@override void m(x)` | `null` on `x` | inherited from the overridden member |
| `C(this.x)` / `C(super.x)` | `null` | the field's / super parameter's type |
| `var (a, b) = pair;` | `null` | from the matched value |
| local function or closure with no return type | `null` | inferred from the body |

The same applies to every node that declares something: `VariableDeclaration`, `FormalParameter` (including field and super formals), `MethodDeclaration`, `FunctionDeclaration`, `DeclaredIdentifier` (for-in variables) and `DeclaredVariablePattern`. Each exposes `declaredFragment`, and its `element` aggregates every fragment (augmentations, parts) of that declaration.

`declaredFragment` is `null` only when the AST isn't resolved. In a lint or plugin that runs on resolved units, treat `null` as "bail out", not as "no type".

#### When the written type is the point

Use the `TypeAnnotation` node (`NamedType`, `GenericFunctionType`, …) only when the rule is explicitly about the annotation as written in the file, for example "always specify types", "omit obvious local variable types", "don't write `dynamic`", or anything that reports on or rewrites the annotation's source text. Then the annotation node's position and text are what matter, and `annotation.type` gives the resolved meaning of what was written.

Even in those rules, any type the rule *produces* comes from the element. A fix that adds the missing annotation writes the element's type, because that's what the code already has.

### Testing what a type is

To ask "is this type X?" for a known named type, use `source_gen`'s `TypeChecker`. Prefer `TypeChecker.typeNamed`, and always pass `inPackage`:

```dart
const _future = TypeChecker.typeNamed(Future, inPackage: 'async', inSdk: true);
const _widget = TypeChecker.typeNamedLiterally('Widget', inPackage: 'flutter');
```

- Without `inPackage`, the checker matches on the name alone, so a user's own class called `Widget` matches too. `inPackage` is the first path segment of the declaring library's URI: the package name for `package:` URIs, or the library name (`core`, `async`, …) together with `inSdk: true` for `dart:` URIs.
- `inPackage` checks the package, not the library, so it doesn't matter that `Widget` is declared in `package:flutter/src/widgets/framework.dart` rather than the `package:flutter/widgets.dart` users import. If you identify a type by hand instead, compare the element *and* `element.library.uri`, using the declaring `src/` library, not the public barrel. Never compare by name alone.
- `typeNamed` takes a `Type`, so the checking code has to be able to import it. When it can't (an analyzer plugin can't depend on Flutter), use `typeNamedLiterally` with the name as a string.
- Use `isExactlyType` for "is exactly X" and `isAssignableFromType` for "is X or a subtype of X".
- `TypeChecker` compares elements only and ignores type arguments: `List<int>` and `List<String>` both match a `List` checker. When type arguments matter, or both sides are `DartType`s you computed, use `TypeSystem.isSubtypeOf` or `isAssignableTo`.

Never test a type with `==`, `toString()` or `getDisplayString()`. Display strings are only for diagnostic messages.

#### Nullability is a separate check

`isDartCoreInt` and the other `isDartCore*`/`isDartAsync*` getters, and every `TypeChecker` method, look only at the type's element. `int?` passes `isDartCoreInt`, and `Future<void>?` passes a `Future` checker. When nullability matters, also check `type.nullabilitySuffix`, or `typeSystem.isNonNullable(type)` / `isNullable(type)`.

#### Not every type is an `InterfaceType`

Switch on the `DartType` subclass instead of casting to `InterfaceType` or writing `type.element!`:

- `FunctionType`, `RecordType`, `VoidType` and `InvalidType` have a `null` element. `TypeChecker` returns `false` for all of them, and its `isSuperTypeOf` throws on them.
- A `TypeParameterType`'s element is the type parameter itself, so a `T extends Widget` fails a `Widget` check. Call `typeSystem.resolveToBound(type)` first.
- `InvalidType` means the code has errors. Return without reporting, or the rule fires false positives while the user is still typing.

`InstanceElement` is sometimes the better thing to match on than `InterfaceElement`. It covers classes, mixins, enums, extension types *and extensions*, and it has `thisType` (the type of `this`; for an extension, the extended type) plus the declared `fields`, `methods`, `getters` and `setters`. Use it when the question is "what declares this member" or "what is `this` here"; a field's `enclosingElement` is already typed as one. Use `InterfaceElement` when you need supertypes or constructors, which extensions don't have.

### Supertypes

`InterfaceElement.supertype` only follows `extends`. Direct `implements` types are in `interfaces`, `with` types in `mixins`, and a mixin's `on` types in `MixinElement.superclassConstraints`. Use those when you need one specific clause. For "is it a subtype of X at all", use `allSupertypes`, `TypeSystem.isSubtypeOf` or `TypeChecker.isAssignableFromType`. `TypeChecker.isSuperOf` and `isSuperTypeOf` also follow `extends` only.

### Generic instantiations

Elements and types reached through a generic instantiation are substituted copies of the declaration.

- **Compare elements through `baseElement`.** The method you resolve on a `List<int>`, or the parameter you get from `argument.correspondingParameter` for `ints.add(1)`, is a substituted wrapper, so `==` against the declaration's element is `false`. Compare `a.baseElement == b.baseElement`.
- **Read call-site types from the invocation.** The invoked element's `type` still has the function's own type parameters: `T Function<T>(T)` for `identity(1)`, and `Iterable<T> Function<T>(T Function(int))` for `ints.map((i) => '$i')`. `staticInvokeType` on the `MethodInvocation` or `FunctionExpressionInvocation` has them inferred: `int Function(int)` and `Iterable<String> Function(String Function(int))`.

### Futures

To get the type an `await` produces, or the value type of a `Future<T>`, use `typeSystem.flatten(type)`. Taking `typeArguments.first` by hand breaks on `FutureOr<T>`, `Future<T>?` and classes that implement `Future`.

### What references and targets resolve to

- **A reference to a field or top-level variable resolves to its getter or setter**, not to the variable. The `element` of `count` in `print(count)` is a `GetterElement`; use its `variable` to reach the `FieldElement` or `TopLevelVariableElement`. An explicit `get count => …` has a `variable` too, a synthetic one (`isSynthetic` is `true`).
- **Assignments have two elements.** For the target of `=`, `+=` or `++`, read the `CompoundAssignmentExpression`'s `writeElement` (the setter) and, for `+=` and `++`, its `readElement` (the getter), not the target identifier's own `element`.
- **Inside a cascade, `target` is `null`.** In `a..foo()..bar()`, each section's `realTarget` is `a`. Outside cascades, a `null` `target` means an implicit `this` or a top-level function call, so check `isCascaded` before concluding that.
- **Unwrap parentheses before checking what kind of expression you have.** The target in `(a as B).foo()` is a `ParenthesizedExpression`, not an `AsExpression`; call `unParenthesized` first.
